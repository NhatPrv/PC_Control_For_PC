import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/control_provider.dart';

class VolumeControlCard extends StatelessWidget {
  const VolumeControlCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlProvider>(
      builder: (context, provider, child) {
        final currentVolume = provider.status?.volume ?? 50;
        final isMuted = provider.status?.isMuted ?? false;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMuted
                              ? const Color(0xFFF43F5E).withValues(alpha: 0.15)
                              : Colors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: isMuted ? const Color(0xFFF43F5E) : Colors.cyanAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Master Volume",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isMuted ? "🔇 Tắt Tiếng (Muted)" : "🔊 Bật Tiếng (Active)",
                            style: TextStyle(
                              color: isMuted ? const Color(0xFFF43F5E) : const Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // NÚT BẬT / TẮT TIẾNG MUTE/UNMUTE TRỰC QUAN
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isMuted
                              ? const Color(0xFFF43F5E).withValues(alpha: 0.2)
                              : const Color(0xFF334155),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => provider.toggleMute(),
                        icon: Icon(
                          isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: isMuted ? const Color(0xFFF43F5E) : Colors.cyanAccent,
                          size: 20,
                        ),
                        tooltip: isMuted ? "Bật Tiếng (Unmute)" : "Tắt Tiếng (Mute)",
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isMuted ? "0%" : "$currentVolume%",
                        style: TextStyle(
                          color: isMuted ? const Color(0xFFF43F5E) : Colors.cyanAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: isMuted ? const Color(0xFFF43F5E) : Colors.cyanAccent,
                  inactiveTrackColor: const Color(0xFF1E293B),
                  thumbColor: isMuted ? const Color(0xFFF43F5E) : Colors.cyanAccent,
                  overlayColor: isMuted
                      ? const Color(0xFFF43F5E).withValues(alpha: 0.2)
                      : Colors.cyanAccent.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: isMuted ? 0.0 : currentVolume.toDouble(),
                  min: 0.0,
                  max: 100.0,
                  onChanged: (val) {
                    provider.changeVolume(val.round());
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
