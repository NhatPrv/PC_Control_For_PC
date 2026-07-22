import platform
import os
import subprocess
import psutil
import screen_brightness_control as sbc
from typing import Dict, Any

CURRENT_OS = platform.system()

class SystemService:
    @staticmethod
    def _init_win_com():
        """Khởi tạo Windows COM Threading Apartment trước khi gọi dịch vụ âm thanh."""
        if CURRENT_OS == 'Windows':
            try:
                import comtypes
                comtypes.CoInitialize()
            except Exception:
                pass
            try:
                import pythoncom
                pythoncom.CoInitialize()
            except Exception:
                pass

    @staticmethod
    def _get_win_volume_endpoint():
        """Khởi tạo Windows Core Audio COM Endpoint qua Pycaw AudioUtilities (Thread-safe 100%)."""
        SystemService._init_win_com()
        try:
            from pycaw.pycaw import AudioUtilities
            speakers = AudioUtilities.GetSpeakers()
            if speakers:
                return speakers.EndpointVolume
        except Exception as e:
            print(f"Pycaw Endpoint Error: {e}")
        return None

    @staticmethod
    def get_mac_address() -> str:
        """Lấy địa chỉ MAC Address card mạng phần cứng thực tế (Wi-Fi/Ethernet) để phục vụ Wake-on-LAN."""
        try:
            addrs_map = psutil.net_if_addrs()
            
            # Ưu tiên 1: Card mạng Wi-Fi hoặc Ethernet vật lý thật
            for iface, addrs in addrs_map.items():
                name_lower = iface.lower()
                if any(v in name_lower for v in ["wi-fi", "wifi", "ethernet"]) and not any(v in name_lower for v in ["radmin", "vpn", "virtual", "vbox", "vethernet", "vmware", "teredo", "pseudo"]):
                    for addr in addrs:
                        if addr.family == psutil.AF_LINK and addr.address:
                            mac = addr.address.replace("-", ":").upper()
                            if mac != "00:00:00:00:00:00" and not mac.startswith("02:50"):
                                return mac

            # Ưu tiên 2: Bất kỳ card nào không phải virtual/vpn/radmin
            for iface, addrs in addrs_map.items():
                name_lower = iface.lower()
                if not any(v in name_lower for v in ["loopback", "vethernet", "vmware", "radmin", "vpn", "vbox", "teredo", "pseudo"]):
                    for addr in addrs:
                        if addr.family == psutil.AF_LINK and addr.address:
                            mac = addr.address.replace("-", ":").upper()
                            if mac != "00:00:00:00:00:00" and not mac.startswith("02:50"):
                                return mac

            return "00:00:00:00:00:00"
        except Exception:
            return "00:00:00:00:00:00"

    @staticmethod
    def get_lan_ip() -> str:
        """Lấy địa chỉ IP Wi-Fi/LAN nội bộ thật của Máy tính."""
        try:
            import socket
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return "127.0.0.1"

    @staticmethod
    def get_system_status() -> Dict[str, Any]:
        """Lấy thông số tải CPU, RAM, Pin, Âm lượng, Trạng thái Mute và địa chỉ MAC Address."""
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
            "is_muted": is_muted,
            "mac_address": SystemService.get_mac_address(),
            "lan_ip": SystemService.get_lan_ip()
        }

    @staticmethod
    def get_is_muted() -> bool:
        """Kiểm tra máy tính có đang ở trạng thái Tắt Tiếng (Mute) hay không."""
        if CURRENT_OS == 'Windows':
            try:
                endpoint = SystemService._get_win_volume_endpoint()
                return bool(endpoint.GetMute())
            except Exception as e:
                print(f"Error getting mute status: {e}")
                return False
        elif CURRENT_OS == 'Linux':
            try:
                out = subprocess.check_output(["amixer", "-D", "pulse", "sget", "Master"], stderr=subprocess.DEVNULL).decode('utf-8')
                return "[off]" in out
            except Exception:
                try:
                    out = subprocess.check_output(["pactl", "get-sink-mute", "@DEFAULT_SINK@"], stderr=subprocess.DEVNULL).decode('utf-8')
                    return "yes" in out.lower()
                except Exception:
                    try:
                        out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], stderr=subprocess.DEVNULL).decode('utf-8')
                        return "[MUTED]" in out
                    except Exception:
                        pass
        return False

    @staticmethod
    def toggle_mute() -> bool:
        """Đảo trạng thái Tắt Tiếng (Mute -> Unmute và ngược lại)."""
        if CURRENT_OS == 'Windows':
            try:
                endpoint = SystemService._get_win_volume_endpoint()
                current_mute = endpoint.GetMute()
                endpoint.SetMute(0 if current_mute else 1, None)
                print(f"[Volume] Toggled Mute -> {'Muted' if not current_mute else 'Unmuted'}")
                return True
            except Exception as e:
                print(f"Error toggling mute: {e}")
                return False
        elif CURRENT_OS == 'Linux':
            try:
                subprocess.run(["amixer", "-q", "-D", "pulse", "sset", "Master", "toggle"], check=True)
                return True
            except Exception:
                try:
                    subprocess.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"], check=True)
                    return True
                except Exception:
                    try:
                        subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"], check=True)
                        return True
                    except Exception as e:
                        print(f"Linux Toggle Mute error: {e}")
                        return False
        return False

    @staticmethod
    def set_brightness(level: int) -> bool:
        """Đổi độ sáng màn hình (0-100%)."""
        level = max(0, min(100, level))
        try:
            sbc.set_brightness(level)
            return True
        except Exception as e:
            if CURRENT_OS == 'Linux':
                try:
                    subprocess.run(["brightnessctl", "set", f"{level}%"], check=True, stderr=subprocess.DEVNULL)
                    return True
                except Exception:
                    try:
                        out = subprocess.check_output(["xrandr", "--verbose"], stderr=subprocess.DEVNULL).decode('utf-8')
                        import re
                        m = re.search(r"(\S+)\s+connected", out)
                        if m:
                            disp = m.group(1)
                            b_val = max(0.1, level / 100.0)
                            subprocess.run(["xrandr", "--output", disp, "--brightness", str(b_val)], check=True)
                            return True
                    except Exception:
                        pass
            print(f"Error setting brightness: {e}")
            return False

    @staticmethod
    def get_volume() -> int:
        """Lấy mức âm lượng hiện tại thực tế trên máy tính (0-100%)."""
        if CURRENT_OS == 'Windows':
            try:
                endpoint = SystemService._get_win_volume_endpoint()
                if endpoint:
                    return int(round(endpoint.GetMasterVolumeLevelScalar() * 100))
            except Exception as e:
                print(f"Windows Get Volume error: {e}")
                return 50
        elif CURRENT_OS == 'Linux':
            try:
                out = subprocess.check_output(["amixer", "-D", "pulse", "sget", "Master"], stderr=subprocess.DEVNULL).decode('utf-8')
                import re
                m = re.search(r"\[(\d+)%\]", out)
                if m:
                    return int(m.group(1))
            except Exception:
                try:
                    out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], stderr=subprocess.DEVNULL).decode('utf-8')
                    import re
                    m = re.search(r"Volume:\s+(\d+\.\d+)", out)
                    if m:
                        return int(float(m.group(1)) * 100)
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
                if endpoint:
                    if level > 0 and endpoint.GetMute():
                        endpoint.SetMute(0, None)
                    elif level == 0:
                        endpoint.SetMute(1, None)
                    
                    endpoint.SetMasterVolumeLevelScalar(level / 100.0, None)
                    print(f"[Volume] Changed Volume to {level}%")
                    return True
            except Exception as e:
                print(f"Windows Set Volume error: {e}")
                return False
        elif CURRENT_OS == 'Linux':
            try:
                subprocess.run(["amixer", "-q", "-D", "pulse", "sset", "Master", f"{level}%"], check=True)
                return True
            except Exception:
                try:
                    subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{level}%"], check=True)
                    return True
                except Exception:
                    try:
                        val_float = level / 100.0
                        subprocess.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", str(val_float)], check=True)
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
                try:
                    subprocess.run(["systemctl", "poweroff"], check=True)
                except Exception:
                    os.system("shutdown -h now")
            elif action == 'restart':
                try:
                    subprocess.run(["systemctl", "reboot"], check=True)
                except Exception:
                    os.system("reboot")
            elif action == 'sleep':
                try:
                    subprocess.run(["systemctl", "suspend"], check=True)
                except Exception:
                    os.system("pm-suspend")
            else:
                return False
            return True
        return False
