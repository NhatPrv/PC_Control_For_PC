import 'dart:convert';
import 'package:http/http.dart' as http;

class SystemStatus {
  final String deviceId;
  final String os;
  final String hostname;
  final double cpuUsagePercent;
  final double ramUsagePercent;
  final int batteryPercent;
  final bool batteryPlugged;
  final int brightness;
  final int volume;
  final bool isMuted;
  final String macAddress;
  final bool connected;
  final bool isPaired;
  final String pairedMode;

  SystemStatus({
    required this.deviceId,
    required this.os,
    required this.hostname,
    required this.cpuUsagePercent,
    required this.ramUsagePercent,
    required this.batteryPercent,
    required this.batteryPlugged,
    required this.brightness,
    required this.volume,
    this.isMuted = false,
    this.macAddress = "",
    this.connected = true,
    this.isPaired = false,
    this.pairedMode = "Remote",
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    final batteryMap = json['battery'] as Map<String, dynamic>? ?? {};
    final isConn = json['connected'] == true || json['is_paired'] == true;
    final isP = json['is_paired'] == true || json['connected'] == true;

    return SystemStatus(
      deviceId: json['device_id'] ?? 'default_device',
      os: json['os'] ?? 'Unknown OS',
      hostname: json['hostname'] ?? 'Unknown Host',
      cpuUsagePercent: (json['cpu_usage_percent'] as num?)?.toDouble() ?? 0.0,
      ramUsagePercent: (json['ram_usage_percent'] as num?)?.toDouble() ?? 0.0,
      batteryPercent: (batteryMap['percent'] as num?)?.toInt() ?? 100,
      batteryPlugged: batteryMap['power_plugged'] as bool? ?? true,
      brightness: (json['brightness'] as num?)?.toInt() ?? 70,
      volume: (json['volume'] as num?)?.toInt() ?? 50,
      isMuted: json['is_muted'] == true,
      macAddress: json['mac_address'] ?? "",
      connected: isConn,
      isPaired: isP,
      pairedMode: json['paired_mode'] ?? 'Remote',
    );
  }
}

class ApiService {
  final String baseIp;
  final int port;
  final String apiKey;
  final String deviceId;
  final String devicePassword;

  ApiService({
    required this.baseIp,
    required this.port,
    required this.apiKey,
    this.deviceId = "default_device",
    this.devicePassword = "",
  });

  String get baseUrl => "http://$baseIp:$port";

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey.isNotEmpty) {
      headers['x-api-key'] = apiKey;
    }
    if (devicePassword.isNotEmpty) {
      headers['x-device-password'] = devicePassword;
    }
    return headers;
  }

  Future<SystemStatus?> getStatus() async {
    try {
      final uri = Uri.parse("$baseUrl/api/status?device_id=$deviceId");
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SystemStatus.fromJson(data);
      }
    } catch (e) {
      // Return null on failure
    }
    return null;
  }

  Future<bool> sendControlCommand(String action, [dynamic value, String mode = "Remote"]) async {
    try {
      final body = json.encode({
        'device_id': deviceId,
        'action': action,
        'mode': mode,
        if (value != null) 'value': value,
      });

      final response = await http
          .post(
            Uri.parse("$baseUrl/api/control"),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disconnectSession() async {
    try {
      final body = json.encode({
        'device_id': deviceId,
      });

      final response = await http
          .post(
            Uri.parse("$baseUrl/api/disconnect"),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
