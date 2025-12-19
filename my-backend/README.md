# EVE-Guard backend (Modal)

This folder contains the Modal-based backend `modal_app.py` for EVE-Guard.

## Deployment-ready notes

Environment variables used by the app:

- `PARENT_TOKENS` - Optional. JSON mapping of `parent_id` to `token`, e.g. `{"parent1":"token1"}`. Fallback format: `parent1:token1,parent2:token2`.
- `ALLOW_ANONYMOUS` - Optional. Set to `1` to allow requests without tokens (default `0`).
- `PRELOAD_MODELS` - Optional. Set to `1` to preload Whisper and MARBERT models during startup (may increase cold-start time).
- `ESP_URL` - Optional. URL to POST commands to your ESP device when danger thresholds are exceeded.

Quick deploy with Modal:

1. Install the Modal CLI and login: https://modal.com/docs
2. Set environment variables (Modal secrets or environment) as needed.
3. From `my-backend` folder, deploy:

```powershell
modal deploy .\modal_app.py
```

For local testing you can run a lightweight dev server (models won't load here unless you have GPU and model files):

```bash
python -m pip install -r requirements.txt
uvicorn modal_app:fastapi_app --reload --port 8000
```

Notes
- Secure your `PARENT_TOKENS` and `ESP_URL` using Modal secrets.
- Consider setting `PRELOAD_MODELS=1` only if you want the service to warm up models on startup.
- Health endpoints: `/health` and `/ready` are available for load balancers.
