# ClassDojo Debit Card System

A comprehensive debit card management system that integrates with ClassDojo points, allowing students to use their earned points as currency within the school.

## Features

- 👥 **Student Management** - Add, view, and manage student accounts
- 💳 **Card Assignment** - Link physical debit cards to student accounts
- 💰 **Transaction Processing** - Handle purchases, credits, and refunds
- 📊 **Balance Tracking** - Real-time point balance monitoring
- 📜 **Transaction History** - Complete audit trail of all transactions
- 📥 **CSV Import** - Bulk import students from ClassDojo exports
- 🌐 **Web Interface** - Easy-to-use admin dashboard
- 🔌 **API Endpoints** - RESTful API for card readers and POS systems

## Installation

### 🚀 Quick Install for Raspberry Pi 3B (Recommended)

**One-line installation:**
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install.sh | sudo bash
```

Or from local files:
```bash
cd classdojo-debit-system
sudo bash install.sh
```

The installer will:
- ✅ Detect your system automatically
- ✅ Check requirements (RAM, disk, architecture)
- ✅ Let you choose installation method (K3s, Docker Compose, or Standalone)
- ✅ Install all dependencies
- ✅ Configure and start the application
- ✅ Set up automatic startup

**Installation time:** 15-30 minutes

📚 **See [QUICK-INSTALL.md](QUICK-INSTALL.md) for detailed instructions**

---

### 📦 Installation Methods

#### Option 1: Docker Compose (Recommended for most users)
```bash
cd classdojo-debit-system
sudo bash docker-compose-install.sh
```
- Easy management with `classdojo-manage` command
- ~200MB RAM usage
- Container isolation

#### Option 2: K3s (Kubernetes - Production ready)
```bash
cd classdojo-debit-system
sudo bash raspberry-pi-setup.sh
```
- Full Kubernetes orchestration
- Auto-healing and scaling
- ~400MB RAM usage

#### Option 3: Standalone Python (Minimal resources)
```bash
cd classdojo-debit-system
sudo bash standalone-install.sh
```
- No containers
- ~100MB RAM usage
- Direct Python execution

#### Option 4: Manual Installation (Development)

**Prerequisites:**
- Python 3.7 or higher
- pip (Python package manager)

**Setup Steps:**

1. **Navigate to the project directory:**
   ```bash
   cd classdojo-debit-system
   ```

2. **Install required packages:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application:**
   ```bash
   python src/app.py
   ```

4. **Access the web interface:**
   Open your browser and go to: `http://localhost:5000`

---

### 📖 Installation Documentation

- **[QUICK-INSTALL.md](QUICK-INSTALL.md)** - Quick installation reference
- **[INSTALL.md](INSTALL.md)** - Complete installation guide
- **[INSTALLATION-SUMMARY.md](INSTALLATION-SUMMARY.md)** - Installation comparison
- **[RASPBERRY-PI-GUIDE.md](RASPBERRY-PI-GUIDE.md)** - Detailed Raspberry Pi guide
- **[RASPBERRY-PI-QUICKSTART.md](RASPBERRY-PI-QUICKSTART.md)** - Quick start guide

## Usage Guide

### Getting Started

1. **Import Students**
   - Export student data from ClassDojo as CSV
   - Use the "Import CSV" feature to bulk import students
   - Or manually add students one by one

2. **Assign Cards**
   - Use the "Assign Card" feature
   - Scan physical cards or enter card IDs manually
   - Each student gets a unique card

3. **Process Transactions**
   - Use the "New Transaction" page
   - Scan student cards at point of sale
   - System automatically updates balances

### CSV Import Format

Your CSV file should include these columns:
```csv
Student ID,First Name,Last Name,Class,Points
S001,John,Smith,Grade 5A,150
S002,Emma,Johnson,Grade 5A,200
```

### API Endpoints

#### Check Card Balance
```
GET /api/check_card/<card_id>
```

Response:
```json
{
  "success": true,
  "student_id": "S001",
  "name": "John Smith",
  "class": "Grade 5A",
  "balance": 150
}
```

#### Process Transaction
```
POST /api/transaction
Content-Type: application/json

{
  "card_id": "CARD001",
  "amount": 50,
  "transaction_type": "purchase",
  "description": "School store purchase",
  "location": "School Store"
}
```

Response:
```json
{
  "success": true,
  "new_balance": 100,
  "message": "Transaction successful"
}
```

## Database Structure

The system uses SQLite with the following tables:

- **students** - Student information and balances
- **transactions** - Complete transaction history
- **card_mappings** - Card-to-student assignments
- **classes** - Class/grade information

## Integration with Card Readers

The system supports various card reader types:

1. **Barcode Scanners** - Acts as keyboard input
2. **RFID Readers** - Returns unique card IDs
3. **Magnetic Stripe Readers** - Standard card readers
4. **Manual Entry** - Keyboard input for testing

Simply configure your card reader to output the card ID, and the system will handle the rest.

## Future Enhancements (When ClassDojo API Access is Available)

- ✅ Real-time sync with ClassDojo
- ✅ Automatic point updates
- ✅ Two-way data synchronization
- ✅ Webhook integration for instant updates

## Security Notes

- Change the `app.secret_key` in `src/app.py` before production use
- Consider adding authentication for admin access
- Use HTTPS in production environments
- Regularly backup the database file

## Troubleshooting

**Issue: Port 5000 already in use**
- Solution: Change the port in `src/app.py` (line with `app.run()`)

**Issue: Database not found**
- Solution: The database is created automatically on first run in the `database/` folder

**Issue: CSV import fails**
- Solution: Check CSV format matches the example, ensure proper encoding (UTF-8)

## File Structure

```
classdojo-debit-system/
├── src/
│   ├── app.py           # Main Flask application
│   └── database.py      # Database management
├── templates/           # HTML templates
│   ├── base.html
│   ├── index.html
│   ├── students.html
│   ├── student_detail.html
│   ├── add_student.html
│   ├── transaction.html
│   ├── assign_card.html
│   └── import_csv.html
├── database/            # SQLite database (created on first run)
├── static/              # Static files (CSS, JS, images)
├── requirements.txt     # Python dependencies
└── README.md           # This file
```

## Support

For questions or issues, contact your school's IT administrator.

## License

This project is created for educational purposes.
