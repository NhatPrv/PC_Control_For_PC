import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/control_provider.dart';
import 'qr_scanner_dialog.dart';
import 'desktop_qr_card.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  void _openQrScanner(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerDialog()),
    );

    if (result != null && context.mounted) {
      final String ip = result['ip'] ?? '';
      final String remoteIp = result['remote_ip'] ?? ip;
      final String lanIp = result['lan_ip'] ?? '';
      final int port = result['port'] ?? 8002;
      final String key = result['key'] ?? '';
      final String devId = result['device_id'] ?? 'default_device';
      final String targetPassword = result['password'] ?? '';
      final String mac = result['mac'] ?? '';

      if (ip.isNotEmpty) {
        if (targetPassword.isNotEmpty) {
          _showPasswordChallengeDialog(context, remoteIp, port, key, devId, targetPassword, mac, lanIp);
        } else {
          final provider = Provider.of<ControlProvider>(context, listen: false);
          await provider.updateConnectionSettings(remoteIp, port, key, devId, "", mac, lanIp);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              content: Text("🎉 Đã ghép nối thành công với $devId (${provider.isLanConnection ? 'LAN' : 'Remote'})"),
            ),
          );
        }
      }
    }
  }

  void _showPasswordChallengeDialog(
    BuildContext context,
    String ip,
    int port,
    String key,
    String devId,
    String targetPassword,
    String mac, [
    String lanIp = "",
  ]) {
    final inputPassController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text("Xác Thực Mật Khẩu PC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Máy tính [$devId] đã cài đặt mật khẩu kết nối. Vui lòng nhập mật khẩu:", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: inputPassController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Mật khẩu máy tính",
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.cyan),
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
              backgroundColor: Colors.cyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final enteredPass = inputPassController.text.trim();
              if (enteredPass == targetPassword) {
                Navigator.pop(ctx);
                final provider = Provider.of<ControlProvider>(context, listen: false);
                await provider.updateConnectionSettings(ip, port, key, devId, enteredPass, mac, lanIp);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text("🎉 Xác thực mật khẩu đúng! Đã kết nối tới $devId"),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFFF43F5E),
                    content: Text("❌ Mật khẩu máy tính không chính xác. Vui lòng thử lại!"),
                  ),
                );
              }
            },
            child: const Text("Xác Nhận", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDesktopQrDialog(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(16),
        content: DesktopQrCard(
          mode: "Remote",
          lanIp: provider.lanIp,
          remoteIp: provider.serverIp,
          serverPort: provider.serverPort,
          apiKey: provider.apiKey,
          deviceId: provider.deviceId,
          devicePassword: provider.devicePassword,
          macAddress: provider.macAddress,
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final provider = Provider.of<ControlProvider>(context, listen: false);
    final ipController = TextEditingController(text: provider.serverIp);
    final portController = TextEditingController(text: provider.serverPort.toString());
    final keyController = TextEditingController(text: provider.apiKey);
    final passController = TextEditingController(text: provider.devicePassword);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cấu hình Kết nối", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.isLanConnection ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final targetLan = provider.laptopLanIp.isNotEmpty ? provider.laptopLanIp : "192.168.100.155";
                      provider.updateConnectionSettings(targetLan, provider.serverPort, provider.apiKey);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text("⚡ Đã chuyển sang LAN Mode ($targetLan)"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
                    label: const Text("LAN Mode", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !provider.isLanConnection ? Colors.cyan : const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      provider.updateConnectionSettings("18.143.90.229", provider.serverPort, provider.apiKey);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.cyan,
                          content: Text("🌐 Đã chuyển sang Remote AWS Cloud (18.143.90.229)"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.public_rounded, color: Colors.white, size: 16),
                    label: const Text("Remote Mode", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Địa chỉ IP Host / AWS",
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.cyan),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Cổng Port (Mặc định: 8002)",
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.cyan),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Mật Khẩu Máy Tính (Device Password)",
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
              backgroundColor: Colors.cyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final ip = ipController.text.trim();
              final port = int.tryParse(portController.text.trim()) ?? 8002;
              final key = keyController.text.trim();
              final pass = passController.text.trim();
              provider.updateConnectionSettings(ip, port, key, null, pass);
              Navigator.pop(ctx);
            },
            child: const Text("Lưu Kết Nối", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlProvider>(
      builder: (context, provider, child) {
        Color statusColor = const Color(0xFFF43F5E); // Mặc định Đỏ (Disconnected)
        if (provider.isSleepingState || provider.isShutdownState) {
          statusColor = Colors.amber; // Màu Vàng cho Sleeping & Shutting down
        } else if (provider.activePowerAction == "restart") {
          statusColor = Colors.orangeAccent;
        } else if (provider.isConnected) {
          statusColor = const Color(0xFF10B981); // Màu Xanh cho Online
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.status?.hostname.isNotEmpty == true
                          ? provider.status!.hostname
                          : (provider.deviceId.isNotEmpty ? provider.deviceId : "My Windows PC"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            provider.displayStatusText,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.isConnected)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => provider.disconnect(),
                      icon: const Icon(Icons.power_off_rounded, color: Color(0xFFF43F5E), size: 20),
                      tooltip: "Ngắt Kết Nối Session",
                    ),
                  if (_isDesktop)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () => _showDesktopQrDialog(context),
                      icon: const Icon(Icons.qr_code_2_rounded, color: Colors.cyanAccent, size: 22),
                      tooltip: "Hiển thị Mã QR Kết Nối",
                    ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => _openQrScanner(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF10B981), size: 22),
                    tooltip: "Quét Mã QR bằng Camera",
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => _showSettingsDialog(context),
                    icon: const Icon(Icons.settings, color: Color(0xFF94A3B8), size: 20),
                    tooltip: "Cấu hình IP & Mật khẩu",
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
