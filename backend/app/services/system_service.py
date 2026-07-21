import platform
import os
import subprocess
import psutil
import screen_brightness_control as sbc
from typing import Dict, Any

CURRENT_OS = platform.system()

class SystemService:
    @staticmethod
    def _get_win_volume_endpoint():
        """Khởi tạo Windows Core Audio COM Endpoint trực tiếp."""
        from comtypes import GUID, client, CLSCTX_ALL
        from ctypes import POINTER, cast
        from pycaw.pycaw import IAudioEndpointVolume, IMMDeviceEnumerator

        CLSID_MMDeviceEnumerator = GUID('{BCDE0380-1D51-4685-8754-21A531E5B836}')
        IID_IMMDeviceEnumerator = GUID('{A95664D2-9614-4F35-A746-DE8DB63617E6}')
        IID_IAudioEndpointVolume = GUID('{5CDF2C82-841E-4546-9722-0CF74078229A}')

        enumerator = client.CreateObject(CLSID_MMDeviceEnumerator, interface=IMMDeviceEnumerator)
        device = enumerator.GetDefaultAudioEndpoint(0, 1)
        endpoint = device.Activate(IID_IAudioEndpointVolume, CLSCTX_ALL, None)
        return cast(endpoint, POINTER(IAudioEndpointVolume))

    @staticmethod
    def get_system_status() -> Dict[str, Any]:
        """Lấy thông số tải CPU, RAM, Pin, Âm lượng và trạng thái Mute hiện tại."""
        cpu_usage = psutil.cpu_percent(interval=0.5)
        ram_usage = psutil.virtual_memory().percent
        
        battery = psutil.sensors_battery()
        battery_data = {
            "percent": battery.percent if battery else 100,
            "power_plugged": battery.power_plugged if battery else True
        }

        try:
            brightness_val = sbc.get_brightness()
            current_brightness = brightness_val[0] if isinstance(brightness_val, list) else brightness_val
        except Exception:
            current_brightness = 100

        is_muted = SystemService.get_is_muted()

        return {
            "os": CURRENT_OS,
            "hostname": platform.node(),
            "cpu_usage_percent": cpu_usage,
            "ram_usage_percent": ram_usage,
            "battery": battery_data,
            "brightness": current_brightness,
            "volume": SystemService.get_volume(),
            "is_muted": is_muted
        }

    @staticmethod
    def get_is_muted() -> bool:
        """Kiểm tra máy tính có đang ở trạng thái Tắt Tiếng (Mute) hay không."""
        if CURRENT_OS == 'Windows':
            try:
                endpoint = SystemService._get_win_volume_endpoint()
                return bool(endpoint.GetMute())
            except Exception:
                return False
        return False

    @staticmethod
    def toggle_mute() -> bool:
        """Đảo trạng thái Tắt Tiếng (Mute -> Unmute và ngược lại)."""
        if CURRENT_OS == 'Windows':
            try:
                endpoint = SystemService._get_win_volume_endpoint()
                current_mute = endpoint.GetMute()
                endpoint.SetMute(0 if current_mute else 1, None)
                return True
            except Exception as e:
                print(f"Error toggling mute: {e}")
                return False
        return False

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
        """Lấy mức âm lượng hiện tại thực tế trên máy tính (0-100%)."""
        if CURRENT_OS == 'Windows':
            try:
                endpoint = SystemService._get_win_volume_endpoint()
                return int(round(endpoint.GetMasterVolumeLevelScalar() * 100))
            except Exception as e:
                print(f"Windows Get Volume error: {e}")
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
        """Đặt âm lượng hệ thống thực tế (0-100%)."""
        level = max(0, min(100, level))
        if CURRENT_OS == 'Windows':
            try:
                endpoint = SystemService._get_win_volume_endpoint()
                if level > 0 and endpoint.GetMute():
                    endpoint.SetMute(0, None)
                elif level == 0:
                    endpoint.SetMute(1, None)
                
                endpoint.SetMasterVolumeLevelScalar(level / 100.0, None)
                return True
            except Exception as e:
                print(f"Windows Set Volume error: {e}")
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
        return False
