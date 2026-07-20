import asyncio
import json
import os
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any

app = FastAPI(title="Device_Control_AI Cloud Relay Server (Multi-Tenant AWS EC2)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_API_KEY = os.getenv("SECRET_API_KEY", "MyPrivateLaptopControlKey@2026")

# Quản lý Đa người dùng / Đa thiết bị bằng Dictionary {device_id: WebSocket}
active_laptops: Dict[str, WebSocket] = {}
latest_laptop_statuses: Dict[str, Dict[str, Any]] = {}

class ControlRequest(BaseModel):
    device_id: Optional[str] = "default_device"
    action: str
    value: Optional[int] = None

class DisconnectRequest(BaseModel):
    device_id: Optional[str] = "default_device"

def verify_api_key(x_api_key: Optional[str] = Header(None)):
    if SECRET_API_KEY and x_api_key != SECRET_API_KEY:
        raise HTTPException(status_code=401, detail="🔒 Access Denied: Invalid Secret API Key")

@app.websocket("/ws/laptop")
async def websocket_endpoint(websocket: WebSocket, device_id: Optional[str] = "default_device", api_key: Optional[str] = None):
    client_key = api_key or websocket.headers.get("x-api-key")
    if SECRET_API_KEY and client_key != SECRET_API_KEY:
        print(f"⛔ Rejected unauthorized Laptop Agent attempt for device: {device_id}")
        await websocket.close(code=4001, reason="Unauthorized Secret Key")
        return

    await websocket.accept()
    active_laptops[device_id] = websocket
    print(f"🟢 Laptop Agent [{device_id}] connected to AWS EC2 via WebSocket")
    
    try:
        while True:
            data_text = await websocket.receive_text()
            data = json.loads(data_text)
            if data.get("type") == "status_update":
                status_payload = data.get("data", {})
                status_payload["status"] = "online"
                status_payload["connected"] = True
                status_payload["device_id"] = device_id
                latest_laptop_statuses[device_id] = status_payload
    except WebSocketDisconnect:
        print(f"🔴 Laptop Agent [{device_id}] disconnected from AWS EC2")
        active_laptops.pop(device_id, None)
        if device_id in latest_laptop_statuses:
            latest_laptop_statuses[device_id]["status"] = "offline"
            latest_laptop_statuses[device_id]["connected"] = False

@app.get("/")
def root():
    return {
        "server": "Device_Control_AI AWS EC2 Multi-Tenant Relay",
        "active_devices_count": len(active_laptops),
        "active_device_ids": list(active_laptops.keys())
    }

@app.get("/api/status", dependencies=[Depends(verify_api_key)])
def get_status(device_id: Optional[str] = "default_device"):
    if device_id not in active_laptops:
        return {
            "device_id": device_id,
            "os": "Unknown",
            "hostname": "Laptop Offline",
            "cpu_usage_percent": 0.0,
            "ram_usage_percent": 0.0,
            "battery": {"percent": 0, "power_plugged": False},
            "brightness": 0,
            "volume": 0,
            "connected": False,
            "status": "offline"
        }
    return latest_laptop_statuses.get(device_id, {"connected": True, "status": "online"})

@app.post("/api/control", dependencies=[Depends(verify_api_key)])
async def send_control(req: ControlRequest):
    dev_id = req.device_id or "default_device"
    if dev_id not in active_laptops:
        raise HTTPException(status_code=503, detail=f"Laptop Agent [{dev_id}] is offline or disconnected")
    
    ws = active_laptops[dev_id]
    command_payload = {
        "type": "command",
        "action": req.action,
        "value": req.value
    }
    await ws.send_text(json.dumps(command_payload))
    return {"status": "success", "message": f"Command '{req.action}' relayed to Laptop [{dev_id}] successfully."}

@app.post("/api/disconnect", dependencies=[Depends(verify_api_key)])
async def disconnect_session(req: DisconnectRequest):
    dev_id = req.device_id or "default_device"
    if dev_id in active_laptops:
        ws = active_laptops.pop(dev_id)
        try:
            await ws.close(code=1000, reason="User disconnected session")
        except Exception:
            pass
    if dev_id in latest_laptop_statuses:
        latest_laptop_statuses[dev_id]["connected"] = False
        latest_laptop_statuses[dev_id]["status"] = "offline"
    return {"status": "success", "message": f"Session [{dev_id}] disconnected successfully."}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=True)
