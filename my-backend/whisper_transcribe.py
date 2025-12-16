from faster_whisper import WhisperModel

_model = None

def get_whisper_model():
    global _model
    if _model is None:
        print("Loading Whisper Medium model (GPU)...")
        _model = WhisperModel("medium", device="cuda", compute_type="float16")
    return _model

def transcribe_audio_file(audio_path: str) -> str:
    model = get_whisper_model()
    segments, _ = model.transcribe(audio_path, beam_size=5)
    return " ".join(seg.text for seg in segments)
