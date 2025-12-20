#include "esp_camera.h"
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// ---------- CONFIG - set your WiFi and API key here ----------
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* API_KEY = "REPLACE_WITH_SECRET_KEY"; // shared secret with backend

// Port for the camera stream
WebServer server(80);

// Streaming control
volatile bool streaming_enabled = false;

// Camera pins for AI-Thinker ESP32-CAM
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5

#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22


void initCamera(){
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  // init with high specs for reasonable quality
  if(psramFound()){
    config.frame_size = FRAMESIZE_SVGA; // 800x600
    config.jpeg_quality = 10;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_VGA; // 640x480
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }
  Serial.println("Camera initialized");
}

// Helper: check API key from headers
bool check_api_key(){
  if (API_KEY == nullptr || strlen(API_KEY) == 0) return false;
  if (server.hasHeader("x-api-key")){
    String key = server.header("x-api-key");
    return key.equals(API_KEY);
  }
  if (server.hasHeader("Authorization")){
    String auth = server.header("Authorization");
    // support "Bearer <key>"
    if (auth.startsWith("Bearer ")){
      String key = auth.substring(7);
      return key.equals(API_KEY);
    }
  }
  return false;
}

// POST /command receives JSON: {"action":"open_camera"} or {"action":"close_camera"}
void handleCommand(){
  if (!check_api_key()){
    server.send(401, "application/json", "{\"error\": \"unauthorized\"}");
    return;
  }

  String body = server.arg("plain");
  StaticJsonDocument<200> doc;
  DeserializationError err = deserializeJson(doc, body);
  if (err){
    server.send(400, "application/json", "{\"error\": \"invalid_json\"}");
    return;
  }
  const char* action = doc["action"] | "";

  if (strcmp(action, "open_camera") == 0){
    streaming_enabled = true;
    String url = "http://" + WiFi.localIP().toString() + ":81/stream";
    String res;
    res += "{\"status\":\"ok\", \"action\":\"open_camera\", \"stream_url\":\"" + url + "\"}";
    server.send(200, "application/json", res);
    Serial.println("Stream enabled");
    return;
  } else if (strcmp(action, "close_camera") == 0){
    streaming_enabled = false;
    server.send(200, "application/json", "{\"status\":\"ok\", \"action\":\"close_camera\"}");
    Serial.println("Stream disabled");
    return;
  }
  server.send(400, "application/json", "{\"error\": \"unknown_action\"}");
}

// Minimal MJPEG stream on /stream
void handleStream(){
  if (!streaming_enabled){
    server.send(403, "text/plain", "stream not enabled");
    return;
  }

  WiFiClient client = server.client();
  String boundary = "--frame";
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Cache-Control", "no-cache");
  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: multipart/x-mixed-replace; boundary=" + boundary);
  client.println();

  while (streaming_enabled && client.connected()){
    camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Camera capture failed");
      delay(100);
      continue;
    }

    client.println(boundary);
    client.println("Content-Type: image/jpeg");
    client.print("Content-Length: "); client.println(fb->len);
    client.println();
    client.write(fb->buf, fb->len);
    client.println();

    esp_camera_fb_return(fb);
    // small delay to lower bandwidth
    delay(100);
  }

  // close connection
  delay(50);
}

void handleRoot(){
  String s = "ESP32-CAM ready. Use POST /command to control stream.";
  server.send(200, "text/plain", s);
}

void setup(){
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  delay(1000);

  // Init camera
  initCamera();

  // Connect WiFi
  WiFi.begin(ssid, password);
  Serial.printf("Connecting to %s", ssid);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20){
    delay(500);
    Serial.print(".");
    attempts++;
  }
  Serial.println();
  if (WiFi.status() == WL_CONNECTED){
    Serial.print("Connected! IP: "); Serial.println(WiFi.localIP());
  } else {
    Serial.println("WiFi connect failed");
  }

  // Routes
  server.on("/", HTTP_GET, handleRoot);
  server.on("/command", HTTP_POST, handleCommand);
  // stream on port 81: use a lambda to forward to handleStream which uses raw client
  server.on("/stream", HTTP_GET, [](){ handleStream(); });

  server.begin();
  Serial.println("HTTP server started");
}

void loop(){
  server.handleClient();
}
