import modal

# Create the app
app = modal.App("whisper-medium-backend")

MODEL_DIR = "/model"
MODEL_NAME = "openai/whisper-medium"

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
    import tempfile
    import os
    import torch
    from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline
    
    api = FastAPI(title="Whisper Medium API", version="1.0")
    
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
    
    @api.post("/transcribe")
    async def transcribe(
        file: UploadFile = File(...),
        authorization: str = Header(None)
    ):
        print(f"[LOG] Received file: {file.filename} (content_type={file.content_type})")
        
        if authorization and not verify_token(authorization.replace("Bearer ", "")):
            print("[LOG] Invalid token")
            raise HTTPException(status_code=401, detail="Invalid token")
        
        allowed_extensions = ('.ogg', '.mp3', '.wav', '.m4a', '.flac')
        if not file.content_type.startswith("audio/") and not file.filename.lower().endswith(allowed_extensions):
            print(f"[LOG] Rejected non-audio file upload: {file.content_type} {file.filename}")
            raise HTTPException(status_code=400, detail=f"File must be audio")
        
        audio_bytes = await file.read()
        suffix = os.path.splitext(file.filename)[1] or ".wav"
        
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as f:
            f.write(audio_bytes)
            temp_path = f.name
        
        print(f"[LOG] Saved file to: {temp_path}")
        
        try:
            print(f"[LOG] Starting transcription")
            text = transcribe_audio_file(temp_path)
            print(f"[LOG] Transcription result: {text}")
            return {"transcription": text}
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)
                print(f"[LOG] Cleaned up temp file")
    
    return api
