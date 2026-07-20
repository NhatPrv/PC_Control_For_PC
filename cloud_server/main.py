import asyncio
import json
import os
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional, Dict, Any

app = FastAPI(title="PC Control Cloud Relay Server (Multi-Tenant AWS EC2)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Phục vụ file tĩnh và Landing Page
STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
if not os.path.exists(STATIC_DIR):
    os.makedirs(STATIC_DIR)
downloads_dir = os.path.join(STATIC_DIR, "downloads")
if not os.path.exists(downloads_dir):
    os.makedirs(downloads_dir)

app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

SECRET_API_KEY = os.getenv("SECRET_API_KEY", "MyPrivateLaptopControlKey@2026")

active_laptops: Dict[str, WebSocket] = {}
latest_laptop_statuses: Dict[str, Dict[str, Any]] = {}

class ControlRequest(BaseModel):
    device_id: Optional[str] = None
    action: str
    value: Optional[int] = None

class DisconnectRequest(BaseModel):
    device_id: Optional[str] = None

def verify_api_key(x_api_key: Optional[str] = Header(None)):
    if SECRET_API_KEY and x_api_key != SECRET_API_KEY:
        raise HTTPException(status_code=401, detail="🔒 Access Denied: Invalid Secret API Key")

@app.get("/")
def read_root():
    index_file = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(index_file):
        return FileResponse(index_file)
    return {
        "server": "PC Control AWS EC2 Multi-Tenant Relay",
        "active_devices_count": len(active_laptops),
        "active_device_ids": list(active_laptops.keys())
    }

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

@app.get("/api/status", dependencies=[Depends(verify_api_key)])
def get_status(device_id: Optional[str] = None):
    target_id = device_id
    if not target_id or target_id not in active_laptops:
        if active_laptops:
            target_id = list(active_laptops.keys())[0]

    if not target_id or target_id not in active_laptops:
        return {
            "device_id": "none",
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
    return latest_laptop_statuses.get(target_id, {"connected": True, "status": "online"})

@app.post("/api/control", dependencies=[Depends(verify_api_key)])
async def send_control(req: ControlRequest):
    target_id = req.device_id
    if not target_id or target_id not in active_laptops:
        if active_laptops:
            target_id = list(active_laptops.keys())[0]

    if not target_id or target_id not in active_laptops:
        raise HTTPException(status_code=503, detail="No active Laptop Agent connected to AWS EC2")
    
    ws = active_laptops[target_id]
    command_payload = {
        "type": "command",
        "action": req.action,
        "value": req.value
    }
    await ws.send_text(json.dumps(command_payload))
    return {"status": "success", "message": f"Command '{req.action}' relayed to Laptop [{target_id}] successfully."}

@app.post("/api/disconnect", dependencies=[Depends(verify_api_key)])
async def disconnect_session(req: DisconnectRequest):
    target_id = req.device_id
    if not target_id or target_id not in active_laptops:
        if active_laptops:
            target_id = list(active_laptops.keys())[0]

    if target_id and target_id in active_laptops:
        ws = active_laptops.pop(target_id)
        try:
            # Gửi thông báo ngắt kết nối cho Laptop Agent dừng loop
            await ws.send_text(json.dumps({"type": "disconnect_agent"}))
            await asyncio.sleep(0.2)
            await ws.close(code=1000, reason="User disconnected session")
        except Exception:
            pass
    if target_id and target_id in latest_laptop_statuses:
        latest_laptop_statuses[target_id]["connected"] = False
        latest_laptop_statuses[target_id]["status"] = "offline"
    return {"status": "success", "message": f"Session [{target_id}] disconnected successfully."}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=True)
