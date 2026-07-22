import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../services/api_service.dart';

class ControlProvider extends ChangeNotifier {
  String _serverIp = "18.143.90.229";
  String _laptopLanIp = "";
  int _serverPort = 8002;
  String _apiKey = "MyPrivateLaptopControlKey@2026";
  String _deviceId = "default_device";
  String _devicePassword = "";
  String _macAddress = "";

  SystemStatus? _status;
  bool _isConnected = false;
  bool _manuallyDisconnected = false;
  String? _phoneWifiIp;
  Timer? _timer;
  String? _activePowerAction;

  String get serverIp => _serverIp;
  String get laptopLanIp => _laptopLanIp;
  String get lanIp => _laptopLanIp.isNotEmpty ? _laptopLanIp : _serverIp;
  int get serverPort => _serverPort;
  String get apiKey => _apiKey;
  String get deviceId => _deviceId;
  String get devicePassword => _devicePassword;
  String get macAddress => _macAddress.isNotEmpty ? _macAddress : (_status?.macAddress ?? "");
  SystemStatus? get status => _status;
  bool get isConnected => _isConnected;
  bool get manuallyDisconnected => _manuallyDisconnected;
  String? get activePowerAction => _activePowerAction;

  bool get isLanConnection {
    if (_serverIp.isEmpty) return true;
    final cleanIp = _serverIp.trim();
    if (cleanIp.startsWith("192.168.") ||
        cleanIp.startsWith("10.") ||
        cleanIp == "localhost" ||
        cleanIp == "127.0.0.1") {
      return true;
    }
    if (cleanIp.startsWith("172.")) {
      final parts = cleanIp.split(".");
      if (parts.length >= 2) {
        final second = int.tryParse(parts[1]) ?? 0;
        if (second >= 16 && second <= 31) return true;
      }
    }
    return false;
  }

  /// Thuật toán kiểm tra Điện thoại và Laptop có đang ở CÙNG MẠNG WI-FI LAN hay không
  bool get isSameLanSubnet {
    if (_phoneWifiIp == null || _phoneWifiIp!.isEmpty) {
      return isLanConnection;
    }
    final phoneParts = _phoneWifiIp!.split('.');
    final targetIp = _laptopLanIp.isNotEmpty ? _laptopLanIp : _serverIp;
    final laptopParts = targetIp.split('.');

    if (phoneParts.length >= 3 && laptopParts.length >= 3) {
      return phoneParts[0] == laptopParts[0] &&
             phoneParts[1] == laptopParts[1] &&
             phoneParts[2] == laptopParts[2];
    }
    return isLanConnection;
  }

  /// Cho phép Wake-on-LAN khi:
  /// 1. Máy tính đang KHÔNG KẾT NỐI (Offline / Sleep / Shutdown)
  /// 2. KHÔNG TRONG CHU KỲ RESTART
  /// 3. Đã có địa chỉ MAC Address hợp lệ
  bool get isAllowWakeOnLan {
    if (_activePowerAction == "restart") return false;
    final macToUse = macAddress;
    if (macToUse.isEmpty || macToUse == "00:00:00:00:00:00") return false;
    
    // Nếu máy tính đang Online và kết nối bình thường ➔ KHÓA NÚT BẬT MÁY (WoL)!
    if (_isConnected && _activePowerAction == null) {
      return false;
    }

    return true;
  }

