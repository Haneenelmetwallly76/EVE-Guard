# auth.py
# Authentication utilities

def verify_token(token: str) -> bool:
    # For demo: accept any non-empty token
    # In production, validate against a DB or verify JWT signature
    return bool(token)
