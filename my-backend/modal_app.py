import modal
import re
from typing import List, Dict

# Create the app
app = modal.App("eveguard-backend")

MODEL_DIR = "/model"
MODEL_NAME = "openai/whisper-medium"
MARBERT_MODEL = "IbrahimAmin/marbertv2-finetuned-egyptian-hate-speech-detection"

# Define bad words database with severity levels
# Level 1: Suspicious (0.3-0.5), Level 2: Warning (0.5-0.7), Level 3: Critical (0.7-1.0)
BAD_WORDS_DATABASE = {
    # Critical (Level 3) - Direct threats, violence, sexual assault
    "critical": [
        # English - Violence & Threats
        "kill", "murder", "die", "death", "shoot", "stab", "attack",
        "bomb", "weapon", "gun", "knife", "blood", "destroy", "rape",
        "assault", "strangle", "suffocate", "torture", "hurt you",
        "end your life", "finish you", "eliminate", "execute", "slaughter",
        "butcher", "massacre", "decapitate", "dismember", "mutilate",
        "molest", "abuse", "violate", "kidnap", "abduct",
        # Arabic - Violence & Threats (عنف وتهديدات)
        "اقتلك", "قتل", "موت", "اذبحك", "اطعنك", "اضربك", "هجوم",
        "سلاح", "مسدس", "سكين", "دم", "تدمير", "اغتصاب", "اعتداء",
        "خنق", "تعذيب", "اأذيك", "انهي حياتك", "اقضي عليك", "ذبح",
        "مجزرة", "تحرش", "اختطاف", "اغتصبك", "اعدام", "سم", "حرق",
        "اشعل فيك", "ادفنك", "انتقام بالدم"
    ],
    # Warning (Level 2) - Harassment, intimidation
    "warning": [
        # English - Harassment & Intimidation
        "threat", "harm", "danger", "watch out", "careful", "regret",
        "sorry", "pay for", "consequences", "revenge", "punish", "suffer",
        "stalking", "following", "watching you", "find you", "know where",
        "coming for", "wait for you", "get you", "teach you a lesson",
        "hate", "ugly", "stupid", "idiot", "loser", "worthless", "useless",
        "slap", "beat", "hit", "punch", "kick", "curse you", "damn you",
        "whore", "bitch", "slut", "pig", "trash", "scum", "disgust",
        # Arabic - Harassment & Intimidation (تحرش وتخويف)
        "تهديد", "اذى", "خطر", "انتبه", "حذر", "ندم", "عواقب",
        "انتقام", "عقاب", "معاناة", "مطاردة", "اتبعك", "اراقبك",
        "اعرف مكانك", "جاي لك", "مستنيك", "هعلمك درس", "كره",
        "قبيح", "غبي", "احمق", "فاشل", "تافه", "عديم القيمة",
        "اضربك", "الطمك", "العنك", "شرموطة", "قحبة", "عاهرة",
        "كلب", "حيوان", "زبالة", "قذر", "مقرف", "وسخ"
    ],
    # Suspicious (Level 1) - Concerning language
    "suspicious": [
        # English - Concerning Language
        "angry", "mad", "upset", "furious", "annoyed", "frustrated",
        "scared", "afraid", "worried", "anxious", "nervous", "uncomfortable",
        "creepy", "weird", "strange", "stop", "leave me alone", "go away",
        "don't touch", "back off", "personal space", "boundaries",
        "following me", "watching me", "stalker", "harasser", "pervert",
        "inappropriate", "uncomfortable", "threatening", "intimidating",
        "aggressive", "violent", "scary", "frightening", "disturbing",
        # Arabic - Concerning Language (لغة مقلقة)
        "غضبان", "زعلان", "متضايق", "مجنون", "قلقان", "خايف",
        "متوتر", "غير مرتاح", "مخيف", "غريب", "عجيب", "سيبني",
        "ابعد عني", "متلمسنيش", "حدودك", "بيتبعني", "بيراقبني",
        "متحرش", "منحرف", "غير لائق", "مهدد", "عدواني", "عنيف",
        "مرعب", "مزعج", "مقلق", "بيضايقني", "مش طبيعي", "خطير"
    ]
}

