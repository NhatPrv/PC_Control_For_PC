# Device_Control_AI 💻📱

**Device_Control_AI** là giải pháp điều khiển máy tính (Laptop/PC) từ xa thông qua điện thoại thông minh (iOS/Android) trên cùng mạng Wi-Fi nội bộ (LAN). Dự án kết hợp sức mạnh của server FastAPI (Python) chạy ngầm trên máy tính và ứng dụng di động Flutter mượt mà, hỗ trợ cả hai hệ điều hành máy tính phổ biến: **Windows** và **Linux**.

---

## 📚 Project Documentation (Tài liệu dự án)

- 📌 [**Execution Roadmap (Lộ trình triển khai)**](docs/ROADMAP.md): Chi tiết 4 giai đoạn phát triển và danh sách công việc.
- 🏗️ [**Architecture & API Specifications (Kiến trúc & API)**](docs/ARCHITECTURE_DOCS.md): Chi tiết sơ đồ Client-Server, định dạng JSON payload và ánh xạ lệnh Windows/Linux.

---

## 🔥 Features (Tính năng cốt lõi)

- ⚡ **Power Control**: Tắt máy (Shutdown), Khởi động lại (Restart), Chuyển chế độ Ngủ (Sleep).
- ☀️ **Screen Brightness**: Điều chỉnh độ sáng màn hình laptop theo thời gian thực (Slider 0-100%).
- 🔊 **Master Volume**: Tăng/giảm và thay đổi mức âm lượng hệ thống linh hoạt.
- 📊 **System Monitor**: Theo dõi các chỉ số sống của máy tính (Dung lượng Pin, Tải CPU, Mức RAM sử dụng).
- 🔌 **Wake-on-LAN (WoL)**: Bật máy tính từ xa qua mạng LAN bằng việc gửi gói tin Magic Packet.

---

## 🛠 Tech Stack (Công nghệ sử dụng)

| Thành phần | Công nghệ / Thư viện chính | Mô tả |
| :--- | :--- | :--- |
| **Mobile App** | [Flutter](https://flutter.dev/) (Dart) | Xây dựng giao diện ứng dụng đa nền tảng (iOS & Android). |
| **Mobile WoL** | `wake_on_lan` package | Gửi Magic Packet UDP khởi động máy tính từ xa. |
| **Backend Server** | [FastAPI](https://fastapi.tiangolo.com/) (Python 3.10+) | RESTful API server tốc độ cao chạy trên Laptop/PC. |
| **Brightness Control**| `screen-brightness-control` | Thư viện Python điều khiển độ sáng màn hình đa nền tảng. |
| **System Info & Exec**| `psutil`, `subprocess`, `platform` | Đọc thông số phần cứng và thực thi lệnh Shell hệ thống. |

---

## 🚀 Quick Start Guide (Hướng dẫn khởi chạy nhanh)

### 1. Khởi chạy Python Server (Trên Máy tính Host)

```bash
# 1. Truy cập thư mục backend
cd backend

# 2. Tạo và kích hoạt môi trường ảo Python
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux:
source venv/bin/activate

# 3. Cài đặt các thư viện phụ thuộc
pip install -r requirements.txt

# 4. Khởi chạy Uvicorn Server
python main.py
# Server sẽ lắng nghe tại: http://0.0.0.0:8000
```

#### Các biến môi trường ví dụ (`.env`):
```env
HOST=0.0.0.0
PORT=8000
SECRET_API_KEY=my_secure_lan_key_123
```

---

### 2. Khởi chạy Flutter App (Trên Điện thoại)

```bash
# 1. Truy cập thư mục mobile app
cd mobile_app

# 2. Lấy các gói phụ thuộc Flutter
flutter pub get

# 3. Khởi chạy app trên thiết bị (Android / iOS)
flutter run
```

---

## 🔒 Security & Privacy

Ứng dụng chỉ giao tiếp nội bộ trong cùng lớp mạng Wi-Fi (LAN). Các request bên ngoài không thể truy cập nếu không có quyền trong mạng cục bộ. Đối với thiết bị iOS, ứng dụng yêu cầu cấp quyền tìm kiếm thiết bị mạng cục bộ (`Local Network`).
