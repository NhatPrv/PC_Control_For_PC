# Project Execution Roadmap - Device_Control_AI

Lộ trình chiến lược chi tiết triển khai hệ thống điều khiển máy tính từ xa **Device_Control_AI** qua mạng cục bộ (LAN).

> **Ký hiệu trạng thái**:
> - `[x]`: Đã hoàn thành (Done)
> - `[/]`: Đang thực hiện (In Progress)
> - `[ ]`: Chưa bắt đầu (Pending)

---

## 📌 Phase 1: Environment Setup & Architecture Definition
Giai đoạn khởi tạo môi trường, cấu hình dự án và định nghĩa chuẩn giao tiếp.

- [x] **1.1 Workspace Setup**
  - [x] Khởi tạo dự án Flutter `mobile_app` cho Android/iOS.
  - [x] Khởi tạo dự án Python backend với thư mục cấu trúc mô hình FastAPI (`backend/`).
  - [x] Thiết lập cấu hình tài liệu dự án, lộ trình & các tệp bỏ qua rác (.gitignore, .ignore,...).
- [x] **1.2 Architecture & Protocol Definition**
  - [x] Thống nhất định dạng JSON Payload cho REST API `/api/control` và `/api/status`.
  - [x] Định nghĩa cơ chế phát hiện Hệ điều hành Host (Windows vs Linux).
  - [x] Xác định chiến lược bảo mật cơ bản (API Key / Local Network Restriction).

---

## 📌 Phase 2: Python Backend (FastAPI) & Cross-Platform Command Mappings
Giai đoạn xây dựng RESTful Server bằng Python và thực thi lệnh hệ thống theo từng HĐH.

- [x] **2.1 OS Detection & Abstraction Layer**
  - [x] Viết module phát hiện HĐH sử dụng thư viện `platform`.
  - [x] Xây dựng interface/service định nghĩa tập lệnh hệ thống (Power, Brightness, Volume, Status).
- [x] **2.2 Platform Specific Implementations**
  - [x] **Windows Controller**:
    - [x] Lệnh Shutdown, Restart, Sleep via `subprocess` / `os.system`.
    - [x] Lệnh chỉnh Âm lượng (Volume) qua `ctypes` / `pycaw`.
    - [x] Chỉnh Độ sáng màn hình (Screen Brightness) qua `screen-brightness-control`.
  - [x] **Linux Controller (Kali Linux / Ubuntu / Debian / Arch)**:
    - [x] Lệnh Power management via `systemctl` / `shutdown` / DBus.
    - [x] Lệnh chỉnh Âm lượng & Mute via `amixer`, `pactl`, hoặc `wpctl` (PipeWire).
    - [x] Chỉnh Độ sáng màn hình via `screen-brightness-control`, `brightnessctl`, hoặc `xrandr`.
    - [x] Script tự động chạy ngầm `start_agent.sh` & Autostart Desktop Entry.
- [x] **2.3 FastAPI Endpoint Integration**
  - [x] Lập trình Endpoint `POST /api/control` xử lý các hành động điều khiển.
  - [x] Lập trình Endpoint `GET /api/status` trả về thông tin CPU, RAM, Battery, Volume, Brightness.
  - [x] Cấu hình CORS và uvicorn runner lắng nghe trên IP LAN `0.0.0.0:8000`.

---

## 📌 Phase 3: Flutter App Integration
Xây dựng giao diện ứng dụng di động Flutter và kết nối với Backend Python.

- [x] **3.1 UI/UX Design & Layout**
  - [x] Tái hiện 100% bản mẫu v0.dev với phong cách Dark Mode Glassmorphism trên Flutter.
  - [x] Xây dựng đầy đủ các Widgets: DashboardHeader, DeviceMonitorCard, ControlSlider, PowerActionButton, HomeScreen.
- [x] **3.2 State Management & HTTP Service**
  - [x] Tích hợp package `http` & `provider` thực hiện các yêu cầu REST API POST/GET mượt mà.
  - [x] Tự động lưu vết cấu hình IP Host & Port qua `shared_preferences`.
  - [x] Tự động cập nhật thông số hệ thống realtime (Auto refresh 3s).
- [x] **3.3 iOS & Network Privacy Configurations**
  - [x] Cấu hình `Info.plist` cấp quyền `NSLocalNetworkUsageDescription` và `NSAppTransportSecurity` trên iOS.
  - [x] Cấu hình `AndroidManifest.xml` cấp quyền `INTERNET` và `android:usesCleartextTraffic="true"` cho Android.

---

## 📌 Phase 4: Testing, Security Hardening & Wake-on-LAN Integration
Kiểm thử toàn diện, tối ưu bảo mật và tích hợp khả năng bật máy từ xa.

- [/] **4.1 Wake-on-LAN (WoL) Feature**
  - [ ] Tích hợp package `wake_on_lan` trên ứng dụng Flutter.
  - [ ] Xây dựng cơ chế lưu trữ MAC Address và Broadcast IP của Laptop Host.
  - [ ] Kiểm thử gửi Magic Packet qua UDP port 7/9 để bật máy từ trạng thái Off/Sleep.
- [/] **4.2 Security & Validation Hardening**
  - [x] Đã cấu hình xác thực Header `X-API-Key` giữa App di động và Python Server.
  - [x] Validate dữ liệu đầu vào Pydantic Schemas trong khoảng (0-100).
- [/] **4.3 End-to-End Testing & Polish**
  - [ ] Kiểm thử chạy đồng thời Python Backend và Flutter App trong mạng LAN.
  - [ ] Viết tài liệu hướng dẫn vận hành hoàn chỉnh.
