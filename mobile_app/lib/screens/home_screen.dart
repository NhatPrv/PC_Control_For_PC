import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/control_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/device_monitor_card.dart';
import '../widgets/power_action_button.dart';
import '../widgets/control_slider.dart';
import '../widgets/volume_control_card.dart';
import 'desktop_home_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  void _confirmPowerAction(BuildContext context, ControlProvider provider, String action, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.power_settings_new_rounded, color: Color(0xFFF43F5E)),
            const SizedBox(width: 10),
            Text("Xác Nhận $title", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text("Bạn có chắc chắn muốn thực hiện lệnh $title trên máy tính?", style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.triggerPowerAction(action);
            },
            child: const Text("Xác Nhận", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return const DesktopHomeView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // slate-950
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardHeader(),
              const SizedBox(height: 20),

              Consumer<ControlProvider>(
                builder: (context, provider, child) {
                  final isConnected = provider.isConnected;
                  final status = provider.status;
                  final isRestarting = provider.activePowerAction == "restart";
                  final allowWol = provider.isAllowWakeOnLan && !isRestarting;
                  final allowControls = isConnected && !isRestarting;

                  return Column(
                    children: [
                      // BANNER THÔNG BÁO KHÓA CHỨC NĂNG VÀ TRẠNG THÁI
                      if (!isConnected || isRestarting || provider.isSleepingState || provider.isShutdownState) ...[
                        Builder(
                          builder: (context) {
                            Color bannerColor = const Color(0xFFF43F5E); // Mặc định Đỏ (Disconnected)
                            IconData bannerIcon = Icons.power_off_rounded;
                            String bannerMsg = "Đã ngắt kết nối với máy tính (Disconnected). Không thể tương tác điều khiển ngoại trừ Bật Máy (WoL).";

                            if (isRestarting) {
                              bannerColor = Colors.orangeAccent;
                              bannerIcon = Icons.restart_alt;
                              bannerMsg = "Máy tính đang khởi động lại (Restarting)... Đã tạm khóa toàn bộ chức năng.";
                            } else if (provider.isSleepingState || provider.isShutdownState) {
                              bannerColor = Colors.amber; // Màu Vàng
                              bannerIcon = provider.isSleepingState ? Icons.bedtime_rounded : Icons.power_settings_new_rounded;
                              bannerMsg = "Máy tính ở trạng thái ${provider.displayStatusText} (Màu Vàng). Đã làm mờ các tính năng điều khiển. Bấm Bật Máy (WoL) để kích hoạt.";
                            }

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: bannerColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: bannerColor.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  Icon(bannerIcon, color: bannerColor, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      bannerMsg,
                                      style: TextStyle(
                                        color: bannerColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      // THÔNG SỐ TẢI HỆ THỐNG (CPU, RAM, PIN) - KHÓA KHI CHƯA KẾT NỐI HOẶC RESTARTING
                      Opacity(
                        opacity: allowControls ? 1.0 : 0.45,
                        child: IgnorePointer(
                          ignoring: !allowControls,
                          child: Row(
                            children: [
                              Expanded(
                                child: DeviceMonitorCard(
                                  title: "CPU",
                                  value: "${status?.cpuUsagePercent.round() ?? 0}",
                                  unit: "%",
                                  icon: Icons.memory,
                                  accentColor: Colors.cyanAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DeviceMonitorCard(
                                  title: "RAM",
                                  value: "${status?.ramUsagePercent.round() ?? 0}",
                                  unit: "%",
                                  icon: Icons.pie_chart,
                                  accentColor: Colors.amberAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DeviceMonitorCard(
                                  title: "PIN",
                                  value: "${status?.batteryPercent ?? 100}",
                                  unit: "%",
                                  icon: Icons.battery_charging_full,
                                  accentColor: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // THANH ĐỘ SÁNG MÀN HÌNH - KHÓA KHI CHƯA KẾT NỐI HOẶC RESTARTING
                      Opacity(
                        opacity: allowControls ? 1.0 : 0.45,
                        child: IgnorePointer(
                          ignoring: !allowControls,
                          child: ControlSlider(
                            label: "Độ Sáng Màn Hình",
                            value: status?.brightness ?? 70,
                            icon: Icons.brightness_6,
                            activeColor: Colors.amberAccent,
                            onChanged: (val) => provider.changeBrightness(val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // THANH MASTER VOLUME - KHÓA KHI CHƯA KẾT NỐI HOẶC RESTARTING
                      Opacity(
                        opacity: allowControls ? 1.0 : 0.45,
                        child: IgnorePointer(
                          ignoring: !allowControls,
                          child: const VolumeControlCard(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // DẢI 4 NÚT CHỨC NĂNG Ở DƯỚI CÙNG (TẮT MÁY, RESTART, SLEEP, WAKE-ON-LAN)
                      Row(
                        children: [
                          // 3 NÚT NGUỒN KHÓA KHI CHƯA KẾT NỐI HOẶC RESTARTING
                          Expanded(
                            child: Opacity(
                              opacity: allowControls ? 1.0 : 0.45,
                              child: IgnorePointer(
                                ignoring: !allowControls,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: PowerActionButton(
                                        label: "Tắt Máy",
                                        icon: Icons.power_settings_new,
                                        accentColor: const Color(0xFFF43F5E),
                                        onClick: () => _confirmPowerAction(context, provider, "shutdown", "Tắt Máy"),
                                        isLoading: provider.activePowerAction == "shutdown",
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: PowerActionButton(
                                        label: "Restart",
                                        icon: Icons.restart_alt,
                                        accentColor: Colors.orangeAccent,
                                        onClick: () => _confirmPowerAction(context, provider, "restart", "Khởi Động Lại"),
                                        isLoading: provider.activePowerAction == "restart",
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: PowerActionButton(
                                        label: "Sleep",
                                        icon: Icons.bedtime,
                                        accentColor: Colors.indigoAccent,
                                        onClick: () => _confirmPowerAction(context, provider, "sleep", "Ngủ Đông"),
                                        isLoading: provider.activePowerAction == "sleep",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          const SizedBox(width: 8),

                          // NÚT WAKE-ON-LAN (MỞ KHI SLEEP/SHUTDOWN/CHƯA KẾT NỐI, KHÓA KHI RESTARTING)
                          Expanded(
                            child: Opacity(
                              opacity: allowWol ? 1.0 : 0.45,
                              child: IgnorePointer(
                                ignoring: !allowWol,
                                child: PowerActionButton(
                                  label: "Bật Máy",
                                  icon: Icons.bolt_rounded,
                                  accentColor: Colors.amberAccent,
                                  onClick: () async {
                                    final success = await provider.sendWakeOnLan();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                          content: Text(
                                            success
                                                ? "⚡ Đã gửi gói Magic Packet bật máy tới MAC: ${provider.macAddress}"
                                                : "❌ Chưa tìm thấy MAC Address để phát Wake-on-LAN.",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // NÚT 🔓 MỞ KHÓA PC (GỬI PIN / MẬT KHẨU ĐĂNG NHẬP WINDOWS)
                          Expanded(
                            child: Opacity(
                              opacity: allowControls ? 1.0 : 0.45,
                              child: IgnorePointer(
                                ignoring: !allowControls,
                                child: PowerActionButton(
                                  label: "Mở Khóa",
                                  icon: Icons.lock_open_rounded,
                                  accentColor: Colors.cyanAccent,
                                  onClick: () => _showUnlockDialog(context, provider),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, ControlProvider provider) {
    final pinController = TextEditingController(text: provider.windowsPin);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_open_rounded, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text("🔓 Mở Khóa Windows", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nhập mã PIN hoặc Mật khẩu đăng nhập Windows của bạn để tự động gõ mở khóa:",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "PIN / Mật khẩu Windows",
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.key_rounded, color: Colors.cyanAccent),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.cyanAccent),
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
              final pin = pinController.text.trim();
              if (pin.isNotEmpty) {
                await provider.updateWindowsPin(pin);
                final success = await provider.unlockWindows(pin);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      content: Text(
                        success
                            ? "🔓 Đã gửi lệnh tự động mở khóa PIN/Mật khẩu tới Windows!"
                            : "❌ Lỗi khi gửi lệnh mở khóa.",
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text("Gửi Mở Khóa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
