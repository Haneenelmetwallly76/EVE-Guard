from fastapi import FastAPI, File, UploadFile, HTTPException, Header
from whisper_transcribe import transcribe_audio_file
from app_utils.storage import save_audio_file, cleanup_temp_file
from app_utils.auth import verify_token
import os

app = FastAPI(title="Whisper Medium API", version="1.0")

@app.post("/transcribe")
async def transcribe(
    file: UploadFile = File(...),
    authorization: str = Header(None)
):
    print(f"[LOG] Received file: {file.filename} (content_type={file.content_type})")
    # Optional auth
    if authorization and not verify_token(authorization.replace("Bearer ", "")):
        print("[LOG] Invalid token")
        raise HTTPException(status_code=401, detail="Invalid token")

    # Only accept audio files
    allowed_extensions = ('.ogg', '.mp3', '.wav', '.m4a', '.flac')
    if not file.content_type.startswith("audio/") and not file.filename.lower().endswith(allowed_extensions):
        print(f"[LOG] Rejected non-audio file upload: {file.content_type} {file.filename}")
        raise HTTPException(status_code=400, detail=f"File must be audio (received {file.content_type})")

    # Save uploaded file
    audio_bytes = await file.read()
    temp_path = save_audio_file(audio_bytes, suffix=os.path.splitext(file.filename)[1] or ".wav")
    print(f"[LOG] Saved file to: {temp_path}")

    try:
        # Run transcription
        print(f"[LOG] Starting transcription for: {temp_path}")
        text = transcribe_audio_file(temp_path)
        print(f"[LOG] Transcription result: {text}")
        return {"transcription": text}
    finally:
        cleanup_temp_file(temp_path)
        print(f"[LOG] Cleaned up temp file: {temp_path}")