# ClassDojo Debit System - Kiosk Client

Touch-screen kiosk application for processing student debit card transactions.

## Features

- 🔐 **Kiosk Mode** - Locked interface with admin unlock
- 📱 **Touch Screen** - Full touch-screen interface
- 🏷️ **RFID Reader** - Support for RFID card readers
- 💰 **Transaction Processing** - Real-time balance checking and purchases
- 🔄 **Auto Updates** - Automatic software updates from GitHub
- 🌐 **Network Discovery** - Auto-discover server on local network
- ⏰ **Auto Lock** - Automatic lock after inactivity
- 👥 **Staff Authentication** - Admin codes and staff card unlock

## Installation

### Requirements

- Python 3.7+
- PyQt5
- Serial port access (for RFID reader)
- Network connection

### Install Dependencies

```bash
cd client
pip install -r requirements.txt
```

### Linux Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install python3-pyqt5 python3-serial

# For RFID reader permissions
sudo usermod -a -G dialout $USER
```

### Windows Dependencies

```bash
# Install PyQt5
pip install PyQt5

# For serial ports, install pywin32
pip install pywin32
```

## Configuration

The kiosk automatically creates a configuration file `kiosk_config.json` on first run.

### Configuration Options

```json
{
    "server_url": "http://localhost:5000",
    "kiosk_id": "kiosk-abc12345",
    "kiosk_name": "Main Entrance Kiosk",
    "admin_code": "ADMIN123",
    "timeout_seconds": 1800,
    "lock_timeout_seconds": 1800,
    "rfid_port": "/dev/ttyUSB0",
    "rfid_baudrate": 9600,
    "fullscreen": true,
    "auto_update": true,
    "github_repo": "yourusername/classdojo-debit-system",
    "update_interval_hours": 24
}
```

## Running the Kiosk

### Normal Operation

```bash
python kiosk_app.py
```

### Development Mode

```bash
# Windowed mode for development
python kiosk_app.py --dev
```

### Mock RFID Reader

```bash
# Use mock RFID reader for testing
python kiosk_app.py --mock-rfid
```

## RFID Reader Setup

### Hardware Requirements

- RFID reader with serial output
- USB-to-serial adapter (if needed)
- 125kHz RFID cards/tags

### Supported Readers

- Most serial RFID readers that output card IDs
- Tested with common 125kHz readers
- Mock reader available for testing

### Reader Configuration

1. Connect RFID reader to USB port
2. Check device path:
   ```bash
   # Linux
   ls /dev/ttyUSB*

   # Windows
   # Check Device Manager for COM port
   ```

3. Update `kiosk_config.json` with correct port
4. Restart kiosk application

## Usage

### Student Transactions

1. **Unlock Kiosk**: Tap screen or scan admin card/code
2. **Student Card**: Student scans their RFID card
3. **Select Amount**: Choose preset amount or enter custom
4. **Confirm Purchase**: Transaction processes automatically
5. **Auto Lock**: Kiosk locks after timeout

### Admin Functions

- **Unlock**: Use admin code or staff card
- **Configure**: Change settings via admin menu
- **Update**: Check for software updates
- **Restart**: Restart kiosk application

## Network Discovery

The kiosk can automatically discover the server on your local network:

1. Set `server_url` to `"http://localhost:5000"` (default)
2. Kiosk will scan common ports on local subnet
3. Automatically updates configuration when server found

## Auto Updates

The kiosk can automatically update itself from GitHub:

1. Set `auto_update` to `true`
2. Configure `github_repo` with your repository
3. Kiosk checks for updates daily
4. Downloads and installs new versions automatically

## Security Features

- **Kiosk Mode**: Prevents alt+tab, task manager access
- **Auto Lock**: Locks after inactivity timeout
- **Admin Authentication**: Secure admin unlock codes
- **Network Security**: HTTPS support for server communication
- **Input Validation**: Prevents invalid transactions

## Troubleshooting

### RFID Reader Issues

**Reader not detected:**
```bash
# Check USB devices
lsusb

# Check serial ports
ls /dev/tty*

# Test permissions
sudo usermod -a -G dialout $USER
```

**Cards not reading:**
- Check RFID reader power
- Verify antenna connection
- Test with known working card
- Check baud rate settings

### Network Issues

**Can't connect to server:**
```bash
# Test server connectivity
curl http://your-server:5000/health

# Check firewall
sudo ufw status

# Test network discovery
python -c "from kiosk_config import KioskConfig; c = KioskConfig(); print(c.discover_server())"
```

### Display Issues

**Touch not working:**
- Check touchscreen calibration
- Verify PyQt5 touch support
- Test with mouse input

**Wrong resolution:**
- Check display settings
- Update fullscreen configuration
- Test windowed mode

### Performance Issues

**Slow startup:**
- Check system resources
- Disable unnecessary services
- Use SSD storage

**Lag during transactions:**
- Check network latency
- Monitor server performance
- Reduce timeout values

## Development

### Project Structure

```
client/
├── kiosk_app.py          # Main application
├── kiosk_config.py       # Configuration management
├── rfid_reader.py        # RFID reader interface
├── requirements.txt      # Python dependencies
└── README.md            # This file
```

### Adding Features

1. **New Transaction Types**: Extend `process_purchase()` method
2. **Additional Hardware**: Create new reader classes in `rfid_reader.py`
3. **UI Customization**: Modify `create_*_screen()` methods
4. **Server Integration**: Add new API calls in `ServerCommunicator`

### Testing

```bash
# Run with mock RFID reader
python kiosk_app.py --mock-rfid --dev

# Test specific functions
python -c "from rfid_reader import MockRFIDReader; r = MockRFIDReader(); r.simulate_card_read('TEST123')"
```

## API Integration

The kiosk communicates with the server via REST API:

### Check Balance
```
GET /api/check_card/{card_id}
```

### Process Transaction
```
POST /api/transaction
{
    "card_id": "CARD001",
    "amount": 50,
    "description": "Kiosk purchase",
    "location": "Main Entrance"
}
```

### Register Kiosk
```
POST /api/kiosk/register
{
    "kiosk_id": "kiosk-abc123",
    "kiosk_name": "Main Entrance",
    "ip_address": "192.168.1.100"
}
```

## License

This project is created for educational purposes.

## Support

For issues or questions, check:
1. This documentation
2. Server application logs
3. Network connectivity
4. Hardware connections

Contact your system administrator for additional support.
