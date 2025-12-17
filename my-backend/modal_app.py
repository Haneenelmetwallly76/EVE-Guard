import modal
import re
from typing import List, Dict

# Create the app
app = modal.App("eveguard-backend")

MODEL_DIR = "/model"
MODEL_NAME = "openai/whisper-medium"

# Define bad words database with severity levels
# Level 1: Suspicious (0.3-0.5), Level 2: Warning (0.5-0.7), Level 3: Critical (0.7-1.0)
BAD_WORDS_DATABASE = {
    # Critical (Level 3) - Direct threats, violence
    "critical": [
        "kill", "murder", "die", "death", "shoot", "stab", "attack",
        "bomb", "weapon", "gun", "knife", "blood", "destroy", "rape",
        "assault", "strangle", "suffocate", "torture", "hurt you",
        "end your life", "finish you", "eliminate", "execute"
    ],
    # Warning (Level 2) - Harassment, intimidation
    "warning": [
        "threat", "harm", "danger", "watch out", "careful", "regret",
        "sorry", "pay for", "consequences", "revenge", "punish", "suffer",
        "stalking", "following", "watching you", "find you", "know where",
        "coming for", "wait for you", "get you", "teach you a lesson",
        "hate", "ugly", "stupid", "idiot", "loser", "worthless", "useless"
    ],
    # Suspicious (Level 1) - Concerning language
    "suspicious": [
        "angry", "mad", "upset", "furious", "annoyed", "frustrated",
        "scared", "afraid", "worried", "anxious", "nervous", "uncomfortable",
        "creepy", "weird", "strange", "stop", "leave me alone", "go away",
        "don't touch", "back off", "personal space", "boundaries"
    ]
}

# Severity weights
SEVERITY_WEIGHTS = {
    "critical": 1.0,
    "warning": 0.6,
    "suspicious": 0.3
}

def detect_bad_words(text: str) -> List[Dict]:
    """
    Analyze text for bad words and return detailed analysis.
    Returns list of detected words with their levels.
    """
    text_lower = text.lower()
    detected_words = []
    
    for level, words in BAD_WORDS_DATABASE.items():
        for word in words:
            # Use word boundary matching for better accuracy
            pattern = r'\b' + re.escape(word) + r'\b'
            matches = re.findall(pattern, text_lower)
            if matches:
                for match in matches:
                    detected_words.append({
                        "word": match,
                        "level": level,
                        "weight": SEVERITY_WEIGHTS[level]
                    })
    
    return detected_words

def calculate_danger_score(detected_words: List[Dict], text: str) -> float:
    """
    Calculate danger score between 0 and 1 based on detected words.
    
    Formula considers:
    - Number of bad words
    - Severity level of each word
    - Text length normalization
    - Cumulative effect (more words = higher danger)
    """
    if not detected_words:
        return 0.0
    
    # Count by severity
    critical_count = sum(1 for w in detected_words if w["level"] == "critical")
    warning_count = sum(1 for w in detected_words if w["level"] == "warning")
    suspicious_count = sum(1 for w in detected_words if w["level"] == "suspicious")
    
    # Calculate base danger score
    # Critical words have highest impact
    base_score = (
        critical_count * 0.35 +
        warning_count * 0.15 +
        suspicious_count * 0.05
    )
    
    # Apply cumulative effect (more bad words = multiplier)
    word_count = len(detected_words)
    if word_count > 1:
        cumulative_multiplier = 1 + (word_count - 1) * 0.1  # 10% increase per additional word
        base_score *= min(cumulative_multiplier, 2.0)  # Cap at 2x
    
    # Normalize by text length (shorter texts with bad words are more concentrated)
    text_word_count = max(len(text.split()), 1)
    word_density = len(detected_words) / text_word_count
    density_bonus = min(word_density * 0.1, 0.2)  # Up to 20% bonus for high density
    
    # Final score
    danger_score = min(base_score + density_bonus, 1.0)
    
    # Ensure minimum score if any critical word found
    if critical_count > 0:
        danger_score = max(danger_score, 0.7)
    elif warning_count > 0:
        danger_score = max(danger_score, 0.4)
    elif suspicious_count > 0:
        danger_score = max(danger_score, 0.15)
    
    return round(danger_score, 3)

