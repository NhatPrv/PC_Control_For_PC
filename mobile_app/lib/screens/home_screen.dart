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
                      // BANNER THÔNG BÁO KHÓA CHỨC NĂNG KHI CHƯA KẾT NỐI HOẶC RESTARTING
                      if (!isConnected || isRestarting) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: (isRestarting ? Colors.orangeAccent : const Color(0xFFF43F5E)).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: (isRestarting ? Colors.orangeAccent : const Color(0xFFF43F5E)).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(isRestarting ? Icons.restart_alt : Icons.lock_rounded, color: isRestarting ? Colors.amberAccent : const Color(0xFFFDA4AF), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isRestarting
                                      ? "Máy tính đang khởi động lại (Restarting)... Đã tạm khóa toàn bộ chức năng."
                                      : "Đã khóa các chức năng điều khiển. Quét mã QR để kết nối hoặc bấm Bật Máy (WoL).",
                                  style: TextStyle(
                                    color: isRestarting ? Colors.amberAccent : const Color(0xFFFDA4AF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}
