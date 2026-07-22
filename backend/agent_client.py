import asyncio
import websockets
import json
import sys
import os
import uuid
import threading
import uvicorn

# Đảm bảo mã hóa UTF-8 trên Windows console không bị lỗi charmap
sys.stdout.reconfigure(encoding='utf-8')

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from app.services.system_service import SystemService
from app.api import routes
from main import app as fastapi_app

AWS_EC2_IP = os.getenv("AWS_EC2_IP", "18.143.90.229")
AWS_EC2_PORT = os.getenv("AWS_EC2_PORT", "8002")
SECRET_API_KEY = os.getenv("SECRET_API_KEY", "MyPrivateLaptopControlKey@2026")

DEVICE_ID = f"LAP-{hex(uuid.getnode())[2:].upper()[:8]}"
WS_URL = f"ws://{AWS_EC2_IP}:{AWS_EC2_PORT}/ws/laptop?device_id={DEVICE_ID}&api_key={SECRET_API_KEY}"

is_paired_active = False

def run_local_fastapi_server():
    """Khởi chạy Local FastAPI Server trên cổng 8002 để lắng nghe kết nối LAN trực tiếp từ Điện thoại."""
    try:
        print(f"[LAN Server] Starting Local LAN HTTP/API Server on 0.0.0.0:8002 ...")
        uvicorn.run(fastapi_app, host="0.0.0.0", port=8002, log_level="warning")
    except Exception as e:
        print(f"[LAN Server Error]: {e}")

async def start_agent():
    global is_paired_active

    # Chạy Local FastAPI Server ở Thread riêng biệt để hỗ trợ LAN Mode trực tiếp
    server_thread = threading.Thread(target=run_local_fastapi_server, daemon=True)
    server_thread.start()

    print(f"[Agent] Connecting Laptop Agent [{DEVICE_ID}] to AWS EC2: ws://{AWS_EC2_IP}:{AWS_EC2_PORT}/ws/laptop ...")
    
    while True:
        try:
            async with websockets.connect(WS_URL) as websocket:
                print(f"[Agent] Successfully authenticated & connected to AWS EC2 Relay Server as [{DEVICE_ID}]!")
                
                async def send_status_loop():
                    global is_paired_active
                    while True:
                        try:
                            # Luôn gửi thông số phần cứng để Cloud Relay nhận biết Laptop đang Online
                            status_data = SystemService.get_system_status()
                            status_data["device_id"] = DEVICE_ID
                            payload = {
                                "type": "status_update",
                                "data": status_data
                            }
                            await websocket.send(json.dumps(payload))
                            await asyncio.sleep(2)
                        except Exception as e:
                            print(f"[Status Loop Error]: {e}")
                            break

                async def receive_commands_loop():
                    global is_paired_active
                    while True:
                        try:
                            message = await websocket.recv()
                            data = json.loads(message)
                            
                            msg_type = data.get("type")
                            if msg_type == "session_disconnected":
                                is_paired_active = False
                                routes.current_paired_phone = None
                                print(f"[Agent] Session Disconnected by Mobile App. Pausing hardware telemetry.")
                            elif msg_type == "command":
                                action = data.get("action")
                                val = data.get("value")
                                print(f"[Command] Received Command [{DEVICE_ID}] from AWS EC2: action={action}, value={val}")
                                
                                if action == "connect":
                                    is_paired_active = True
                                    routes.current_paired_phone = "Mobile App (Remote)"
                                    print(f"[Agent] Session Activated & Paired with Mobile App!")
                                elif action in ["shutdown", "restart", "sleep"]:
                                    routes.current_paired_phone = None
                                    SystemService.execute_power_action(action)
                                elif action == "unlock":
                                    pass_val = str(val) if val is not None else ""
                                    SystemService.unlock_windows(pass_val)
                                elif action == "brightness" and val is not None:
                                    SystemService.set_brightness(val)
                                elif action == "volume" and val is not None:
                                    SystemService.set_volume(val)
                                elif action == "mute":
                                    SystemService.toggle_mute()
                        except Exception as e:
                            print(f"[Receive Loop Error]: {e}")
                            break

                await asyncio.gather(send_status_loop(), receive_commands_loop())

        except Exception as e:
            print(f"[Agent Error] Connection failed or Disconnected: {e}. Retrying in 5 seconds...")
            await asyncio.sleep(5)

if __name__ == "__main__":
    asyncio.run(start_agent())
