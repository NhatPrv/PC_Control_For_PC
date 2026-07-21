# Technical Architecture & API Specifications - Device_Control_AI

Tài liệu thiết kế kiến trúc kỹ thuật và thông số giao thức API cho hệ thống **Device_Control_AI**.

---

## 1. System Architecture (Kiến trúc Hệ thống)

Mô hình hoạt động dựa trên cơ chế **Client-Server trong mạng cục bộ (LAN)**:

```
┌─────────────────────────┐               HTTP REST API (JSON)            ┌─────────────────────────┐
│   Mobile Application    │  ──────────────────────────────────────────►  │   FastAPI Python Server │
│   (Flutter iOS/Android) │                                               │   (Host Laptop/PC)      │
│                         │  ◄──────────────────────────────────────────  │                         │
└─────────────────────────┘               Response (Status/JSON)          └────────────┬────────────┘
             │                                                                         │
             │ Magic Packet (UDP Port 7/9)                                             │ Native OS Calls
             └─────────────────────────────────────────────────────────────────────────┼──────────────────┐
                                                                                       ▼                  ▼
                                                                                 ┌───────────┐      ┌───────────┐
                                                                                 │  Windows  │      │   Linux   │
                                                                                 └───────────┘      └───────────┘
```

- **Client Layer (Mobile App)**:
  - Sử dụng Flutter gửi các HTTP POST/GET Requests chứa payload JSON điều khiển tới Server IP.
  - Sử dụng UDP Socket gửi gói tin Wake-on-LAN Magic Packet trực tiếp tới địa chỉ MAC của card mạng máy tính.
- **Server Layer (Python FastAPI)**:
  - Khởi chạy Web Server bất đồng bộ lắng nghe trên cổng 8000 của địa chỉ `0.0.0.0` trong mạng LAN.
  - Phân tích JSON Payload nhận được và định tuyến lệnh tới Module điều khiển hệ thống tương ứng.

---

## 2. API Endpoints Specification

### 2.1 Endpoint Điều khiển: `POST /api/control`

Tất cả các hành động điều khiển được gửi qua duy nhất một endpoint để đơn giản hóa giao tiếp.

- **Headers**:
  ```http
  Content-Type: application/json
  X-API-Key: <OPTIONAL_LAN_SECRET_KEY>
  ```

- **Request Payload Examples**:

  * **Thao tác Nguồn (Power Operations)**:
    ```json
    {
      "action": "shutdown"
    }
    ```
    *(Các giá trị `action` hợp lệ khác: `"restart"`, `"sleep"`)*

  * **Điều chỉnh Độ sáng màn hình (Brightness)**:
    ```json
    {
      "action": "brightness",
      "value": 70
    }
    ```
    *(Giá trị `value` nhận từ 0 đến 100)*

  * **Điều chỉnh Âm lượng (Volume)**:
    ```json
    {
      "action": "volume",
      "value": 45
    }
    ```
    *(Giá trị `value` nhận từ 0 đến 100)*

  * **Tắt/Bật tiếng (Mute Toggle)**:
    ```json
    {
      "action": "mute"
    }
    ```

- **Response Success (200 OK)**:
  ```json
  {
    "status": "success",
    "message": "Action 'brightness' set to 70 executed successfully.",
    "timestamp": "2026-07-21T00:41:00Z"
  }
  ```

- **Response Error (400 / 500)**:
  ```json
  {
    "status": "error",
    "message": "Invalid volume value. Must be between 0 and 100."
  }
  ```

---

### 2.2 Endpoint Trạng thái Hệ thống: `GET /api/status`

- **Response Success (200 OK)**:
  ```json
  {
    "os": "Windows",
    "hostname": "Legion5Pro-Laptop",
    "cpu_usage_percent": 18.5,
    "ram_usage_percent": 62.3,
    "battery": {
      "percent": 85,
      "power_plugged": true
    },
    "brightness": 70,
    "volume": 45
  }
  ```

---

## 3. Cross-Platform OS Logic (Windows vs Linux)

Hệ thống sử dụng thư viện chuẩn `platform` trong Python để phát hiện Hệ điều hành Host lúc khởi chạy và ánh xạ các lệnh shell tương ứng:

```python
import platform
import os
import subprocess
import screen_brightness_control as sbc

CURRENT_OS = platform.system()  # Returns 'Windows' or 'Linux'

def execute_shutdown():
    if CURRENT_OS == 'Windows':
        os.system("shutdown /s /t 0")
    elif CURRENT_OS == 'Linux':
        subprocess.run(["systemctl", "poweroff"])

def set_brightness(level: int):
    # Thư viện screen-brightness-control tự động xử lý đa nền tảng
    sbc.set_brightness(level)
```

### Bảng Ánh Xạ Lệnh Hệ Thống (Command Mapping Matrix):

| Hành động | Lệnh trên Windows | Lệnh trên Linux (Kali / Ubuntu / Debian) |
| :--- | :--- | :--- |
| **Shutdown** | `shutdown /s /t 0` | `systemctl poweroff` / `shutdown -h now` / DBus |
| **Restart** | `shutdown /r /t 0` | `systemctl reboot` / `reboot` |
| **Sleep** | `rundll32.exe powrprof.dll,SetSuspendState 0,1,0` | `systemctl suspend` / `pm-suspend` |
| **Volume** | CAPI `pycaw` / `ctypes` | `amixer`, `pactl set-sink-volume`, `wpctl` |
| **Mute Toggle**| CAPI `pycaw` | `amixer set Master toggle`, `pactl set-sink-mute` |
| **Brightness**| `screen-brightness-control` | `screen-brightness-control` / `brightnessctl` / `xrandr` |

---

## 4. Security & Network Isolation

1. **Local Area Network (LAN) Restriction**:
   - Server chỉ lắng nghe các kết nối đến từ các IP nằm trong subnet mạng nội bộ (VD: `192.168.x.x`).
2. **Payload Input Validation**:
   - Tất cả request dữ liệu đầu vào được kiểm soát chặt chẽ thông qua **Pydantic Schemas** của FastAPI để loại bỏ nguy cơ Command Injection.
3. **Optional API Key Authentication**:
   - Cung cấp tùy chọn Header `X-API-Key` xác thực cơ bản giữa App di động và Python Server nhằm ngăn ngừa các thiết bị lạ trong cùng mạng LAN điều khiển trái phép.
