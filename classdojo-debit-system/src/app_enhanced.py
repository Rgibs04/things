from flask import Flask, render_template, request, jsonify, redirect, url_for, flash, session
from database_enhanced import DebitCardDatabase
from config import Config
import os
import threading
import time
from email_monitor import EmailMonitor

app = Flask(__name__,
            template_folder='../templates',
            static_folder='../static')

# Load configuration
config = Config()
app.secret_key = config.SECRET_KEY
app.config['SESSION_TYPE'] = 'filesystem'

# Initialize database
db = DebitCardDatabase(config.DATABASE_PATH)

# Email monitor
email_monitor = None

def start_email_monitor():
    """Start email monitoring in background thread"""
    global email_monitor
    if config.EMAIL_USER and config.EMAIL_PASS:
        email_monitor = EmailMonitor(config.DATABASE_PATH)
        monitor_thread = threading.Thread(target=email_monitor.run_monitor, daemon=True)
        monitor_thread.start()
        print("Email monitor started")
    else:
        print("Email monitoring disabled - credentials not configured")

# Start email monitor on startup
start_email_monitor()

@app.route('/')
def index():
    """Home page - Dashboard"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    students = db.get_all_students()
    total_students = len(students)
    total_points = sum(student[8] for student in students)  # point_balance is index 8

    # Get recent transactions
    recent_transactions = []
    for student in students[:10]:  # Get from first 10 students
        transactions = db.get_transaction_history(student[1], 1)  # Get 1 recent transaction per student
        recent_transactions.extend(transactions)

    recent_transactions.sort(key=lambda x: x[11], reverse=True)  # Sort by created_at
    recent_transactions = recent_transactions[:10]  # Keep only 10 most recent

    return render_template('index.html',
                         total_students=total_students,
                         total_points=total_points,
                         recent_transactions=recent_transactions)

@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    """Admin login page"""
    if request.method == 'POST':
        password = request.form.get('password')
        if password == config.ADMIN_PASSWORD:
            session['admin_logged_in'] = True
            return redirect(url_for('index'))
        else:
            flash('Invalid password', 'error')

    return render_template('admin_login.html')

@app.route('/admin/logout')
def admin_logout():
    """Admin logout"""
    session.pop('admin_logged_in', None)
    return redirect(url_for('admin_login'))

@app.route('/students')
def students():
    """View all students"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    all_students = db.get_all_students()
    return render_template('students.html', students=all_students)

@app.route('/student/<student_id>')
def student_detail(student_id):
    """View individual student details"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    student = db.get_student_by_id(student_id)
    transactions = db.get_transaction_history(student_id)

    if not student:
        flash('Student not found!', 'error')
        return redirect(url_for('students'))

    return render_template('student_detail.html',
                         student=student,
                         transactions=transactions)

@app.route('/add_student', methods=['GET', 'POST'])
def add_student():
    """Add a new student"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    if request.method == 'POST':
        student_id = request.form.get('student_id')
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        class_name = request.form.get('class_name')
        card_id = request.form.get('card_id')
        initial_earned = int(request.form.get('initial_earned', 0))
        is_staff = request.form.get('is_staff') == 'on'

        success = db.add_student(student_id, first_name, last_name,
                                class_name, card_id, initial_earned, is_staff)

        if success:
            flash(f'Student {first_name} {last_name} added successfully!', 'success')
            return redirect(url_for('students'))
        else:
            flash('Error adding student. Student ID or Card ID may already exist.', 'error')

    return render_template('add_student.html')

@app.route('/assign_card', methods=['GET', 'POST'])
def assign_card():
    """Assign card to student"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    if request.method == 'POST':
        student_id = request.form.get('student_id')
        card_id = request.form.get('card_id')

        success = db.assign_card(student_id, card_id)

        if success:
            flash(f'Card {card_id} assigned to student {student_id}', 'success')
            return redirect(url_for('students'))
        else:
            flash('Error assigning card', 'error')

    students = db.get_all_students()
    return render_template('assign_card.html', students=students)

@app.route('/transaction', methods=['GET', 'POST'])
def transaction():
    """Process manual transaction"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    if request.method == 'POST':
        card_id = request.form.get('card_id')
        amount = int(request.form.get('amount'))
        description = request.form.get('description', '')
        location = request.form.get('location', 'Admin')

        # Get student by card
        student = db.get_student_by_card(card_id)
        if not student:
            flash('Card not found', 'error')
            return redirect(url_for('transaction'))

        student_id = student[1]

        # Process transaction
        success = db.process_transaction(student_id, amount, description, location)

        if success:
            flash('Transaction successful!', 'success')
        else:
            flash('Transaction failed - insufficient balance', 'error')

        return redirect(url_for('transaction'))

    return render_template('transaction.html')

@app.route('/items')
def items():
    """View and manage POS items"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    items = db.get_all_items()
    return render_template('items.html', items=items)

@app.route('/kiosks')
def kiosks():
    """View registered kiosks"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    kiosks = db.get_all_kiosks()
    return render_template('kiosks.html', kiosks=kiosks)