# Arabic-specific bad words database for better Arabic detection
ARABIC_BAD_WORDS = {
    "critical": [
        "هقتلك", "هموتك", "هذبحك", "هغتصبك", "هحرقك", "هدمرك",
        "يلعن ابوك", "يلعن امك", "ابن الشرموطة", "ابن القحبة",
        "هنيكك", "هخرمك", "كسمك", "كس امك", "طيزك", "هفشخك",
        "هشرمطك", "هعذبك", "هقطعك", "هكسرك", "ولد الزنا", "ابن الحرام",
        "منيوك", "معرص", "ديوث", "قواد", "متناك", "خول"
    ],
    "warning": [
        "يا حمار", "يا كلب", "يا حيوان", "يا زبالة", "يا قذر",
        "يا واطي", "يا سافل", "يا حقير", "انت عار", "انت فضيحة",
        "هفضحك", "هشوهك", "هخربلك", "هوريك", "مستنيك برا",
        "عارف بيتك", "عارف شغلك", "هجيلك", "مش هسيبك", "هخليك تندم",
        "يا جبان", "يا ضعيف", "يا مسخ", "يا عبيط", "يا هبلة"
    ],
    "suspicious": [
        "بتعملي كده ليه", "بتبصلي ليه", "ايه نظراتك دي", "سيب ايدي",
        "متقربش", "ابعد بقى", "كفاية بقى", "وقف عند حدك", "احترم نفسك",
        "انا مش مرتاح", "حاسس بخطر", "في حاجة غلط", "مش طبيعي",
        "خايفة منه", "بيخوفني", "بيهددني", "مش امان", "محتاج مساعدة"
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
    Supports both English and Arabic languages.
    Returns list of detected words with their levels.
    """
    text_lower = text.lower()
    detected_words = []
    
    # Check main database (English + Arabic mixed)
    for level, words in BAD_WORDS_DATABASE.items():
        for word in words:
            # Use word boundary matching for better accuracy
            pattern = r'\b' + re.escape(word) + r'\b'
            matches = re.findall(pattern, text_lower, re.IGNORECASE)
            if matches:
                for match in matches:
                    detected_words.append({
                        "word": match,
                        "level": level,
                        "weight": SEVERITY_WEIGHTS[level],
                        "language": "mixed"
                    })
    
    # Check Arabic-specific database (no word boundaries needed for Arabic)
    for level, words in ARABIC_BAD_WORDS.items():
        for word in words:
            if word in text:
                detected_words.append({
                    "word": word,
                    "level": level,
                    "weight": SEVERITY_WEIGHTS[level],
                    "language": "arabic"
                })
    
    # Remove duplicates based on word
    seen = set()
    unique_words = []
    for w in detected_words:
        if w["word"] not in seen:
            seen.add(w["word"])
            unique_words.append(w)
    
    return unique_words

def calculate_danger_score(detected_words: List[Dict], text: str) -> float:
    """
    Calculate danger score between 0 and 1 based on detected words.
    
    Improved formula considers:
    - Severity weights with exponential scaling for critical words
    - Word frequency and repetition
    - Text density (bad words / total words ratio)
    - Cumulative threat escalation
    - Context intensity multiplier
    """
    if not detected_words:
        return 0.0
    
    # Count by severity
    critical_count = sum(1 for w in detected_words if w["level"] == "critical")
    warning_count = sum(1 for w in detected_words if w["level"] == "warning")
    suspicious_count = sum(1 for w in detected_words if w["level"] == "suspicious")
    total_bad_words = len(detected_words)
    
    # Base severity score with weighted importance
    # Critical words are exponentially more dangerous
    critical_score = min(critical_count * 0.4, 1.0)  # Each critical word = 40%, caps at 100%
    warning_score = min(warning_count * 0.2, 0.6)    # Each warning word = 20%, caps at 60%
    suspicious_score = min(suspicious_count * 0.1, 0.3)  # Each suspicious = 10%, caps at 30%
    
    # Weighted combination (critical has highest priority)
    base_score = critical_score + (warning_score * 0.7) + (suspicious_score * 0.5)
    
    # Text density factor (ratio of bad words to total words)
    text_word_count = max(len(text.split()), 1)
    density_ratio = total_bad_words / text_word_count
    
    # Density multiplier: higher concentration = more dangerous
    # Short aggressive messages (e.g., "I'll kill you") should score high
    if density_ratio > 0.5:
        density_multiplier = 1.4  # More than 50% bad words
    elif density_ratio > 0.3:
        density_multiplier = 1.25  # 30-50% bad words
    elif density_ratio > 0.15:
        density_multiplier = 1.1  # 15-30% bad words
    else:
        density_multiplier = 1.0
    
    # Cumulative threat escalation (multiple threats = more dangerous)
    if total_bad_words >= 5:
        cumulative_bonus = 0.2
    elif total_bad_words >= 3:
        cumulative_bonus = 0.1
    elif total_bad_words >= 2:
        cumulative_bonus = 0.05
    else:
        cumulative_bonus = 0.0
    
    # Mixed severity bonus (having both critical + warning is worse)
    mixed_severity_bonus = 0.0
    if critical_count > 0 and warning_count > 0:
        mixed_severity_bonus = 0.1
    if critical_count > 0 and warning_count > 0 and suspicious_count > 0:
        mixed_severity_bonus = 0.15
    
    # Calculate final score
    danger_score = (base_score * density_multiplier) + cumulative_bonus + mixed_severity_bonus
    
    # Apply minimum thresholds based on severity found
    if critical_count >= 2:
        danger_score = max(danger_score, 0.85)  # Multiple critical = very dangerous
    elif critical_count == 1:
        danger_score = max(danger_score, 0.6)   # Single critical = dangerous
    elif warning_count >= 3:
        danger_score = max(danger_score, 0.55)  # Multiple warnings = concerning
    elif warning_count >= 1:
        danger_score = max(danger_score, 0.35)  # Single warning = notable
    elif suspicious_count >= 1:
        danger_score = max(danger_score, 0.15)  # Suspicious = worth noting
    
    # Cap at 1.0 and round
    return round(min(danger_score, 1.0), 3)

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
        "sentencepiece==0.2.0",  # Required for MARBERT
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
            self.sentiment_classifier = None
        
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
        
        def get_sentiment_classifier(self):
            if self.sentiment_classifier is None:
                print("Loading MARBERT hate speech classifier...")
                self.sentiment_classifier = pipeline(
                    "text-classification",
                    model=MARBERT_MODEL,
                    device="cuda"
                )
                print("MARBERT classifier loaded successfully!")
            return self.sentiment_classifier
    
    model_cache_instance = ModelCache()
    
    def transcribe_audio_file(audio_path: str) -> str:
        pipe = model_cache_instance.get_pipeline()
        result = pipe(audio_path)
        return result["text"]
    
    def analyze_sentiment(text: str) -> dict:
        """
        Analyze text using MARBERT for hate speech detection.
        Returns: label (HATE/NOT_HATE), score, is_hate boolean
        """
        classifier = model_cache_instance.get_sentiment_classifier()
        result = classifier(text)[0]
        
        label = result["label"]
        score = result["score"]
        is_hate = label.upper() in ["HATE", "OFFENSIVE", "ABUSIVE", "1", "LABEL_1"]
        
        return {
            "label": label,
            "score": score,
            "is_hate": is_hate,
            "confidence": score if is_hate else 1 - score
        }
    
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
            
            # Analyze for threats using keyword detection
            detected_words = detect_bad_words(text)
            keyword_danger_score = calculate_danger_score(detected_words, text)
            
            # Analyze sentiment using MARBERT model
            sentiment_result = analyze_sentiment(text)
            
            # Combine scores
            sentiment_boost = 0.3 if sentiment_result["is_hate"] else 0.0
            combined_danger_score = min(1.0, keyword_danger_score + (sentiment_boost * sentiment_result["confidence"]))
            danger_score = max(keyword_danger_score, combined_danger_score)
            
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
                    "sentiment_analysis": {
                        "model": "MARBERT (Egyptian Hate Speech)",
                        "label": sentiment_result["label"],
                        "score": sentiment_result["score"],
                        "is_hate": sentiment_result["is_hate"],
                        "confidence": sentiment_result["confidence"]
                    }
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
        Uses MARBERT for sentiment analysis + keyword detection.
        Returns: danger score (0-1), risk level, detected words, sentiment
        """
        text = request.text
        print(f"[LOG] Analyzing text: {text[:100]}...")
        
        if not text or not text.strip():
            raise HTTPException(status_code=400, detail="Text cannot be empty")
        
        # Analyze for threats using keyword detection
        detected_words = detect_bad_words(text)
        keyword_danger_score = calculate_danger_score(detected_words, text)
        
        # Analyze sentiment using MARBERT model
        sentiment_result = analyze_sentiment(text)
        
        # Combine scores: keyword-based + sentiment-based
        # If MARBERT detects hate speech, boost the danger score
        sentiment_boost = 0.3 if sentiment_result["is_hate"] else 0.0
        combined_danger_score = min(1.0, keyword_danger_score + (sentiment_boost * sentiment_result["confidence"]))
        
        # Use the higher of the two scores
        danger_score = max(keyword_danger_score, combined_danger_score)
        
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
            "sentiment_analysis": {
                "model": "MARBERT (Egyptian Hate Speech)",
                "label": sentiment_result["label"],
                "score": sentiment_result["score"],
                "is_hate": sentiment_result["is_hate"],
                "confidence": sentiment_result["confidence"]
            }
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