import platform
import os
import subprocess
import psutil
import screen_brightness_control as sbc
from typing import Dict, Any

CURRENT_OS = platform.system()

class SystemService:
    @staticmethod
    def get_system_status() -> Dict[str, Any]:
        """Lấy thông số tải CPU, RAM, Pin và trạng thái hiện tại của thiết bị."""
        cpu_usage = psutil.cpu_percent(interval=0.5)
        ram_usage = psutil.virtual_memory().percent
        
        # Battery info
        battery = psutil.sensors_battery()
        battery_data = {
            "percent": battery.percent if battery else 100,
            "power_plugged": battery.power_plugged if battery else True
        }

        # Brightness info
        try:
            brightness_val = sbc.get_brightness()
            current_brightness = brightness_val[0] if isinstance(brightness_val, list) else brightness_val
        except Exception:
            current_brightness = 100

        return {
            "os": CURRENT_OS,
            "hostname": platform.node(),
            "cpu_usage_percent": cpu_usage,
            "ram_usage_percent": ram_usage,
            "battery": battery_data,
            "brightness": current_brightness,
            "volume": SystemService.get_volume()
        }

    @staticmethod
    def set_brightness(level: int) -> bool:
        """Đổi độ sáng màn hình (0-100%)."""
        try:
            level = max(0, min(100, level))
            sbc.set_brightness(level)
            return True
        except Exception as e:
            print(f"Error setting brightness: {e}")
            return False

    @staticmethod
    def get_volume() -> int:
        """Lấy mức âm lượng hiện tại (0-100%)."""
        if CURRENT_OS == 'Windows':
            try:
                from ctypes import cast, POINTER
                from comtypes import CLSCTX_ALL
                from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
                devices = AudioUtilities.GetSpeakers()
                interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
                volume_obj = cast(interface, POINTER(IAudioEndpointVolume))
                return int(volume_obj.GetMasterVolumeLevelScalar() * 100)
            except Exception:
                return 50
        elif CURRENT_OS == 'Linux':
            try:
                out = subprocess.check_output(["amixer", "-D", "pulse", "sget", "Master"]).decode('utf-8')
                import re
                m = re.search(r"\[(\d+)%\]", out)
                if m:
                    return int(m.group(1))
            except Exception:
                pass
            return 50
        return 50

    @staticmethod
    def set_volume(level: int) -> bool:
        """Đặt âm lượng hệ thống (0-100%)."""
        level = max(0, min(100, level))
        if CURRENT_OS == 'Windows':
            try:
                from ctypes import cast, POINTER
                from comtypes import CLSCTX_ALL
                from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
                devices = AudioUtilities.GetSpeakers()
                interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
                volume_obj = cast(interface, POINTER(IAudioEndpointVolume))
                volume_obj.SetMasterVolumeLevelScalar(level / 100.0, None)
                return True
            except Exception as e:
                print(f"Windows Volume error: {e}")
                return False
        elif CURRENT_OS == 'Linux':
            try:
                subprocess.run(["amixer", "-q", "-D", "pulse", "sset", "Master", f"{level}%"], check=True)
                return True
            except Exception:
                try:
                    subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{level}%"], check=True)
                    return True
                except Exception as e:
                    print(f"Linux Volume error: {e}")
                    return False
        return False

    @staticmethod
    def execute_power_action(action: str) -> bool:
        """Thực hiện thao tác nguồn: shutdown, restart, sleep."""
        action = action.lower()
        if CURRENT_OS == 'Windows':
            if action == 'shutdown':
                os.system("shutdown /s /t 2")
            elif action == 'restart':
                os.system("shutdown /r /t 2")
            elif action == 'sleep':
                os.system("rundll32.exe powrprof.dll,SetSuspendState 0,1,0")
            else:
                return False
            return True
        elif CURRENT_OS == 'Linux':
            if action == 'shutdown':
                subprocess.run(["systemctl", "poweroff"])
            elif action == 'restart':
                subprocess.run(["systemctl", "reboot"])
            elif action == 'sleep':
                subprocess.run(["systemctl", "suspend"])
            else:
                return False
            return True
        return False
