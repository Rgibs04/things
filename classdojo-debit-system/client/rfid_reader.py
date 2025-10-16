import serial
import time
import threading
import queue

class RFIDReader:
    def __init__(self, port='/dev/ttyUSB0', baudrate=9600):
        self.port = port
        self.baudrate = baudrate
        self.serial_conn = None
        self.running = False
        self.card_queue = queue.Queue()
        self.callback = None

    def connect(self):
        """Connect to RFID reader"""
        try:
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=1
            )
            print(f"Connected to RFID reader on {self.port}")
            return True
        except Exception as e:
            print(f"Failed to connect to RFID reader: {e}")
            return False

    def disconnect(self):
        """Disconnect from RFID reader"""
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
        self.running = False

    def read_card(self):
        """Read card ID from serial port"""
        if not self.serial_conn or not self.serial_conn.is_open:
            return None

        try:
            # Read line from serial port
            line = self.serial_conn.readline().decode('utf-8').strip()

            if line:
                # Extract card ID (assuming format like "CARD:1234567890" or just "1234567890")
                card_id = line.replace('CARD:', '').strip()
                return card_id
        except Exception as e:
            print(f"Error reading card: {e}")

        return None

    def monitor_cards(self):
        """Monitor for card reads in background thread"""
        self.running = True

        while self.running:
            card_id = self.read_card()
            if card_id:
                self.card_queue.put(card_id)

                # Call callback if set
                if self.callback:
                    try:
                        self.callback(card_id)
                    except Exception as e:
                        print(f"Error in card callback: {e}")

            time.sleep(0.1)  # Small delay to prevent busy waiting

    def start_monitoring(self, callback=None):
        """Start monitoring for cards"""
        self.callback = callback

        if not self.connect():
            return False

        # Start monitoring thread
        monitor_thread = threading.Thread(target=self.monitor_cards, daemon=True)
        monitor_thread.start()

        return True

    def get_next_card(self, timeout=1):
        """Get next card ID from queue"""
        try:
            return self.card_queue.get(timeout=timeout)
        except queue.Empty:
            return None

    def simulate_card_read(self, card_id):
        """Simulate a card read (for testing)"""
        self.card_queue.put(card_id)

        if self.callback:
            try:
                self.callback(card_id)
            except Exception as e:
                print(f"Error in card callback: {e}")

class MockRFIDReader(RFIDReader):
    """Mock RFID reader for testing without hardware"""

    def __init__(self):
        super().__init__(port='mock', baudrate=0)
        self.mock_cards = ['CARD001', 'CARD002', 'CARD003']

    def connect(self):
        """Mock connection"""
        print("Mock RFID reader connected")
        return True

    def read_card(self):
        """Mock card reading"""
        import random
        if random.random() < 0.1:  # 10% chance every read
            return random.choice(self.mock_cards)
        return None

    def disconnect(self):
        """Mock disconnect"""
        print("Mock RFID reader disconnected")
        self.running = False
