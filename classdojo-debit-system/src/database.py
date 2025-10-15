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
        
        # Students table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS students (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id TEXT UNIQUE NOT NULL,
                first_name TEXT NOT NULL,
                last_name TEXT NOT NULL,
                class_name TEXT,
                card_id TEXT UNIQUE,
                point_balance INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (student_id) REFERENCES students(student_id)
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
        
        # Classes table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS classes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                class_name TEXT UNIQUE NOT NULL,
                teacher_name TEXT,
                grade_level TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
        print("Database initialized successfully!")
    
    def add_student(self, student_id, first_name, last_name, class_name=None, card_id=None, initial_balance=0):
        """Add a new student to the database"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute('''
                INSERT INTO students (student_id, first_name, last_name, class_name, card_id, point_balance)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (student_id, first_name, last_name, class_name, card_id, initial_balance))
            
            conn.commit()
            print(f"Student {first_name} {last_name} added successfully!")
            return True
        except sqlite3.IntegrityError as e:
            print(f"Error adding student: {e}")
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
    
    def update_balance(self, student_id, amount, transaction_type, description="", location=""):
        """Update student balance and log transaction"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        try:
            # Get current balance
            cursor.execute('SELECT point_balance FROM students WHERE student_id = ?', (student_id,))
            result = cursor.fetchone()
            
            if not result:
                print(f"Student {student_id} not found!")
                return False
            
            current_balance = result[0]
            new_balance = current_balance + amount
            
            # Check for negative balance on debit
            if new_balance < 0:
                print(f"Insufficient balance! Current: {current_balance}, Attempted: {amount}")
                return False
            
            # Update balance
            cursor.execute('''
                UPDATE students 
                SET point_balance = ?, updated_at = CURRENT_TIMESTAMP
                WHERE student_id = ?
            ''', (new_balance, student_id))
            
            # Log transaction
            cursor.execute('''
                INSERT INTO transactions (student_id, transaction_type, amount, description, balance_after, location)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (student_id, transaction_type, amount, description, new_balance, location))
            
            conn.commit()
            print(f"Transaction successful! New balance: {new_balance}")
            return True
        except Exception as e:
            print(f"Error updating balance: {e}")
            conn.rollback()
            return False
        finally:
            conn.close()
    
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
            SELECT * FROM transactions 
            WHERE student_id = ? 
            ORDER BY created_at DESC 
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
                UPDATE students SET card_id = ? WHERE student_id = ?
            ''', (card_id, student_id))
            
            # Add to card_mappings
            cursor.execute('''
                INSERT INTO card_mappings (card_id, student_id, is_active)
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
        """Import students from CSV file (ClassDojo export format)"""
        import csv
        
        conn = self.get_connection()
        cursor = conn.cursor()
        
        try:
            with open(csv_path, 'r', encoding='utf-8') as file:
                csv_reader = csv.DictReader(file)
                
                for row in csv_reader:
                    # Adjust these field names based on ClassDojo's CSV format
                    student_id = row.get('Student ID', row.get('id', ''))
                    first_name = row.get('First Name', row.get('first_name', ''))
                    last_name = row.get('Last Name', row.get('last_name', ''))
                    class_name = row.get('Class', row.get('class', ''))
                    points = int(row.get('Points', row.get('points', 0)))
                    
                    cursor.execute('''
                        INSERT OR REPLACE INTO students 
                        (student_id, first_name, last_name, class_name, point_balance)
                        VALUES (?, ?, ?, ?, ?)
                    ''', (student_id, first_name, last_name, class_name, points))
                
                conn.commit()
                print(f"Successfully imported students from {csv_path}")
                return True
        except Exception as e:
            print(f"Error importing CSV: {e}")
            conn.rollback()
            return False
        finally:
            conn.close()


if __name__ == "__main__":
    # Test the database
    db = DebitCardDatabase()
    print("Database setup complete!")
