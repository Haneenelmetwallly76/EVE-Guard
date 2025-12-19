# ESP32-CAM (AI-Thinker) - EVE-Guard

This folder contains a simple ESP32-CAM sketch that accepts a webhook from the backend to open/close a camera MJPEG stream.

Files
- `esp32_cam.ino` - Arduino sketch. POST control endpoint at `/command`. MJPEG stream at `/stream`.

How it works
1. Backend posts to the ESP URL (set in backend `ESP_URL`) with JSON body `{ "action": "open_camera" }` and header `x-api-key: <secret>` (or `Authorization: Bearer <secret>`).
2. ESP verifies the API key, enables streaming, and responds with the stream URL: `http://<esp_ip>:81/stream`.
3. Parent device (phone) opens the returned stream URL to view live MJPEG.

Setup
1. Edit `esp32_cam.ino` and set `ssid`, `password`, and `API_KEY`.
2. Install ESP32 board support in Arduino IDE (or use PlatformIO) and select `AI-Thinker ESP32-CAM` board.
3. Upload sketch to the ESP32-CAM module.

Security
- Use a strong `API_KEY` and keep it secret. Configure the same secret in the backend `ESP_URL` call headers.
- Run ESP on a trusted network or secure VLAN. The MJPEG stream is not encrypted; consider using a VPN or secured network.

Notes
- The sketch uses a minimal MJPEG implementation; performance depends on your network and ESP memory (PSRAM recommended).
- If you need authentication on the stream endpoint itself, add an access check in `handleStream()`.

Example backend POST (Python using `httpx`):

```python
import httpx

ESP_URL = "http://192.168.1.50/command"
API_KEY = "REPLACE_WITH_SECRET_KEY"

async def call_esp_open():
    async with httpx.AsyncClient() as client:
        resp = await client.post(ESP_URL, json={"action": "open_camera"}, headers={"x-api-key": API_KEY})
        print(resp.status_code, resp.text)
```

Replace `192.168.1.50` and `API_KEY` with your device's IP and secret.
