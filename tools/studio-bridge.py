"""
Studio Bridge — HTTP-сервер для связи Claude Code <-> Roblox Studio Plugin.

Как это работает:
1. Этот сервер запускается локально (порт 28859)
2. Claude Code отправляет команды через HTTP POST
3. Сервер передаёт их в Studio через файловый мост или plugin settings
4. Studio plugin выполняет команду и возвращает результат

Запуск: python tools/studio-bridge.py
"""

import http.server
import json
import os
import time
import subprocess
from pathlib import Path

PORT = 28859
ROBLOX_PLUGINS_DIR = Path.home() / "Documents" / "Roblox"
COMMAND_FILE = ROBLOX_PLUGINS_DIR / "claude_command.json"
RESPONSE_FILE = ROBLOX_PLUGINS_DIR / "claude_response.json"


class StudioBridgeHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        print(f"[Bridge] {args[0]}")

    def do_GET(self):
        """GET /status — проверка что мост работает"""
        if self.path == "/status":
            self.send_json({"status": "running", "port": PORT})
        elif self.path == "/screenshot":
            self.take_screenshot()
        elif self.path == "/screenshot/studio":
            self.take_screenshot("studio")
        elif self.path == "/screenshot/blender":
            self.take_screenshot("blender")
        else:
            self.send_json({"error": "Unknown endpoint", "endpoints": [
                "GET /status",
                "GET /screenshot",
                "GET /screenshot/studio",
                "GET /screenshot/blender",
                "POST /command",
            ]})

    def do_POST(self):
        """POST /command — отправить команду в Studio"""
        if self.path == "/command":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8")

            try:
                command = json.loads(body)
            except json.JSONDecodeError:
                self.send_json({"error": "Invalid JSON"}, 400)
                return

            # Добавляем уникальный ID
            command["id"] = str(time.time_ns())

            # Записываем команду в файл
            COMMAND_FILE.write_text(json.dumps(command))

            # Ждём ответа (polling)
            response = self.wait_for_response(command["id"], timeout=10)
            self.send_json(response)
        else:
            self.send_json({"error": "POST only to /command"}, 404)

    def wait_for_response(self, command_id, timeout=10):
        """Ждёт ответа от Studio plugin."""
        start = time.time()
        while time.time() - start < timeout:
            if RESPONSE_FILE.exists():
                try:
                    data = json.loads(RESPONSE_FILE.read_text())
                    if data.get("_command_id") == command_id:
                        RESPONSE_FILE.unlink(missing_ok=True)
                        return data
                except (json.JSONDecodeError, IOError):
                    pass
            time.sleep(0.1)

        return {"error": "Timeout waiting for Studio response", "timeout": timeout}

    def take_screenshot(self, target="screen"):
        """Делает скриншот и возвращает путь."""
        output = f"/tmp/studio_screenshot_{int(time.time())}.png"
        script = os.path.join(os.path.dirname(__file__), "screenshot.sh")

        try:
            result = subprocess.run(
                ["bash", script, target, output],
                capture_output=True, text=True, timeout=5
            )
            if os.path.exists(output):
                self.send_json({"success": True, "path": output, "output": result.stdout.strip()})
            else:
                self.send_json({"error": "Screenshot failed", "stderr": result.stderr})
        except Exception as e:
            self.send_json({"error": str(e)})

    def send_json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))


def main():
    # Убедимся что папка для файлового моста существует
    ROBLOX_PLUGINS_DIR.mkdir(parents=True, exist_ok=True)

    server = http.server.HTTPServer(("127.0.0.1", PORT), StudioBridgeHandler)
    print(f"[Studio Bridge] Running on http://127.0.0.1:{PORT}")
    print(f"[Studio Bridge] Endpoints:")
    print(f"  GET  /status            — проверка статуса")
    print(f"  GET  /screenshot        — скриншот экрана")
    print(f"  GET  /screenshot/studio — скриншот Roblox Studio")
    print(f"  POST /command           — команда в Studio plugin")
    print(f"[Studio Bridge] Ctrl+C to stop")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[Studio Bridge] Stopped")
        server.server_close()


if __name__ == "__main__":
    main()
