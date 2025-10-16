import os
import json
import socket

class KioskConfig:
    def __init__(self, config_file='kiosk_config.json'):
        self.config_file = config_file
        self.config = self.load_config()

    def load_config(self):
        """Load configuration from file"""
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    return json.load(f)
            except:
                pass

        # Default configuration
        return {
            'server_url': 'http://localhost:5000',
            'kiosk_id': self.generate_kiosk_id(),
            'kiosk_name': socket.gethostname(),
            'admin_code': 'ADMIN123',
            'timeout_seconds': 1800,  # 30 minutes
            'lock_timeout_seconds': 1800,  # 30 minutes
            'rfid_port': '/dev/ttyUSB0',
            'rfid_baudrate': 9600,
            'fullscreen': True,
            'auto_update': True,
            'github_repo': 'yourusername/classdojo-debit-system',
            'update_interval_hours': 24
        }

    def save_config(self):
        """Save configuration to file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            print(f"Error saving config: {e}")

    def get(self, key, default=None):
        """Get configuration value"""
        return self.config.get(key, default)

    def set(self, key, value):
        """Set configuration value"""
        self.config[key] = value
        self.save_config()

    def generate_kiosk_id(self):
        """Generate unique kiosk ID"""
        import uuid
        return f"kiosk-{uuid.uuid4().hex[:8]}"

    def discover_server(self):
        """Discover server on local network"""
        import ipaddress
        import requests

        # Get local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
        except:
            local_ip = "192.168.1.100"
        finally:
            s.close()

        # Try common ports and subnets
        network = ipaddress.ip_network(f"{local_ip}/24", strict=False)
        common_ports = [5000, 8000, 8080]

        for host in network.hosts():
            for port in common_ports:
                try:
                    url = f"http://{host}:{port}/health"
                    response = requests.get(url, timeout=1)
                    if response.status_code == 200:
                        data = response.json()
                        if data.get('status') == 'healthy':
                            self.set('server_url', f"http://{host}:{port}")
                            return f"http://{host}:{port}"
                except:
                    continue

        return None
