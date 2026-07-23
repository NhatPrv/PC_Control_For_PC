from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, Field
from typing import Optional, Literal
from app.services.system_service import SystemService
from app.core.config import settings

router = APIRouter(prefix="/api", tags=["Control & Status"])

class ControlRequest(BaseModel):
    action: Literal["shutdown", "restart", "sleep", "brightness", "volume", "mute", "connect"] = Field(
        ..., description="Hành động điều khiển hệ thống"
    )
    value: Optional[int] = Field(
        None, ge=0, le=100, description="Giá trị tương ứng cho brightness (0-100) hoặc volume (0-100)"
    )

def verify_api_key(x_api_key: Optional[str] = Header(None)):
    if settings.API_KEY and x_api_key != settings.API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API Key")

current_paired_phone: Optional[str] = None

@router.get("/status", dependencies=[Depends(verify_api_key)])
def get_status():
    """Lấy toàn bộ thông số tải hệ thống, dung lượng pin, âm lượng và độ sáng."""
    global current_paired_phone
    status_data = SystemService.get_system_status()
    # Nếu điện thoại gửi HTTP GET /api/status qua LAN thành công ➔ Tự động xác nhận LAN Session hợp lệ!
    if current_paired_phone != "DISCONNECTED":
        current_paired_phone = "Mobile Device (LAN)"
    
    is_active = current_paired_phone == "Mobile Device (LAN)" or (current_paired_phone is not None and current_paired_phone != "DISCONNECTED")
    status_data["connected"] = is_active
    status_data["is_paired"] = is_active
    status_data["paired_mode"] = "LAN" if is_active else "Standby"
    status_data["paired_device"] = current_paired_phone
    return status_data

@router.post("/disconnect", dependencies=[Depends(verify_api_key)])
def disconnect_session():
    """Ngắt kết nối LAN."""
    global current_paired_phone
    current_paired_phone = None
    print("🔴 Active Mobile Session Disconnected!")
    return {"status": "success", "message": "Disconnected LAN session."}

@router.post("/control", dependencies=[Depends(verify_api_key)])
def execute_control(req: ControlRequest):
    """Xử lý các thao tác điều khiển thiết bị."""
    global current_paired_phone
    if req.action == "connect":
        current_paired_phone = "Mobile Device"
        print("🟢 Active Mobile Session Connected & Paired!")
        return {"status": "success", "message": "LAN connection active."}
    if req.action in ["shutdown", "restart", "sleep"]:
        success = SystemService.execute_power_action(req.action)
        if not success:
            raise HTTPException(status_code=500, detail=f"Failed to execute power action '{req.action}'")
        return {"status": "success", "message": f"Power action '{req.action}' triggered."}

    elif req.action == "brightness":
        if req.value is None:
            raise HTTPException(status_code=400, detail="Field 'value' is required for brightness action.")
        success = SystemService.set_brightness(req.value)
        if not success:
            raise HTTPException(status_code=500, detail="Failed to set screen brightness.")
        return {"status": "success", "message": f"Brightness set to {req.value}%."}

    elif req.action == "volume":
        if req.value is None:
            raise HTTPException(status_code=400, detail="Field 'value' is required for volume action.")
        success = SystemService.set_volume(req.value)
        if not success:
            raise HTTPException(status_code=500, detail="Failed to set master volume.")
        return {"status": "success", "message": f"Volume set to {req.value}%."}

    elif req.action == "mute":
        # Toggle mute bằng cách set volume 0
        current_vol = SystemService.get_volume()
        target_vol = 0 if current_vol > 0 else 50
        SystemService.set_volume(target_vol)
        return {"status": "success", "message": f"Volume toggled to {target_vol}%."}

    raise HTTPException(status_code=400, detail="Invalid action")
