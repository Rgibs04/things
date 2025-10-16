from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from database import DebitCardDatabase
import os

app = Flask(__name__, 
            template_folder='../templates',
            static_folder='../static')

# Get secret key from environment variable or use default for development
app.secret_key = os.environ.get('SECRET_KEY', 'your-secret-key-change-this')

# Initialize database
db = DebitCardDatabase()

@app.route('/')
def index():
    """Home page - Dashboard"""
    students = db.get_all_students()
    total_students = len(students)
    total_points = sum(student[6] for student in students)  # point_balance is index 6
    
    return render_template('index.html', 
                         total_students=total_students,
                         total_points=total_points)

@app.route('/students')
def students():
    """View all students"""
    all_students = db.get_all_students()
    return render_template('students.html', students=all_students)

@app.route('/student/<student_id>')
def student_detail(student_id):
    """View individual student details"""
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
    if request.method == 'POST':
        student_id = request.form.get('student_id')
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        class_name = request.form.get('class_name')
        card_id = request.form.get('card_id')
        initial_balance = int(request.form.get('initial_balance', 0))
        
        success = db.add_student(student_id, first_name, last_name, 
                                class_name, card_id, initial_balance)
        
        if success:
            flash(f'Student {first_name} {last_name} added successfully!', 'success')
            return redirect(url_for('students'))
        else:
            flash('Error adding student. Student ID or Card ID may already exist.', 'error')
    
    return render_template('add_student.html')

@app.route('/transaction', methods=['GET', 'POST'])
def transaction():
    """Process a transaction"""
    if request.method == 'POST':
        card_id = request.form.get('card_id')
        amount = int(request.form.get('amount'))
        transaction_type = request.form.get('transaction_type')
        description = request.form.get('description', '')
        location = request.form.get('location', '')
        
        # Get student by card
        student = db.get_student_by_card(card_id)
        
        if not student:
            flash('Card not found!', 'error')
            return render_template('transaction.html')
        
        student_id = student[1]  # student_id is index 1
        
        # For purchases, amount should be negative
        if transaction_type == 'purchase':
            amount = -abs(amount)
        
        success = db.update_balance(student_id, amount, transaction_type, 
                                   description, location)
        
        if success:
            flash(f'Transaction successful! Amount: {amount} points', 'success')
            return redirect(url_for('student_detail', student_id=student_id))
        else:
            flash('Transaction failed! Insufficient balance or error occurred.', 'error')
    
    return render_template('transaction.html')

@app.route('/assign_card', methods=['GET', 'POST'])
def assign_card():
    """Assign a card to a student"""
    if request.method == 'POST':
        student_id = request.form.get('student_id')
        card_id = request.form.get('card_id')
        
        success = db.assign_card(student_id, card_id)
        
        if success:
            flash(f'Card {card_id} assigned successfully!', 'success')
            return redirect(url_for('student_detail', student_id=student_id))
        else:
            flash('Error assigning card. Card ID may already be in use.', 'error')
    
    students = db.get_all_students()
    return render_template('assign_card.html', students=students)

@app.route('/import_csv', methods=['GET', 'POST'])
def import_csv():
    """Import students from CSV"""
    if request.method == 'POST':
        if 'file' not in request.files:
            flash('No file uploaded!', 'error')
            return redirect(request.url)
        
        file = request.files['file']
        
        if file.filename == '':
            flash('No file selected!', 'error')
            return redirect(request.url)
        
        if file and file.filename.endswith('.csv'):
            # Save file temporarily
            filepath = os.path.join('database', 'temp_import.csv')
            file.save(filepath)
            
            # Import from CSV
            success = db.import_from_csv(filepath)
            
            # Clean up temp file
            os.remove(filepath)
            
            if success:
                flash('Students imported successfully!', 'success')
                return redirect(url_for('students'))
            else:
                flash('Error importing CSV file.', 'error')
        else:
            flash('Please upload a CSV file.', 'error')
    
    return render_template('import_csv.html')

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
            'balance': student[6]
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
    
    student = db.get_student_by_card(card_id)
    
    if not student:
        return jsonify({
            'success': False,
            'message': 'Card not found'
        }), 404
    
    student_id = student[1]
    
    if transaction_type == 'purchase':
        amount = -abs(amount)
    
    success = db.update_balance(student_id, amount, transaction_type, 
                               description, location)
    
    if success:
        updated_student = db.get_student_by_id(student_id)
        return jsonify({
            'success': True,
            'new_balance': updated_student[6],
            'message': 'Transaction successful'
        })
    else:
        return jsonify({
            'success': False,
            'message': 'Insufficient balance or error occurred'
        }), 400

@app.route('/health')
def health():
    """Health check endpoint for Kubernetes"""
    try:
        # Check if database is accessible
        students = db.get_all_students()
        return jsonify({
            'status': 'healthy',
            'database': 'connected'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 503

if __name__ == '__main__':
    print("Starting ClassDojo Debit Card System...")
    print("Access the web interface at: http://localhost:5000")
    
    # Get debug mode from environment variable
    debug_mode = os.environ.get('FLASK_ENV', 'development') == 'development'
    
    app.run(debug=debug_mode, host='0.0.0.0', port=5000)