def get_risk_level(danger_score: float) -> str:
    """Convert danger score to risk level string."""
    if danger_score >= 0.7:
        return "danger"
    elif danger_score >= 0.4:
        return "warning"
    elif danger_score > 0:
        return "suspicious"
    else:
        return "safe"

def get_risk_message(risk_level: str, detected_words: List[Dict], danger_score: float) -> str:
    """Generate human-readable risk message."""
    if risk_level == "safe":
        return "No threatening content detected. The text appears safe."
    
    word_summary = {}
    for w in detected_words:
        level = w["level"]
        if level not in word_summary:
            word_summary[level] = []
        word_summary[level].append(w["word"])
    
    message_parts = []
    if "critical" in word_summary:
        message_parts.append(f"CRITICAL threats detected: {', '.join(set(word_summary['critical']))}")
    if "warning" in word_summary:
        message_parts.append(f"Warning indicators: {', '.join(set(word_summary['warning']))}")
    if "suspicious" in word_summary:
        message_parts.append(f"Suspicious terms: {', '.join(set(word_summary['suspicious']))}")
    
    message_parts.append(f"Danger score: {danger_score:.1%}")
    
    return " | ".join(message_parts)


# Define the image with all dependencies and CUDA support
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("ffmpeg")
    .pip_install(
        "torch==2.5.1",
        "transformers==4.47.1",
        "huggingface-hub==0.36.0",
        "librosa==0.10.2",
        "soundfile==0.12.1",
        "accelerate==1.2.1",
        "fastapi==0.115.0",
        "python-multipart==0.0.9",
    )
    .env({"HF_HUB_CACHE": MODEL_DIR})
)

model_cache = modal.Volume.from_name("whisper-model-cache", create_if_missing=True)