  /// Gửi gói tin Magic Packet Wake-on-LAN 3 đợt liên tiếp tới TẤT CẢ MAC phần cứng vật lý (Wi-Fi, Ethernet, LAN)
  Future<bool> sendWakeOnLan() async {
    try {
      var macRaw = macAddress;
      if (_status?.macAddress != null && _status!.macAddress.isNotEmpty) {
        macRaw = "${_status!.macAddress},$macRaw";
      }

      final macList = macRaw
          .split(',')
          .map((m) => m.trim())
          .where((m) => m.isNotEmpty && m != "00:00:00:00:00:00" && !m.startsWith("02:50"))
          .toSet();

      if (macList.isEmpty) {
        print("❌ WoL Error: No valid physical hardware MAC addresses found.");
        return false;
      }

      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final candidateIps = <String>{
        if (_phoneWifiIp != null && _phoneWifiIp!.isNotEmpty) _phoneWifiIp!,
        if (_laptopLanIp.isNotEmpty) _laptopLanIp,
        if (_serverIp.isNotEmpty) _serverIp,
      };

      bool sentAny = false;

      for (final targetMac in macList) {
        final cleanMac = targetMac.replaceAll(RegExp(r'[:\-]'), '');
        if (cleanMac.length != 12) continue;

        final macBytes = List<int>.generate(
          6,
          (i) => int.parse(cleanMac.substring(i * 2, i * 2 + 2), radix: 16),
        );

        final packet = List<int>.filled(6, 0xFF) + List<int>.generate(16 * 6, (i) => macBytes[i % 6]);

        // Gửi 3 đợt burst liên tiếp (cách nhau 100ms) để đảm bảo không bị rớt gói tin
        for (int burst = 0; burst < 3; burst++) {
          // 1. Global Broadcast 255.255.255.255
          socket.send(packet, InternetAddress('255.255.255.255'), 9);
          socket.send(packet, InternetAddress('255.255.255.255'), 7);

          // 2. Subnet Broadcasts (192.168.x.255)
          for (final rawIp in candidateIps) {
            if (rawIp.contains('.')) {
              final parts = rawIp.split('.');
              if (parts.length == 4 && (parts[0] == "192" || parts[0] == "10" || parts[0] == "172")) {
                final subnetBroadcast = "${parts[0]}.${parts[1]}.${parts[2]}.255";
                socket.send(packet, InternetAddress(subnetBroadcast), 9);
                socket.send(packet, InternetAddress(subnetBroadcast), 7);
                socket.send(packet, InternetAddress(subnetBroadcast), 9000);
              }
            }
          }
          await Future.delayed(const Duration(milliseconds: 100));
        }
        sentAny = true;
        print("⚡ Sent 3x WoL Magic Packet Bursts to Physical Hardware MAC $targetMac");
      }

      socket.close();
      return sentAny;
    } catch (e) {
      print("❌ WoL Send Error: $e");
      return false;
    }
  }

  Future<void> triggerPowerAction(String action) async {
    _activePowerAction = action;
    if (action == "shutdown" || action == "sleep") {
      _isConnected = false;
    }
    notifyListeners();

    final apiService = ApiService(
      baseIp: _serverIp,
      port: _serverPort,
      apiKey: _apiKey,
      deviceId: _deviceId,
      devicePassword: _devicePassword,
    );

    await apiService.sendControlCommand(action);

    if (action == "restart") {
      // Giữ khóa toàn bộ nút trong 10s khi đang Restart
      await Future.delayed(const Duration(seconds: 10));
    } else {
      await Future.delayed(const Duration(seconds: 1));
    }
    _activePowerAction = null;
    notifyListeners();
  }

  ControlProvider() {
    _loadSettings();
    _fetchPhoneWifiIp();
    _detectLocalDesktopNetwork();
  }

