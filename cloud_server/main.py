import asyncio
import json
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any

app = FastAPI(title="Device_Control_AI Cloud Relay Server (AWS EC2)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Lưu trữ kết nối WebSocket của Laptop Agent
laptop_connection: Optional[WebSocket] = None
latest_laptop_status: Dict[str, Any] = {
    "status": "offline",
    "message": "Laptop Agent is not connected to AWS EC2"
}

class ControlRequest(BaseModel):
    action: str
    value: Optional[int] = None

@app.websocket("/ws/laptop")
async def websocket_endpoint(websocket: WebSocket):
    global laptop_connection, latest_laptop_status
    await websocket.accept()
    laptop_connection = websocket
    print("🟢 Laptop Agent connected to AWS EC2 via WebSocket")
    
    try:
        while True:
            # Nhận thông số trạng thái định kỳ từ Laptop Agent
            data_text = await websocket.receive_text()
            data = json.loads(data_text)
            if data.get("type") == "status_update":
                latest_laptop_status = data.get("data", {})
                latest_laptop_status["status"] = "online"
    except WebSocketDisconnect:
        print("🔴 Laptop Agent disconnected from AWS EC2")
        laptop_connection = None
        latest_laptop_status = {"status": "offline", "message": "Laptop is disconnected"}

@app.get("/")
def root():
    return {
        "server": "Device_Control_AI AWS EC2 Relay",
        "laptop_status": "online" if laptop_connection else "offline"
    }

@app.get("/api/status")
def get_status():
    if not laptop_connection:
        return {
            "os": "Unknown",
            "hostname": "Laptop Offline",
            "cpu_usage_percent": 0.0,
            "ram_usage_percent": 0.0,
            "battery": {"percent": 0, "power_plugged": False},
            "brightness": 0,
            "volume": 0,
            "connected": False
        }
    return latest_laptop_status

@app.post("/api/control")
async def send_control(req: ControlRequest):
    global laptop_connection
    if not laptop_connection:
        raise HTTPException(status_code=503, detail="Laptop Agent is offline or not connected to AWS EC2")
    
    # Chuyển tiếp lệnh điều khiển từ Mobile App tới Laptop Agent qua WebSocket
    command_payload = {
        "type": "command",
        "action": req.action,
        "value": req.value
    }
    await laptop_connection.send_text(json.dumps(command_payload))
    return {"status": "success", "message": f"Command '{req.action}' relayed to Laptop successfully."}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