# Deploy the FastAPI app
@app.function(
    image=image,
    gpu="A10G",
    volumes={MODEL_DIR: model_cache},
    cpu=2,
    memory=16384,
    timeout=600,
)
@modal.asgi_app()
def fastapi_app():
    from fastapi import FastAPI, File, UploadFile, HTTPException, Header
    from fastapi.middleware.cors import CORSMiddleware
    from pydantic import BaseModel
    import tempfile
    import os
    import base64
    import torch
    from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline
    
    api = FastAPI(title="EVE-Guard API", version="2.0")
    
    # Add CORS middleware for Flutter app
    api.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    class TextAnalysisRequest(BaseModel):
        text: str
    
    class ModelCache:
        def __init__(self):
            self.pipeline = None
        
        def get_pipeline(self):
            if self.pipeline is None:
                print("Loading Whisper Medium model (GPU)...")
                processor = AutoProcessor.from_pretrained(MODEL_NAME)
                model = AutoModelForSpeechSeq2Seq.from_pretrained(
                    MODEL_NAME,
                    torch_dtype=torch.float16,
                    low_cpu_mem_usage=True,
                    use_safetensors=True,
                ).to("cuda")
                
                self.pipeline = pipeline(
                    "automatic-speech-recognition",
                    model=model,
                    tokenizer=processor.tokenizer,
                    feature_extractor=processor.feature_extractor,
                    torch_dtype=torch.float16,
                    device="cuda",
                )
                print("Model loaded successfully!")
            return self.pipeline
    
    model_cache_instance = ModelCache()
    
    def transcribe_audio_file(audio_path: str) -> str:
        pipe = model_cache_instance.get_pipeline()
        result = pipe(audio_path)
        return result["text"]
    
    def verify_token(token: str) -> bool:
        return bool(token)
    
    @api.get("/")
    async def root():
        return {
            "service": "EVE-Guard API",
            "version": "2.0",
            "endpoints": [
                "/transcribe - Speech to text with threat analysis",
                "/analyze-text - Text threat analysis",
                "/analyze-video - Video analysis (placeholder)"
            ]
        }
    
    # ============================================
    # ENDPOINT 1: Speech to Text + Threat Analysis
    # ============================================
    @api.post("/transcribe")
    async def transcribe(
        file: UploadFile = File(...),
        authorization: str = Header(None)
    ):
        """
        Transcribe audio and analyze for threats.
        Returns: transcription, detected words, danger score (0-1), risk level
        """
        print(f"[LOG] Received file: {file.filename} (content_type={file.content_type})")
        
        if authorization and not verify_token(authorization.replace("Bearer ", "")):
            print("[LOG] Invalid token")
            raise HTTPException(status_code=401, detail="Invalid token")
        
        allowed_extensions = ('.ogg', '.mp3', '.wav', '.m4a', '.flac')
        if not file.content_type.startswith("audio/") and not file.filename.lower().endswith(allowed_extensions):
            print(f"[LOG] Rejected non-audio file upload: {file.content_type} {file.filename}")
            raise HTTPException(status_code=400, detail="File must be audio")
        
        audio_bytes = await file.read()
        suffix = os.path.splitext(file.filename)[1] or ".wav"
        
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as f:
            f.write(audio_bytes)
            temp_path = f.name
        
        print(f"[LOG] Saved file to: {temp_path}")
        
        try:
            # Transcribe audio
            print(f"[LOG] Starting transcription")
            text = transcribe_audio_file(temp_path)
            print(f"[LOG] Transcription result: {text}")
            
            # Analyze for threats
            detected_words = detect_bad_words(text)
            danger_score = calculate_danger_score(detected_words, text)
            risk_level = get_risk_level(danger_score)
            risk_message = get_risk_message(risk_level, detected_words, danger_score)
            
            # Encode audio as base64 for returning to client
            audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
            
            return {
                "transcription": text,
                "audio_base64": audio_base64,
                "audio_format": suffix.replace(".", ""),
                "analysis": {
                    "detected_words": detected_words,
                    "danger_score": danger_score,
                    "risk": risk_level,
                    "message": risk_message,
                    "word_count": len(detected_words),
                    "critical_count": sum(1 for w in detected_words if w["level"] == "critical"),
                    "warning_count": sum(1 for w in detected_words if w["level"] == "warning"),
                    "suspicious_count": sum(1 for w in detected_words if w["level"] == "suspicious"),
                }
            }
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)
                print(f"[LOG] Cleaned up temp file")
    
    # ============================================
    # ENDPOINT 2: Text Analysis Only
    # ============================================
    @api.post("/analyze-text")
    async def analyze_text(request: TextAnalysisRequest):
        """
        Analyze text for threats without audio.
        Returns: danger score (0-1), risk level, detected words
        """
        text = request.text
        print(f"[LOG] Analyzing text: {text[:100]}...")
        
        if not text or not text.strip():
            raise HTTPException(status_code=400, detail="Text cannot be empty")
        
        # Analyze for threats
        detected_words = detect_bad_words(text)
        danger_score = calculate_danger_score(detected_words, text)
        risk_level = get_risk_level(danger_score)
        risk_message = get_risk_message(risk_level, detected_words, danger_score)
        
        return {
            "text": text,
            "danger_score": danger_score,
            "risk": risk_level,
            "message": risk_message,
            "detected_words": detected_words,
            "word_count": len(detected_words),
            "critical_count": sum(1 for w in detected_words if w["level"] == "critical"),
            "warning_count": sum(1 for w in detected_words if w["level"] == "warning"),
            "suspicious_count": sum(1 for w in detected_words if w["level"] == "suspicious"),
        }
    
    # ============================================
    # ENDPOINT 3: Video Analysis (Placeholder)
    # ============================================
    @api.post("/analyze-video")
    async def analyze_video(
        file: UploadFile = File(...),
        authorization: str = Header(None)
    ):
        """
        Placeholder for future video analysis feature.
        Will analyze video for threatening behavior, weapons, etc.
        """
        print(f"[LOG] Video analysis requested: {file.filename}")
        
        # Placeholder response
        return {
            "status": "placeholder",
            "message": "Video analysis feature coming soon",
            "filename": file.filename,
            "planned_features": [
                "Object detection (weapons, suspicious items)",
                "Behavior analysis",
                "Face recognition for known threats",
                "Crowd density monitoring",
                "Audio extraction and analysis"
            ]
        }
    
    return api