  /// Tự động phát hiện IP LAN nội bộ card mạng trên Laptop Desktop App
  Future<void> _detectLocalDesktopNetwork() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains("loopback") || name.contains("vethernet") || name.contains("vmware") || name.contains("vbox")) {
          continue;
        }
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && (addr.address.startsWith("192.168.") || addr.address.startsWith("10.") || addr.address.startsWith("172."))) {
            _laptopLanIp = addr.address;
            print("💻 Detected Local Desktop Host LAN IP: $_laptopLanIp");
            notifyListeners();
            break;
          }
        }
      }
    } catch (e) {
      print("Error detecting desktop network: $e");
    }
  }

  Future<void> _fetchPhoneWifiIp() async {
    try {
      final info = NetworkInfo();
      _phoneWifiIp = await info.getWifiIP();
      notifyListeners();
    } catch (e) {
      print("Error fetching phone wifi IP: $e");
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString('server_ip') ?? "18.143.90.229";
    _laptopLanIp = prefs.getString('laptop_lan_ip') ?? "";
    _serverPort = prefs.getInt('server_port') ?? 8002;
    _apiKey = prefs.getString('api_key') ?? "MyPrivateLaptopControlKey@2026";
    _deviceId = prefs.getString('device_id') ?? "default_device";
    _devicePassword = prefs.getString('device_password') ?? "";
    _macAddress = prefs.getString('mac_address') ?? "";
    _isConnected = prefs.getBool('is_connected') ?? false;
    _manuallyDisconnected = prefs.getBool('manually_disconnected') ?? false;

    // Desktop Host luôn reset manuallyDisconnected để sẵn sàng nhận kết nối mới
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _manuallyDisconnected = false;
      _isConnected = false;
      await prefs.setBool('manually_disconnected', false);
    }

    notifyListeners();
    startAutoRefresh();
  }

  Future<void> updateDevicePassword(String pass) async {
    _devicePassword = pass;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_password', pass);
    notifyListeners();
  }

  Future<void> updateConnectionSettings(
    String ip,
    int port,
    String key, [
    String? devId,
    String? pass,
    String? mac,
    String? lanIp,
  ]) async {
    await _fetchPhoneWifiIp();

    String finalTargetIp = ip;

    _serverIp = finalTargetIp;
    _serverPort = port;
    _apiKey = key;
    if (devId != null && devId.isNotEmpty) {
      _deviceId = devId;
    }
    if (pass != null) {
      _devicePassword = pass;
    }
    if (mac != null && mac.isNotEmpty) {
      _macAddress = mac;
    }

    // ƯU TIÊN LAN MODE HÀNG ĐẦU: Nếu có lanIp nội bộ ➔ Thử kết nối LAN IP trước!
    if (lanIp != null && lanIp.isNotEmpty) {
      _laptopLanIp = lanIp;
      
      final lanApiService = ApiService(
        baseIp: lanIp,
        port: port,
        apiKey: key,
        deviceId: _deviceId,
        devicePassword: _devicePassword,
      );
      
      final testLanStatus = await lanApiService.getStatus();
      if (testLanStatus != null) {
        finalTargetIp = lanIp;
        _serverIp = finalTargetIp;
        print("⚡ Successfully connected via LAN IP: $lanIp");
      } else {
        print("🌐 LAN IP ($lanIp) unreachable. Falling back to Remote Cloud IP: $ip");
      }
    }

    _isConnected = true;
    _manuallyDisconnected = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', _serverIp);
    await prefs.setString('laptop_lan_ip', _laptopLanIp);
    await prefs.setInt('server_port', _serverPort);
    await prefs.setString('api_key', _apiKey);
    await prefs.setString('device_id', _deviceId);
    await prefs.setString('device_password', _devicePassword);
    await prefs.setBool('is_connected', true);
    await prefs.setBool('manually_disconnected', false);
    if (mac != null) {
      await prefs.setString('mac_address', mac);
    }

    notifyListeners();

    // Bắn lệnh kích hoạt Pairing Session thời gian thực
    final apiService = ApiService(
      baseIp: _serverIp,
      port: _serverPort,
      apiKey: _apiKey,
      deviceId: _deviceId,
      devicePassword: _devicePassword,
    );
    await apiService.sendControlCommand("connect");
    refreshStatus();
  }

  void startAutoRefresh() {
    _timer?.cancel();
    refreshStatus();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => refreshStatus());
  }

  Future<void> refreshStatus() async {
    if (_manuallyDisconnected) return;

    SystemStatus? status;
    final bool isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (isDesktop) {
      // DESKTOP HOST: Luôn hỏi LOCAL SERVER 127.0.0.1:8002 trước tiên (tức thì, không timeout)
      final localApiService = ApiService(
        baseIp: "127.0.0.1",
        port: _serverPort,
        apiKey: _apiKey,
        deviceId: _deviceId,
        devicePassword: _devicePassword,
      );
      status = await localApiService.getStatus();
    } else {
      // MOBILE APP: Hỏi server đích (_serverIp) như bình thường
      final mainApiService = ApiService(
        baseIp: _serverIp,
        port: _serverPort,
        apiKey: _apiKey,
        deviceId: _deviceId,
        devicePassword: _devicePassword,
      );
      status = await mainApiService.getStatus();
    }

    if (status != null) {
      _status = status;
      
      // Tự động đồng bộ Device ID nếu từ server trả về deviceId mới hơn (ví dụ máy tính vừa khởi động lại)
      if (status.deviceId.isNotEmpty && status.deviceId != "default_device" && status.deviceId != "LAP-UNKNOWN") {
        if (_deviceId != status.deviceId) {
          _deviceId = status.deviceId;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('device_id', status.deviceId);
        }
      }

      if (_activePowerAction == "sleep" || _activePowerAction == "shutdown") {
        _isConnected = false;
      } else if (status.isPaired || status.connected) {
        _isConnected = true;
        _manuallyDisconnected = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_connected', true);
      } else {
        _isConnected = false;
      }

      if (status.macAddress.isNotEmpty && status.macAddress != "00:00:00:00:00:00") {
        _macAddress = status.macAddress;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mac_address', status.macAddress);
      }
    }
    notifyListeners();
  }



  Future<void> disconnect() async {
    final apiService = ApiService(
      baseIp: _serverIp,
      port: _serverPort,
      apiKey: _apiKey,
      deviceId: _deviceId,
      devicePassword: _devicePassword,
    );

    await apiService.disconnectSession();

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final localApiService = ApiService(
        baseIp: "127.0.0.1",
        port: _serverPort,
        apiKey: _apiKey,
        deviceId: _deviceId,
        devicePassword: _devicePassword,
      );
      await localApiService.disconnectSession();
    }

    _isConnected = false;
    _manuallyDisconnected = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_connected', false);
    await prefs.setBool('manually_disconnected', true);

    if (_status != null) {
      _status = SystemStatus(
        deviceId: _status!.deviceId,
        os: _status!.os,
        hostname: _status!.hostname,
        cpuUsagePercent: _status!.cpuUsagePercent,
        ramUsagePercent: _status!.ramUsagePercent,
        batteryPercent: _status!.batteryPercent,
        batteryPlugged: _status!.batteryPlugged,
        brightness: _status!.brightness,
        volume: _status!.volume,
        isMuted: _status!.isMuted,
        macAddress: _status!.macAddress,
        connected: false,
        isPaired: false,
        pairedMode: _status!.pairedMode,
      );
    }
    notifyListeners();
  }



  Future<void> changeBrightness(int value) async {
    if (_status != null) {
      _status = SystemStatus(
        deviceId: _status!.deviceId,
        os: _status!.os,
        hostname: _status!.hostname,
        cpuUsagePercent: _status!.cpuUsagePercent,
        ramUsagePercent: _status!.ramUsagePercent,
        batteryPercent: _status!.batteryPercent,
        batteryPlugged: _status!.batteryPlugged,
        brightness: value,
        volume: _status!.volume,
        isMuted: _status!.isMuted,
        macAddress: _status!.macAddress,
        connected: _status!.connected,
        isPaired: _status!.isPaired,
        pairedMode: _status!.pairedMode,
      );
      notifyListeners();
    }

    final apiService = ApiService(
      baseIp: _serverIp,
      port: _serverPort,
      apiKey: _apiKey,
      deviceId: _deviceId,
      devicePassword: _devicePassword,
    );

    await apiService.sendControlCommand("brightness", value);
  }

  Future<void> changeVolume(int value) async {
    if (_status != null) {
      _status = SystemStatus(
        deviceId: _status!.deviceId,
        os: _status!.os,
        hostname: _status!.hostname,
        cpuUsagePercent: _status!.cpuUsagePercent,
        ramUsagePercent: _status!.ramUsagePercent,
        batteryPercent: _status!.batteryPercent,
        batteryPlugged: _status!.batteryPlugged,
        brightness: _status!.brightness,
        volume: value,
        isMuted: _status!.isMuted,
        macAddress: _status!.macAddress,
        connected: _status!.connected,
        isPaired: _status!.isPaired,
        pairedMode: _status!.pairedMode,
      );
      notifyListeners();
    }

    final apiService = ApiService(
      baseIp: _serverIp,
      port: _serverPort,
      apiKey: _apiKey,
      deviceId: _deviceId,
      devicePassword: _devicePassword,
    );

    await apiService.sendControlCommand("volume", value);
  }

  Future<void> toggleMute() async {
    final isMutedNow = _status?.isMuted ?? false;
    if (_status != null) {
      _status = SystemStatus(
        deviceId: _status!.deviceId,
        os: _status!.os,
        hostname: _status!.hostname,
        cpuUsagePercent: _status!.cpuUsagePercent,
        ramUsagePercent: _status!.ramUsagePercent,
        batteryPercent: _status!.batteryPercent,
        batteryPlugged: _status!.batteryPlugged,
        brightness: _status!.brightness,
        volume: _status!.volume,
        isMuted: !isMutedNow,
        macAddress: _status!.macAddress,
        connected: _status!.connected,
        isPaired: _status!.isPaired,
        pairedMode: _status!.pairedMode,
      );
      notifyListeners();
    }

    final apiService = ApiService(
      baseIp: _serverIp,
      port: _serverPort,
      apiKey: _apiKey,
      deviceId: _deviceId,
      devicePassword: _devicePassword,
    );

    await apiService.sendControlCommand("mute");
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
