import asyncio
import websockets
import json
import sys
import os

# Nạp thư mục app vào path để import SystemService
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from app.services.system_service import SystemService

# Điền IP Public của AWS EC2 Instance của bạn ở đây
AWS_EC2_IP = os.getenv("AWS_EC2_IP", "127.0.0.1")
AWS_EC2_PORT = os.getenv("AWS_EC2_PORT", "8000")

WS_URL = f"ws://{AWS_EC2_IP}:{AWS_EC2_PORT}/ws/laptop"

async def start_agent():
    print(f"🔄 Connecting Laptop Agent to AWS EC2: {WS_URL} ...")
    while True:
        try:
            async with websockets.connect(WS_URL) as websocket:
                print("🟢 Successfully connected to AWS EC2 Relay Server!")
                
                # Task gửi trạng thái hệ thống định kỳ 2s/lần
                async def send_status_loop():
                    while True:
                        try:
                            status_data = SystemService.get_system_status()
                            payload = {
                                "type": "status_update",
                                "data": status_data
                            }
                            await websocket.send(json.dumps(payload))
                            await asyncio.sleep(2)
                        except Exception as e:
                            print(f"Status loop error: {e}")
                            break

                # Task lắng nghe lệnh từ AWS EC2 đẩy xuống
                async def receive_commands_loop():
                    while True:
                        try:
                            message = await websocket.recv()
                            data = json.loads(message)
                            if data.get("type") == "command":
                                action = data.get("action")
                                val = data.get("value")
                                print(f"⚡ Received Command from AWS EC2: action={action}, value={val}")
                                
                                # Thực thi lệnh phần cứng trên Laptop
                                if action in ["shutdown", "restart", "sleep"]:
                                    SystemService.execute_power_action(action)
                                elif action == "brightness" and val is not None:
                                    SystemService.set_brightness(val)
                                elif action == "volume" and val is not None:
                                    SystemService.set_volume(val)
                                elif action == "mute":
                                    vol = SystemService.get_volume()
                                    SystemService.set_volume(0 if vol > 0 else 50)
                        except Exception as e:
                            print(f"Receive loop error: {e}")
                            break

                await asyncio.gather(send_status_loop(), receive_commands_loop())

        except Exception as e:
            print(f"❌ Connection failed: {e}. Retrying in 5 seconds...")
            await asyncio.sleep(5)

if __name__ == "__main__":
    asyncio.run(start_agent())
