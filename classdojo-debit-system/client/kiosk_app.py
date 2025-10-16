#!/usr/bin/env python3
"""
ClassDojo Debit System - Kiosk Application
Touch-screen kiosk with RFID reader for student transactions
"""

import sys
import os
import time
import threading
import requests
from datetime import datetime, timedelta
import json

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QInputDialog, QLineEdit,
                                 QHBoxLayout, QLabel, QPushButton, QLineEdit,
                                 QTextEdit, QFrame, QGridLayout, QMessageBox,
                                 QProgressBar, QSystemTrayIcon, QMenu, QAction)
    from PyQt5.QtCore import Qt, QTimer, QThread, pyqtSignal, QPropertyAnimation, QRect
    from PyQt5.QtGui import QFont, QPalette, QColor, QPixmap, QIcon
except ImportError:
    print("PyQt5 not installed. Installing...")
    os.system("pip install PyQt5")
    from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                                 QHBoxLayout, QLabel, QPushButton, QLineEdit,
                                 QTextEdit, QFrame, QGridLayout, QMessageBox,
                                 QProgressBar, QSystemTrayIcon, QMenu, QAction)
    from PyQt5.QtCore import Qt, QTimer, QThread, pyqtSignal, QPropertyAnimation, QRect
    from PyQt5.QtGui import QFont, QPalette, QColor, QPixmap, QIcon

from kiosk_config import KioskConfig
from rfid_reader import RFIDReader, MockRFIDReader

class ServerCommunicator(QThread):
    """Thread for communicating with server"""
    balance_received = pyqtSignal(dict)
    transaction_result = pyqtSignal(dict)
    error_occurred = pyqtSignal(str)

    def __init__(self, server_url):
        super().__init__()
        self.server_url = server_url

    def check_balance(self, card_id):
        """Check card balance"""
        try:
            response = requests.get(f"{self.server_url}/api/check_card/{card_id}", timeout=5)
            if response.status_code == 200:
                self.balance_received.emit(response.json())
            else:
                self.error_occurred.emit(f"Server error: {response.status_code}")
        except requests.exceptions.RequestException as e:
            self.error_occurred.emit(f"Connection error: {str(e)}")

    def process_transaction(self, card_id, amount, description="", location="Kiosk"):
        """Process transaction"""
        try:
            data = {
                'card_id': card_id,
                'amount': amount,
                'description': description,
                'location': location
            }
            response = requests.post(f"{self.server_url}/api/transaction",
                                   json=data, timeout=10)

            if response.status_code == 200:
                self.transaction_result.emit(response.json())
            else:
                error_data = response.json()
                self.error_occurred.emit(error_data.get('message', 'Transaction failed'))
        except requests.exceptions.RequestException as e:
            self.error_occurred.emit(f"Connection error: {str(e)}")

class KioskApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.config = KioskConfig()
        self.server_comm = ServerCommunicator(self.config.get('server_url'))
        self.server_comm.balance_received.connect(self.on_balance_received)
        self.server_comm.transaction_result.connect(self.on_transaction_result)
        self.server_comm.error_occurred.connect(self.on_server_error)

        # RFID reader
        self.rfid_reader = None
        self.card_buffer = []

        # State
        self.current_student = None
        self.locked = True
        self.admin_mode = False

        # Timers
        self.lock_timer = QTimer()
        self.lock_timer.timeout.connect(self.lock_kiosk)
        self.update_timer = QTimer()
        self.update_timer.timeout.connect(self.check_for_updates)

        self.init_ui()
        self.init_rfid()
        self.setup_timers()

        # Register kiosk with server
        self.register_kiosk()

        # Auto-discover server if not configured
        if self.config.get('server_url') == 'http://localhost:5000':
            self.discover_server()

    def init_ui(self):
        """Initialize user interface"""
        self.setWindowTitle("ClassDojo Debit System - Kiosk")
        self.setGeometry(0, 0, 800, 600)

        # Set fullscreen if configured
        if self.config.get('fullscreen', True):
            self.showFullScreen()
        else:
            self.showMaximized()

        # Set kiosk mode (prevent alt+tab, etc.)
        self.setWindowFlags(Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint)

        # Main widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)

        # Header
        header_frame = QFrame()
        header_frame.setFrameStyle(QFrame.Box)
        header_layout = QHBoxLayout(header_frame)

        self.status_label = QLabel("KIOSK LOCKED - Tap to unlock")
        self.status_label.setAlignment(Qt.AlignCenter)
        self.status_label.setStyleSheet("font-size: 18px; font-weight: bold; color: red;")
        header_layout.addWidget(self.status_label)

        self.time_label = QLabel()
        self.time_label.setAlignment(Qt.AlignRight)
        header_layout.addWidget(self.time_label)

        layout.addWidget(header_frame)

        # Main content area
        self.content_stack = QVBoxLayout()

        # Locked screen
        self.locked_widget = self.create_locked_screen()
        self.content_stack.addWidget(self.locked_widget)

        # Main screen
        self.main_widget = self.create_main_screen()
        self.main_widget.hide()
        self.content_stack.addWidget(self.main_widget)

        # Admin screen
        self.admin_widget = self.create_admin_screen()
        self.admin_widget.hide()
        self.content_stack.addWidget(self.admin_widget)

        layout.addLayout(self.content_stack)

        # Update clock
        self.update_clock()
        clock_timer = QTimer(self)
        clock_timer.timeout.connect(self.update_clock)
        clock_timer.start(1000)

    def create_locked_screen(self):
        """Create locked screen widget"""
        widget = QWidget()
        layout = QVBoxLayout(widget)

        title = QLabel("KIOSK LOCKED")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("font-size: 48px; font-weight: bold; color: red; margin: 50px;")
        layout.addWidget(title)

        subtitle = QLabel("Tap screen or scan admin card to unlock")
        subtitle.setAlignment(Qt.AlignCenter)
        subtitle.setStyleSheet("font-size: 24px; color: #666; margin: 20px;")
        layout.addWidget(subtitle)

        # Progress bar for timeout
        self.lock_progress = QProgressBar()
        self.lock_progress.setRange(0, 100)
        self.lock_progress.setValue(0)
        layout.addWidget(self.lock_progress)

        return widget

    def create_main_screen(self):
        """Create main transaction screen"""
        widget = QWidget()
        layout = QVBoxLayout(widget)

        # Student info
        info_frame = QFrame()
        info_frame.setFrameStyle(QFrame.Box)
        info_layout = QVBoxLayout(info_frame)

        self.student_name_label = QLabel("No student selected")
        self.student_name_label.setAlignment(Qt.AlignCenter)
        self.student_name_label.setStyleSheet("font-size: 24px; margin: 10px;")
        info_layout.addWidget(self.student_name_label)

        self.student_balance_label = QLabel("Balance: $0.00")
        self.student_balance_label.setAlignment(Qt.AlignCenter)
        self.student_balance_label.setStyleSheet("font-size: 20px; margin: 10px;")
        info_layout.addWidget(self.student_balance_label)

        layout.addWidget(info_frame)

        # Transaction buttons
        buttons_frame = QFrame()
        buttons_layout = QGridLayout(buttons_frame)

        # Quick amount buttons
        amounts = [25, 50, 75, 100, 150, 200]
        for i, amount in enumerate(amounts):
            btn = QPushButton(f"${amount/100:.2f}")
            btn.setStyleSheet("font-size: 18px; padding: 20px; margin: 5px;")
            btn.clicked.connect(lambda checked, amt=amount: self.process_purchase(amt))
            buttons_layout.addWidget(btn, i // 3, i % 3)

        layout.addWidget(buttons_frame)

        # Custom amount
        custom_frame = QFrame()
        custom_layout = QHBoxLayout(custom_frame)

        self.custom_amount_input = QLineEdit()
        self.custom_amount_input.setPlaceholderText("Custom amount (cents)")
        self.custom_amount_input.setStyleSheet("font-size: 16px; padding: 10px;")
        custom_layout.addWidget(self.custom_amount_input)

        custom_btn = QPushButton("Purchase Custom")
        custom_btn.setStyleSheet("font-size: 16px; padding: 10px;")
        custom_btn.clicked.connect(self.process_custom_purchase)
        custom_layout.addWidget(custom_btn)

        layout.addWidget(custom_frame)

        # Messages
        self.message_label = QLabel("")
        self.message_label.setAlignment(Qt.AlignCenter)
        self.message_label.setStyleSheet("font-size: 16px; margin: 20px;")
        layout.addWidget(self.message_label)

        return widget

    def create_admin_screen(self):
        """Create admin screen"""
        widget = QWidget()
        layout = QVBoxLayout(widget)

        title = QLabel("ADMIN MODE")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("font-size: 36px; font-weight: bold; color: blue; margin: 20px;")
        layout.addWidget(title)

        # Admin functions
        functions_layout = QGridLayout()

        btn_config = QPushButton("Configure Kiosk")
        btn_config.clicked.connect(self.show_config)
        functions_layout.addWidget(btn_config, 0, 0)

        btn_restart = QPushButton("Restart Kiosk")
        btn_restart.clicked.connect(self.restart_kiosk)
        functions_layout.addWidget(btn_restart, 0, 1)

        btn_update = QPushButton("Check for Updates")
        btn_update.clicked.connect(self.check_for_updates)
        functions_layout.addWidget(btn_update, 1, 0)

        btn_exit = QPushButton("Exit Admin Mode")
        btn_exit.clicked.connect(self.exit_admin_mode)
        functions_layout.addWidget(btn_exit, 1, 1)

        layout.addLayout(functions_layout)

        # Log area
        self.admin_log = QTextEdit()
        self.admin_log.setReadOnly(True)
        layout.addWidget(self.admin_log)

        return widget

    def init_rfid(self):
        """Initialize RFID reader"""
        try:
            self.rfid_reader = RFIDReader(
                port=self.config.get('rfid_port'),
                baudrate=self.config.get('rfid_baudrate')
            )

            if self.rfid_reader.start_monitoring(self.on_card_read):
                self.log_message("RFID reader initialized")
            else:
                self.log_message("RFID reader failed to initialize, using mock reader")
                self.rfid_reader = MockRFIDReader()
                self.rfid_reader.start_monitoring(self.on_card_read)
        except Exception as e:
            self.log_message(f"RFID initialization error: {e}")
            # Use mock reader as fallback
            self.rfid_reader = MockRFIDReader()
            self.rfid_reader.start_monitoring(self.on_card_read)

    def setup_timers(self):
        """Setup various timers"""
        # Lock timer
        self.lock_timer.setSingleShot(True)
        self.lock_timer.setInterval(self.config.get('lock_timeout_seconds') * 1000)

        # Update check timer (daily)
        self.update_timer.setSingleShot(False)
        self.update_timer.setInterval(self.config.get('update_interval_hours') * 3600000)
        self.update_timer.start()

    def register_kiosk(self):
        """Register kiosk with server"""
        try:
            data = {
                'kiosk_id': self.config.get('kiosk_id'),
                'kiosk_name': self.config.get('kiosk_name'),
                'ip_address': self.get_local_ip()
            }

            response = requests.post(f"{self.config.get('server_url')}/api/kiosk/register",
                                   json=data, timeout=5)

            if response.status_code == 200:
                self.log_message("Kiosk registered with server")
            else:
                self.log_message(f"Failed to register kiosk: {response.status_code}")
        except Exception as e:
            self.log_message(f"Kiosk registration error: {e}")

    def discover_server(self):
        """Auto-discover server on network"""
        self.log_message("Attempting to discover server...")
        server_url = self.config.discover_server()

        if server_url:
            self.log_message(f"Server discovered at: {server_url}")
            self.config.set('server_url', server_url)
            self.server_comm.server_url = server_url
        else:
            self.log_message("Server discovery failed")

    def on_card_read(self, card_id):
        """Handle card read event"""
        self.card_buffer.append(card_id)

        # Process card based on current state
        if self.locked:
            self.try_unlock(card_id)
        elif self.admin_mode:
            self.process_admin_card(card_id)
        else:
            self.process_student_card(card_id)

    def try_unlock(self, card_id):
        """Try to unlock kiosk with admin code or card"""
        # Check if it's an admin code
        if card_id == self.config.get('admin_code'):
            self.unlock_kiosk()
            return

        # Check with server if card belongs to staff
        try:
            response = requests.get(f"{self.config.get('server_url')}/api/check_card/{card_id}", timeout=5)
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and data.get('is_staff'):
                    self.unlock_kiosk()
                    return
        except:
            pass

        # Invalid unlock attempt
        self.show_message("Invalid admin code or card", "red")

    def unlock_kiosk(self):
        """Unlock the kiosk"""
        self.locked = False
        self.show_main_screen()
        self.lock_timer.start()
        self.log_message("Kiosk unlocked")

    def lock_kiosk(self):
        """Lock the kiosk"""
        self.locked = True
        self.admin_mode = False
        self.current_student = None
        self.show_locked_screen()
        self.log_message("Kiosk locked due to timeout")

    def process_student_card(self, card_id):
        """Process student card for transaction"""
        self.server_comm.check_balance(card_id)

    def process_admin_card(self, card_id):
        """Process admin card"""
        if card_id == self.config.get('admin_code'):
            self.exit_admin_mode()
        else:
            self.show_message("Invalid admin code", "red")

    def process_purchase(self, amount):
        """Process purchase transaction"""
        if not self.current_student:
            self.show_message("No student selected", "red")
            return

        card_id = self.current_student.get('card_id')
        if not card_id:
            self.show_message("No card associated with student", "red")
            return

        self.server_comm.process_transaction(card_id, amount, f"Kiosk purchase - ${amount/100:.2f}")

    def process_custom_purchase(self):
        """Process custom amount purchase"""
        try:
            amount = int(self.custom_amount_input.text())
            if amount <= 0:
                raise ValueError("Amount must be positive")

            self.process_purchase(amount)
            self.custom_amount_input.clear()
        except ValueError:
            self.show_message("Invalid amount", "red")

    def on_balance_received(self, data):
        """Handle balance check response"""
        if data.get('success'):
            self.current_student = data
            self.update_student_display()
            self.show_message(f"Welcome, {data['name']}!", "green")
        else:
            self.show_message("Card not recognized", "red")

    def on_transaction_result(self, data):
        """Handle transaction response"""
        if data.get('success'):
            new_balance = data.get('new_balance', 0)
            self.current_student['balance'] = new_balance
            self.update_student_display()
            self.show_message(f"Purchase successful! New balance: ${new_balance/100:.2f}", "green")
        else:
            self.show_message(data.get('message', 'Transaction failed'), "red")

    def on_server_error(self, error):
        """Handle server communication error"""
        self.show_message(f"Server error: {error}", "red")

    def update_student_display(self):
        """Update student information display"""
        if self.current_student:
            name = self.current_student.get('name', 'Unknown')
            balance = self.current_student.get('balance', 0)
            self.student_name_label.setText(f"Student: {name}")
            self.student_balance_label.setText(f"Balance: ${balance/100:.2f}")
        else:
            self.student_name_label.setText("No student selected")
            self.student_balance_label.setText("Balance: $0.00")

    def show_locked_screen(self):
        """Show locked screen"""
        self.main_widget.hide()
        self.admin_widget.hide()
        self.locked_widget.show()
        self.status_label.setText("KIOSK LOCKED - Tap to unlock")
        self.status_label.setStyleSheet("font-size: 18px; font-weight: bold; color: red;")

    def show_main_screen(self):
        """Show main transaction screen"""
        self.locked_widget.hide()
        self.admin_widget.hide()
        self.main_widget.show()
        self.status_label.setText("KIOSK ACTIVE")
        self.status_label.setStyleSheet("font-size: 18px; font-weight: bold; color: green;")

    def show_admin_screen(self):
        """Show admin screen"""
        self.locked_widget.hide()
        self.main_widget.hide()
        self.admin_widget.show()
        self.status_label.setText("ADMIN MODE")
        self.status_label.setStyleSheet("font-size: 18px; font-weight: bold; color: blue;")

    def show_message(self, message, color="black"):
        """Show message to user"""
        color_map = {
            "red": "#ff4444",
            "green": "#44ff44",
            "blue": "#4444ff",
            "black": "#000000"
        }

        self.message_label.setText(message)
        self.message_label.setStyleSheet(f"font-size: 16px; color: {color_map.get(color, '#000000')}; margin: 20px;")

        # Clear message after 5 seconds
        QTimer.singleShot(5000, lambda: self.message_label.setText(""))

    def update_clock(self):
        """Update clock display"""
        current_time = datetime.now().strftime("%H:%M:%S")
        self.time_label.setText(current_time)

    def get_local_ip(self):
        """Get local IP address"""
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
        except:
            return "127.0.0.1"
        finally:
            s.close()

    def check_for_updates(self):
        """Check for application updates"""
        if not self.config.get('auto_update', True):
            return

        try:
            # Check GitHub for latest release
            repo = self.config.get('github_repo')
            response = requests.get(f"https://api.github.com/repos/{repo}/releases/latest", timeout=10)

            if response.status_code == 200:
                release_data = response.json()
                latest_version = release_data.get('tag_name', '')

                # Compare with current version (simplified)
                current_version = "v1.0.0"  # TODO: Read from version file

                if latest_version != current_version:
                    self.log_message(f"Update available: {latest_version}")
                    # TODO: Implement auto-update
                else:
                    self.log_message("Application is up to date")
        except Exception as e:
            self.log_message(f"Update check failed: {e}")

    def show_config(self):
        """Show configuration dialog"""
        # TODO: Implement configuration dialog
        self.log_message("Configuration dialog not implemented yet")

    def restart_kiosk(self):
        """Restart the kiosk application"""
        self.log_message("Restarting kiosk...")
        QTimer.singleShot(1000, lambda: sys.exit(0))

    def exit_admin_mode(self):
        """Exit admin mode"""
        self.admin_mode = False
        self.show_main_screen()

    def log_message(self, message):
        """Log message to admin console"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        log_entry = f"[{timestamp}] {message}"

        if hasattr(self, 'admin_log'):
            self.admin_log.append(log_entry)

        print(log_entry)

    def mousePressEvent(self, event):
        """Handle mouse/touch events"""
        if self.locked:
            # Try to unlock with admin code dialog
            self.try_admin_unlock()
        else:
            # Reset lock timer
            self.lock_timer.start()

        super().mousePressEvent(event)

    def try_admin_unlock(self):
        """Try to unlock with admin code input"""
        # Simple admin code input (in production, use secure PIN pad)
        code, ok = QInputDialog.getText(self, 'Admin Unlock', 'Enter admin code:', QLineEdit.Password)
        if ok and code == self.config.get('admin_code'):
            self.unlock_kiosk()
        elif ok:
            self.show_message("Invalid admin code", "red")

    def closeEvent(self, event):
        """Handle application close"""
        if self.rfid_reader:
            self.rfid_reader.disconnect()

        # Unregister kiosk
        try:
            requests.post(f"{self.config.get('server_url')}/api/kiosk/unregister",
                         json={'kiosk_id': self.config.get('kiosk_id')}, timeout=5)
        except:
            pass

        event.accept()

def main():
    app = QApplication(sys.argv)

    # Set application properties
    app.setApplicationName("ClassDojo Debit Kiosk")
    app.setApplicationVersion("1.0.0")

    # Create kiosk
    kiosk = KioskApp()
    kiosk.show()

    sys.exit(app.exec_())

if __name__ == "__main__":
    main()
