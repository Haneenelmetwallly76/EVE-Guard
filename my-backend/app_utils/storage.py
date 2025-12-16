import tempfile
import os

def save_audio_file(audio_bytes: bytes, suffix: str = ".wav") -> str:
    """Save audio bytes to a temp file and return path."""
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as f:
        f.write(audio_bytes)
        return f.name

def cleanup_temp_file(path: str):
    """Delete temp file."""
    if os.path.exists(path):
        os.remove(path)