@app.route('/admin')
def admin():
    """Admin panel"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    import_history = db.get_import_history()
    admin_codes = []  # TODO: Implement admin codes retrieval

    return render_template('admin.html',
                         import_history=import_history,
                         admin_codes=admin_codes)

@app.route('/import_csv', methods=['GET', 'POST'])
def import_csv():
    """Import students from CSV"""
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    if request.method == 'POST':
        if 'csv_file' not in request.files:
            flash('No file uploaded', 'error')
            return redirect(request.url)

        file = request.files['csv_file']
        if file.filename == '':
            flash('No file selected', 'error')
            return redirect(request.url)

        if file and file.filename.lower().endswith('.csv'):
            # Save uploaded file temporarily
            temp_path = f'/tmp/{file.filename}'
            file.save(temp_path)

            # Import CSV
            success = db.import_from_csv(temp_path)

            # Clean up
            os.remove(temp_path)

            if success:
                flash('CSV imported successfully!', 'success')
            else:
                flash('Error importing CSV', 'error')

            return redirect(url_for('students'))

    return render_template('import_csv.html')

# API Endpoints

@app.route('/api/check_card/<card_id>')
def api_check_card(card_id):
    """API endpoint to check card balance"""
    student = db.get_student_by_card(card_id)

    if student:
        return jsonify({
            'success': True,
            'student_id': student[1],
            'name': f"{student[2]} {student[3]}",
            'class': student[4],
            'balance': student[8],  # point_balance
            'is_staff': bool(student[9])  # is_staff
        })
    else:
        return jsonify({
            'success': False,
            'message': 'Card not found'
        }), 404

@app.route('/api/transaction', methods=['POST'])
def api_transaction():
    """API endpoint for processing transactions"""
    data = request.get_json()

    card_id = data.get('card_id')
    amount = int(data.get('amount'))
    transaction_type = data.get('transaction_type', 'purchase')
    description = data.get('description', '')
    location = data.get('location', '')
    kiosk_id = data.get('kiosk_id')

    student = db.get_student_by_card(card_id)

    if not student:
        return jsonify({
            'success': False,
            'message': 'Card not found'
        }), 404

    student_id = student[1]

    if transaction_type == 'purchase':
        amount = -abs(amount)

    success = db.process_transaction(student_id, amount, description, location, kiosk_id=kiosk_id)

    if success:
        updated_student = db.get_student_by_id(student_id)
        return jsonify({
            'success': True,
            'new_balance': updated_student[8],
            'message': 'Transaction successful'
        })
    else:
        return jsonify({
            'success': False,
            'message': 'Insufficient balance or error occurred'
        }), 400

@app.route('/api/items', methods=['GET', 'POST'])
def api_items():
    """API endpoint for item management"""
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401

    if request.method == 'POST':
        data = request.get_json() or request.form

        name = data.get('name')
        price = int(data.get('price'))
        category = data.get('category')
        barcode = data.get('barcode')

        success = db.add_item(name, price, category, barcode)

        return jsonify({
            'success': success,
            'message': 'Item added successfully' if success else 'Error adding item'
        })

    # GET request
    items = db.get_all_items()
    return jsonify({
        'success': True,
        'items': [{
            'id': item[0],
            'name': item[1],
            'price': item[2],
            'category': item[3],
            'barcode': item[4]
        } for item in items]
    })

@app.route('/api/items/<int:item_id>', methods=['DELETE'])
def api_delete_item(item_id):
    """Delete an item"""
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401

    # TODO: Implement item deletion in database
    return jsonify({'success': True, 'message': 'Item deleted'})

@app.route('/api/kiosk/register', methods=['POST'])
def api_register_kiosk():
    """Register a kiosk"""
    data = request.get_json()

    kiosk_id = data.get('kiosk_id')
    kiosk_name = data.get('kiosk_name')
    ip_address = data.get('ip_address')

    success = db.register_kiosk(kiosk_id, kiosk_name, ip_address)

    return jsonify({
        'success': success,
        'message': 'Kiosk registered' if success else 'Registration failed'
    })

@app.route('/api/admin-codes', methods=['GET', 'POST'])
def api_admin_codes():
    """Manage admin codes"""
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401

    if request.method == 'POST':
        data = request.get_json() or request.form

        code = data.get('code')
        description = data.get('description')

        success = db.add_admin_code(code, description)

        return jsonify({
            'success': success,
            'message': 'Admin code added' if success else 'Error adding code'
        })

    # GET request - TODO: Implement admin codes retrieval
    return jsonify({'success': True, 'codes': []})

@app.route('/api/admin-codes/<int:code_id>/<action>', methods=['POST'])
def api_toggle_admin_code(code_id, action):
    """Enable/disable admin code"""
    if not session.get('admin_logged_in'):
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401

    # TODO: Implement code toggle
    return jsonify({'success': True, 'message': f'Code {action}d'})

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        # Check database connectivity
        students = db.get_all_students()
        return jsonify({
            'status': 'healthy',
            'database': 'connected',
            'student_count': len(students)
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 503

@app.route('/api/validate-admin-code', methods=['POST'])
def api_validate_admin_code():
    """Validate admin code"""
    data = request.get_json()
    code = data.get('code')

    valid = db.validate_admin_code(code)

    return jsonify({
        'success': valid,
        'message': 'Valid code' if valid else 'Invalid code'
    })

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    return render_template('500.html'), 500

if __name__ == '__main__':
    print("Starting ClassDojo Debit Card System...")
    print(f"Access the web interface at: http://{config.SERVER_HOST}:{config.SERVER_PORT}")
    print(f"Debug mode: {config.DEBUG}")

    app.run(debug=config.DEBUG,
            host=config.SERVER_HOST,
            port=config.SERVER_PORT)
