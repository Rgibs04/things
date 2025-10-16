import sqlite3
import os
from datetime import datetime

class DebitCardDatabase:
    def __init__(self, db_path='database/school_debit.db'):
        self.db_path = db_path
        # Create database directory if it doesn't exist
        db_dir = os.path.dirname(self.db_path)
        if db_dir and not os.path.exists(db_dir):
            os.makedirs(db_dir)
        self.init_database()

    def get_connection(self):
        """Create a database connection"""
        return sqlite3.connect(self.db_path)

    def init_database(self):
        """Initialize the database with required tables"""
        conn = self.get_connection()
        cursor = conn.cursor()

        # Students table with earned_points, spent_points, and computed balance
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS students (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id TEXT UNIQUE NOT NULL,
                first_name TEXT NOT NULL,
                last_name TEXT NOT NULL,
                class_name TEXT,
                card_id TEXT UNIQUE,
                earned_points INTEGER DEFAULT 0,
                spent_points INTEGER DEFAULT 0,
                point_balance INTEGER GENERATED ALWAYS AS (earned_points - spent_points) STORED,
                is_staff BOOLEAN DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        # Items table for POS system
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                item_name TEXT NOT NULL,
                price INTEGER NOT NULL,
                category TEXT,
                barcode TEXT UNIQUE,
                is_active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        # Transactions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id TEXT NOT NULL,
                transaction_type TEXT NOT NULL,
                amount INTEGER NOT NULL,
                description TEXT,
                balance_after INTEGER NOT NULL,
                location TEXT,
                item_id INTEGER,
                kiosk_id TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (student_id) REFERENCES students(student_id),
                FOREIGN KEY (item_id) REFERENCES items(id)
            )
        ''')

        # Card mappings table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS card_mappings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                card_id TEXT UNIQUE NOT NULL,
                student_id TEXT NOT NULL,
                assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (student_id) REFERENCES students(student_id)
            )
        ''')

        # Kiosk registrations table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS kiosks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                kiosk_id TEXT UNIQUE NOT NULL,
                kiosk_name TEXT,
                ip_address TEXT,
                last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        # Admin codes table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS admin_codes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                code TEXT UNIQUE NOT NULL,
                description TEXT,
                is_active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        # Email import logs
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS email_imports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                filename TEXT NOT NULL,
                imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                student_count INTEGER DEFAULT 0,
                status TEXT DEFAULT 'success'
            )
        ''')

        # Insert default admin code
        cursor.execute('''
            INSERT OR IGNORE INTO admin_codes (code, description)
            VALUES ('ADMIN123', 'Default admin code')
        ''')

        conn.commit()
        conn.close()
        print("Enhanced database initialized successfully!")

    def add_student(self, student_id, first_name, last_name, class_name=None, card_id=None, initial_earned=0, is_staff=False):
        """Add a new student to the database"""
        conn = self.get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute('''
                INSERT INTO students (student_id, first_name, last_name, class_name, card_id, earned_points, is_staff)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (student_id, first_name, last_name, class_name, card_id, initial_earned, is_staff))

            conn.commit()
            print(f"Student {first_name} {last_name} added successfully!")
            return True
        except sqlite3.IntegrityError as e:
            print(f"Error adding student: {e}")
            return False
        finally:
            conn.close()

    def update_earned_points(self, student_id, points):
        """Update earned points (from CSV import)"""
        conn = self.get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute('''
                UPDATE students
                SET earned_points = ?, updated_at = CURRENT_TIMESTAMP
                WHERE student_id = ?
            ''', (points, student_id))

            if cursor.rowcount == 0:
                print(f"Student {student_id} not found!")
                return False

            conn.commit()
            print(f"Updated earned points for {student_id} to {points}")
            return True
        except Exception as e:
            print(f"Error updating earned points: {e}")
            conn.rollback()
            return False
        finally:
            conn.close()

    def process_transaction(self, student_id, amount, description="", location="", item_id=None, kiosk_id=None):
        """Process a transaction (spends points)"""
        conn = self.get_connection()
        cursor = conn.cursor()

        try:
            # Get current balance
            cursor.execute('SELECT point_balance, spent_points FROM students WHERE student_id = ?', (student_id,))
            result = cursor.fetchone()

            if not result:
                print(f"Student {student_id} not found!")
                return False

            current_balance, current_spent = result

            # Check if sufficient balance
            if current_balance < amount:
                print(f"Insufficient balance! Current: {current_balance}, Required: {amount}")
                return False

            # Update spent points
            new_spent = current_spent + amount
            cursor.execute('''
                UPDATE students
                SET spent_points = ?, updated_at = CURRENT_TIMESTAMP
                WHERE student_id = ?
            ''', (new_spent, student_id))

            # Get new balance
            cursor.execute('SELECT point_balance FROM students WHERE student_id = ?', (student_id,))
            new_balance = cursor.fetchone()[0]

            # Log transaction
            cursor.execute('''
                INSERT INTO transactions (student_id, transaction_type, amount, description, balance_after, location, item_id, kiosk_id)
                VALUES (?, 'purchase', ?, ?, ?, ?, ?, ?)
            ''', (student_id, amount, description, new_balance, location, item_id, kiosk_id))

            conn.commit()
            print(f"Transaction successful! New balance: {new_balance}")
            return True
        except Exception as e:
            print(f"Error processing transaction: {e}")
            conn.rollback()
            return False
        finally:
            conn.close()

    def get_student_by_card(self, card_id):
        """Get student information by card ID"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('''
            SELECT * FROM students WHERE card_id = ?
        ''', (card_id,))

        student = cursor.fetchone()
        conn.close()
        return student

    def get_student_by_id(self, student_id):
        """Get student information by student ID"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('''
            SELECT * FROM students WHERE student_id = ?
        ''', (student_id,))

        student = cursor.fetchone()
        conn.close()
        return student

    def get_all_students(self):
        """Get all students"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('SELECT * FROM students ORDER BY last_name, first_name')
        students = cursor.fetchall()
        conn.close()
        return students

    def get_transaction_history(self, student_id, limit=50):
        """Get transaction history for a student"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('''
            SELECT t.*, i.item_name
            FROM transactions t
            LEFT JOIN items i ON t.item_id = i.id
            WHERE t.student_id = ?
            ORDER BY t.created_at DESC
            LIMIT ?
        ''', (student_id, limit))

        transactions = cursor.fetchall()
        conn.close()
        return transactions

    def assign_card(self, student_id, card_id):
        """Assign a card to a student"""
        conn = self.get_connection()
        cursor = conn.cursor()

        try:
            # Update student's card_id
            cursor.execute('''
                UPDATE students SET card_id = ?, updated_at = CURRENT_TIMESTAMP
                WHERE student_id = ?
            ''', (card_id, student_id))

            # Add to card_mappings
            cursor.execute('''
                INSERT OR REPLACE INTO card_mappings (card_id, student_id, is_active)
                VALUES (?, ?, 1)
            ''', (card_id, student_id))

            conn.commit()
            print(f"Card {card_id} assigned to student {student_id}")
            return True
        except sqlite3.IntegrityError as e:
            print(f"Error assigning card: {e}")
            return False
        finally:
            conn.close()

    def import_from_csv(self, csv_path):
        """Import students from CSV file (only updates earned_points)"""
        import csv

        conn = self.get_connection()
        cursor = conn.cursor()

        try:
            imported_count = 0
            with open(csv_path, 'r', encoding='utf-8') as file:
                csv_reader = csv.DictReader(file)

                for row in csv_reader:
                    # Adjust these field names based on ClassDojo's CSV format
                    student_id = row.get('Student ID', row.get('id', ''))
                    first_name = row.get('First Name', row.get('first_name', ''))
                    last_name = row.get('Last Name', row.get('last_name', ''))
                    class_name = row.get('Class', row.get('class', ''))
                    points = int(row.get('Points', row.get('points', 0)))

                    # Check if student exists
                    cursor.execute('SELECT id FROM students WHERE student_id = ?', (student_id,))
                    existing = cursor.fetchone()

                    if existing:
                        # Update existing student's earned points only
                        cursor.execute('''
                            UPDATE students
                            SET earned_points = ?, first_name = ?, last_name = ?, class_name = ?, updated_at = CURRENT_TIMESTAMP
                            WHERE student_id = ?
                        ''', (points, first_name, last_name, class_name, student_id))
                    else:
                        # Add new student
                        cursor.execute('''
                            INSERT INTO students (student_id, first_name, last_name, class_name, earned_points)
                            VALUES (?, ?, ?, ?, ?)
                        ''', (student_id, first_name, last_name, class_name, points))

                    imported_count += 1

                # Log the import
                cursor.execute('''
                    INSERT INTO email_imports (filename, student_count, status)
                    VALUES (?, ?, 'success')
                ''', (os.path.basename(csv_path), imported_count))

                conn.commit()
                print(f"Successfully imported {imported_count} students from {csv_path}")
                return True
        except Exception as e:
            print(f"Error importing CSV: {e}")
            conn.rollback()
            return False
        finally:
            conn.close()

    # Item management methods
    def add_item(self, item_name, price, category=None, barcode=None):
        """Add an item to the POS system"""
        conn = self.get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute('''
                INSERT INTO items (item_name, price, category, barcode)
                VALUES (?, ?, ?, ?)
            ''', (item_name, price, category, barcode))

            conn.commit()
            print(f"Item {item_name} added successfully!")
            return True
        except sqlite3.IntegrityError as e:
            print(f"Error adding item: {e}")
            return False
        finally:
            conn.close()

    def get_all_items(self):
        """Get all active items"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('SELECT * FROM items WHERE is_active = 1 ORDER BY item_name')
        items = cursor.fetchall()
        conn.close()
        return items

    def get_item_by_id(self, item_id):
        """Get item by ID"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('SELECT * FROM items WHERE id = ? AND is_active = 1', (item_id,))
        item = cursor.fetchone()
        conn.close()
        return item

    def get_item_by_barcode(self, barcode):
        """Get item by barcode"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('SELECT * FROM items WHERE barcode = ? AND is_active = 1', (barcode,))
        item = cursor.fetchone()
        conn.close()
        return item

    # Kiosk management methods
    def register_kiosk(self, kiosk_id, kiosk_name=None, ip_address=None):
        """Register or update a kiosk"""
        conn = self.get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute('''
                INSERT OR REPLACE INTO kiosks (kiosk_id, kiosk_name, ip_address, last_seen, is_active)
                VALUES (?, ?, ?, CURRENT_TIMESTAMP, 1)
            ''', (kiosk_id, kiosk_name, ip_address))

            conn.commit()
            print(f"Kiosk {kiosk_id} registered successfully!")
            return True
        except Exception as e:
            print(f"Error registering kiosk: {e}")
            return False
        finally:
            conn.close()

    def get_all_kiosks(self):
        """Get all active kiosks"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('SELECT * FROM kiosks WHERE is_active = 1 ORDER BY last_seen DESC')
        kiosks = cursor.fetchall()
        conn.close()
        return kiosks

    # Admin code methods
    def validate_admin_code(self, code):
        """Validate admin code"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('SELECT id FROM admin_codes WHERE code = ? AND is_active = 1', (code,))
        result = cursor.fetchone()
        conn.close()
        return result is not None

    def add_admin_code(self, code, description=None):
        """Add a new admin code"""
        conn = self.get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute('''
                INSERT INTO admin_codes (code, description)
                VALUES (?, ?)
            ''', (code, description))

            conn.commit()
            print(f"Admin code {code} added successfully!")
            return True
        except sqlite3.IntegrityError as e:
            print(f"Error adding admin code: {e}")
            return False
        finally:
            conn.close()

    # Email import methods
    def get_import_history(self, limit=10):
        """Get email import history"""
        conn = self.get_connection()
        cursor = conn.cursor()

        cursor.execute('SELECT * FROM email_imports ORDER BY imported_at DESC LIMIT ?', (limit,))
        imports = cursor.fetchall()
        conn.close()
        return imports


if __name__ == "__main__":
    # Test the enhanced database
    db = DebitCardDatabase()
    print("Enhanced database setup complete!")
