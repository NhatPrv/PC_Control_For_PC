import asyncio
import websockets
import json
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from app.services.system_service import SystemService

AWS_EC2_IP = os.getenv("AWS_EC2_IP", "18.143.90.229")
AWS_EC2_PORT = os.getenv("AWS_EC2_PORT", "8002")
SECRET_API_KEY = os.getenv("SECRET_API_KEY", "MyPrivateLaptopControlKey@2026")

WS_URL = f"ws://{AWS_EC2_IP}:{AWS_EC2_PORT}/ws/laptop"

async def start_agent():
    print(f"🔄 Connecting Laptop Agent to AWS EC2: {WS_URL} ...")
    extra_headers = {
        "x-api-key": SECRET_API_KEY
    }
    
    while True:
        try:
            async with websockets.connect(WS_URL, extra_headers=extra_headers) as websocket:
                print("🟢 Successfully authenticated & connected to AWS EC2 Relay Server!")
                
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

                async def receive_commands_loop():
                    while True:
                        try:
                            message = await websocket.recv()
                            data = json.loads(message)
                            if data.get("type") == "command":
                                action = data.get("action")
                                val = data.get("value")
                                print(f"⚡ Received Command from AWS EC2: action={action}, value={val}")
                                
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
            print(f"❌ Connection failed or Unauthorized key: {e}. Retrying in 5 seconds...")
            await asyncio.sleep(5)

if __name__ == "__main__":
    asyncio.run(start_agent())
