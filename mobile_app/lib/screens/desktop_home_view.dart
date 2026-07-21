import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/control_provider.dart';
import '../widgets/desktop_qr_card.dart';

class DesktopHomeView extends StatefulWidget {
  const DesktopHomeView({super.key});

  @override
  State<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends State<DesktopHomeView> {
  bool _forceShowQr = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _autoStartBackgroundAgent();
    // Refresh giao diện Desktop realtime mỗi 1 giây để đồng bộ tức thì với Điện thoại
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final provider = Provider.of<ControlProvider>(context, listen: false);
        provider.refreshStatus();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _autoStartBackgroundAgent() async {
    try {
      final exePath = Platform.resolvedExecutable;
      final appDir = Directory(exePath).parent.path;
      final backendDir = "$appDir\\backend";
      final vbsPath = "$backendDir\\start_agent_hidden.vbs";

      if (await File(vbsPath).exists()) {
        await Process.run("wscript.exe", [vbsPath], workingDirectory: backendDir);
        print("🟢 Auto-started Python Agent Client from: $vbsPath");
      } else {
        await Process.run("wscript.exe", ["start_agent_hidden.vbs"], workingDirectory: "backend");
      }
    } catch (e) {
      print("Error auto-starting agent: $e");
    }
  }

  void _showPasswordDialog(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context, listen: false);
    final passController = TextEditingController(text: provider.devicePassword);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text("Cài Đặt Mật Khẩu Kết Nối", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Đặt mật khẩu để chỉ điện thoại nhập đúng mật khẩu mới được phép kết nối và điều khiển máy tính này.",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Mật khẩu kết nối máy tính",
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.amberAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newPass = passController.text.trim();
              provider.updateDevicePassword(newPass);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF10B981),
                  content: Text("🔑 Đã lưu mật khẩu kết nối máy tính thành công!"),
                ),
              );
            },
            child: const Text("Lưu Mật Khẩu", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // slate-950
      body: SafeArea(
        child: Consumer<ControlProvider>(
          builder: (context, provider, child) {
            final isConnected = provider.isConnected;
            final activeMode = provider.status?.pairedMode ?? (provider.isLanConnection ? "LAN" : "Remote");

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header Logo & Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.laptop_mac_rounded, color: Colors.cyanAccent, size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PC Control",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "Desktop Companion Host",
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Trạng thái Kết nối Badge & Nút Cài Đặt Mật Khẩu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFFF43F5E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isConnected ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isConnected ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isConnected
                                      ? "ĐÃ KẾT NỐI • $activeMode Mode"
                                      : "CHƯA KẾT NỐI",
                                  style: TextStyle(
                                    color: isConnected ? const Color(0xFF10B981) : const Color(0xFFFDA4AF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () => _showPasswordDialog(context),
                            icon: Icon(
                              provider.devicePassword.isNotEmpty ? Icons.lock : Icons.lock_open,
                              color: provider.devicePassword.isNotEmpty ? Colors.amberAccent : const Color(0xFF94A3B8),
                            ),
                            tooltip: "Cài Đặt Mật Khẩu Máy Tính",
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Nút Tùy chọn Ngắt kết nối / Ẩn Mã QR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isConnected) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                                side: const BorderSide(color: Color(0xFFF43F5E)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () => provider.disconnect(),
                              icon: const Icon(Icons.power_settings_new, color: Color(0xFFF43F5E), size: 18),
                              label: const Text(
                                "Ngắt Kết Nối Thập Thể",
                                style: TextStyle(color: Color(0xFFFDA4AF), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _forceShowQr = !_forceShowQr;
                              });
                            },
                            icon: Icon(
                              _forceShowQr ? Icons.visibility_off : Icons.qr_code_2_rounded,
                              color: Colors.cyanAccent,
                              size: 20,
                            ),
                            label: Text(
                              _forceShowQr ? "Ẩn Mã QR" : "Hiển Thị Mã QR Ghép Nối",
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // KHU VỰC THÔNG TIN VÀ MÃ QR CODE HỢP NHẤT DÙNG CHUNG
                      if (!isConnected || _forceShowQr) ...[
                        DesktopQrCard(
                          mode: "Auto",
                          lanIp: provider.lanIp,
                          remoteIp: provider.serverIp,
                          serverPort: provider.serverPort,
                          apiKey: provider.apiKey,
                          deviceId: provider.deviceId,
                          devicePassword: provider.devicePassword,
                          macAddress: provider.macAddress,
                        ),
                      ] else ...[
                        // GIAO DIỆN KHI ĐÃ KẾT NỐI TÍCH CỰC
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.phonelink_ring_rounded, color: Color(0xFF10B981), size: 40),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Đã Ghép Nối Với Điện Thoại",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Chế độ: $activeMode • Sẵn sàng nhận lệnh điều khiển",
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "🔒 Mã QR Code đã được ẩn để bảo vệ quyền điều khiển độc quyền.",
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                                  side: const BorderSide(color: Color(0xFFF43F5E)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => provider.disconnect(),
                                icon: const Icon(Icons.power_settings_new, color: Color(0xFFF43F5E), size: 16),
                                label: const Text(
                                  "Ngắt Kết Nối Session",
                                  style: TextStyle(color: Color(0xFFFDA4AF), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // THÔNG SỐ TẢI TRỰC TIẾP TRÊN LAPTOP HOST
                              Row(
                                children: [
                                  _buildStatItem("CPU", "${provider.status?.cpuUsagePercent.round() ?? 0}%", Colors.cyanAccent),
                                  _buildStatItem("RAM", "${provider.status?.ramUsagePercent.round() ?? 0}%", Colors.amberAccent),
                                  _buildStatItem("PIN", "${provider.status?.batteryPercent ?? 100}%", const Color(0xFF10B981)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
