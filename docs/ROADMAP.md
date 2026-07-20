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
  - [/] Khởi tạo dự án Python backend với thư mục cấu trúc mô hình FastAPI.
  - [x] Thiết lập cấu hình tài liệu dự án, lộ trình & các tệp bỏ qua rác (.gitignore, .ignore,...).
- [x] **1.2 Architecture & Protocol Definition**
  - [x] Thống nhất định dạng JSON Payload cho REST API `/api/control` và `/api/status`.
  - [x] Định nghĩa cơ chế phát hiện Hệ điều hành Host (Windows vs Linux).
  - [x] Xác định chiến lược bảo mật cơ bản (API Key / Local Network Restriction).

---

## 📌 Phase 2: Python Backend (FastAPI) & Cross-Platform Command Mappings
Giai đoạn xây dựng RESTful Server bằng Python và thực thi lệnh hệ thống theo từng HĐH.

- [/] **2.1 OS Detection & Abstraction Layer**
  - [/] Viết module phát hiện HĐH sử dụng thư viện `platform`.
  - [/] Xây dựng interface/abstract class định nghĩa tập lệnh hệ thống (Power, Brightness, Volume, Status).
- [ ] **2.2 Platform Specific Implementations**
  - [ ] **Windows Controller**:
    - [ ] Lệnh Shutdown, Restart, Sleep via `subprocess` / `os.system`.
    - [ ] Lệnh chỉnh Âm lượng (Volume) qua `ctypes` / `pycaw`.
    - [ ] Chỉnh Độ sáng màn hình (Screen Brightness) qua `screen-brightness-control`.
  - [ ] **Linux Controller**:
    - [ ] Lệnh Power management via `systemctl` / `shutdown`.
    - [ ] Lệnh chỉnh Âm lượng via `amixer` hoặc `pactl`.
    - [ ] Chỉnh Độ sáng màn hình via `brightnessctl` hoặc `xrandr` / `screen-brightness-control`.
- [ ] **2.3 FastAPI Endpoint Integration**
  - [ ] Lập trình Endpoint `POST /api/control` xử lý các hành động điều khiển.
  - [ ] Lập trình Endpoint `GET /api/status` trả về thông tin CPU, RAM, Battery, Volume, Brightness.
  - [ ] Cấu hình CORS và uvicorn runner lắng nghe trên IP LAN `0.0.0.0:8000`.

---

## 📌 Phase 3: Flutter App Integration
Xây dựng giao diện ứng dụng di động Flutter và kết nối với Backend Python.

- [/] **3.1 UI/UX Design & Layout**
  - [ ] Màn hình Cấu hình IP Host & Kết nối.
  - [ ] Dashboard chính: Thẻ thông số Hệ thống (CPU, RAM, Pin).
  - [ ] Bộ điều khiển Sliders: Thanh trượt Chỉnh Âm lượng và Độ sáng màn hình.
  - [ ] Bộ nút bấm Nhanh: Shutdown, Restart, Sleep, Mute.
- [ ] **3.2 State Management & HTTP Service**
  - [ ] Tích hợp `http` / `dio` package gửi request REST API.
  - [ ] Cấu hình Quản lý trạng thái (State Management) cho cập nhật realtime/mượt mà của Sliders và Buttons.
- [ ] **3.3 iOS & Network Privacy Configurations**
  - [ ] Khởi tạo file `Info.plist` cấu hình quyền `NSLocalNetworkUsageDescription` và `NSBonjourServices` trên iOS.
  - [ ] Cấu hình Android Manifest cho phép truy cập giao thức HTTP không mã hóa (Cleartext Traffic) trên mạng LAN.

---

## 📌 Phase 4: Testing, Security Hardening & Wake-on-LAN Integration
Kiểm thử toàn diện, tối ưu bảo mật và tích hợp khả năng bật máy từ xa.

- [ ] **4.1 Wake-on-LAN (WoL) Feature**
  - [ ] Tích hợp package `wake_on_lan` trên ứng dụng Flutter.
  - [ ] Xây dựng cơ chế lưu trữ MAC Address và Broadcast IP của Laptop Host.
  - [ ] Kiểm thử gửi Magic Packet qua UDP port 7/9 để bật máy từ trạng thái Off/Sleep.
- [ ] **4.2 Security & Validation Hardening**
  - [ ] Thêm cơ chế xác thực Token / PIN đơn giản giữa Mobile App và Python Server.
  - [ ] Validate dữ liệu đầu vào (VD: giá trị brightness/volume trong khoảng 0-100).
- [ ] **4.3 End-to-End Testing & Polish**
  - [ ] Kiểm thử trên các môi trường thực tế (Windows 11 & Ubuntu/Debian Linux).
  - [ ] Xử lý trôi chảy các lỗi mất kết nối mạng LAN hoặc Timeout request.
  - [ ] Viết tài liệu hướng dẫn vận hành hoàn chỉnh.
