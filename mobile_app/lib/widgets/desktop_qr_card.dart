import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DesktopQrCard extends StatelessWidget {
  final String mode; // Tùy chọn giữ lại tương thích
  final String lanIp;
  final String remoteIp;
  final int serverPort;
  final String apiKey;
  final String deviceId;
  final String devicePassword;
  final String macAddress;

  const DesktopQrCard({
    super.key,
    this.mode = "Auto",
    required this.lanIp,
    required this.remoteIp,
    required this.serverPort,
    required this.apiKey,
    this.deviceId = "default_device",
    this.devicePassword = "",
    this.macAddress = "",
  });

  @override
  Widget build(BuildContext context) {
    // Mã QR Thông Minh Tự Động chứa đầy đủ thông số LAN IP & Remote Cloud IP
    final qrData = json.encode({
      "ip": remoteIp,
      "remote_ip": remoteIp,
      "lan_ip": lanIp,
      "port": serverPort,
      "key": apiKey,
      "device_id": deviceId,
      "password": devicePassword,
      "mac": macAddress,
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: Colors.cyanAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "Mã QR Ghép Nối Thông Minh",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Mở App PC Control trên điện thoại ➔ Quét mã QR để ghép nối tự động",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_rounded, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 4),
              Text(
                "LAN: ${lanIp.isNotEmpty ? lanIp : 'Auto'}",
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.public_rounded, color: Colors.amberAccent, size: 16),
              const SizedBox(width: 4),
              Text(
                "Remote: $remoteIp",
                style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (deviceId.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "ID: $deviceId ${devicePassword.isNotEmpty ? '• (Có Mật Khẩu 🔒)' : ''}",
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
