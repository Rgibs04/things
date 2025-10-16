import imaplib
import email
import os
import time
from datetime import datetime
from database_enhanced import DebitCardDatabase

class EmailMonitor:
    def __init__(self, db_path='database/school_debit.db'):
        self.db = DebitCardDatabase(db_path)
        self.imap_server = os.environ.get('EMAIL_IMAP_SERVER', 'imap.ionos.co.uk')
        self.email_user = os.environ.get('EMAIL_USER', 'testing@harleycloud.com')
        self.email_pass = os.environ.get('EMAIL_PASS', 'Testing.!2222!.')
        self.check_interval = int(os.environ.get('EMAIL_CHECK_INTERVAL', '300'))  # 5 minutes default

    def connect_imap(self):
        """Connect to IMAP server"""
        try:
            # Connect to IMAP server on port 993 (SSL)
            mail = imaplib.IMAP4_SSL(self.imap_server, 993)
            mail.login(self.email_user, self.email_pass)
            mail.select('inbox')
            return mail
        except Exception as e:
            print(f"Failed to connect to email server: {e}")
            return None

    def process_attachments(self, msg):
        """Process email attachments looking for CSV files"""
        for part in msg.walk():
            if part.get_content_maintype() == 'multipart':
                continue
            if part.get('Content-Disposition') is None:
                continue

            filename = part.get_filename()
            if filename and filename.lower().endswith('.csv'):
                # Save attachment
                temp_path = f'/tmp/{filename}'
                with open(temp_path, 'wb') as f:
                    f.write(part.get_payload(decode=True))

                # Import CSV
                success = self.db.import_from_csv(temp_path)

                # Clean up
                os.remove(temp_path)

                if success:
                    print(f"Successfully imported CSV: {filename}")
                else:
                    print(f"Failed to import CSV: {filename}")

    def check_emails(self):
        """Check for new emails with CSV attachments"""
        mail = self.connect_imap()
        if not mail:
            return

        try:
            # Search for unread emails
            status, messages = mail.search(None, 'UNSEEN')

            if status == 'OK':
                for msg_id in messages[0].split():
                    # Fetch email
                    status, msg_data = mail.fetch(msg_id, '(RFC822)')
                    if status != 'OK':
                        continue

                    email_body = msg_data[0][1]
                    msg = email.message_from_bytes(email_body)

                    # Process attachments
                    self.process_attachments(msg)

                    # Mark as read
                    mail.store(msg_id, '+FLAGS', '\\Seen')

        except Exception as e:
            print(f"Error checking emails: {e}")
        finally:
            try:
                mail.logout()
            except:
                pass

    def run_monitor(self):
        """Run the email monitoring loop"""
        print("Starting email monitor...")
        print(f"Checking every {self.check_interval} seconds")

        while True:
            try:
                self.check_emails()
            except Exception as e:
                print(f"Email monitor error: {e}")

            time.sleep(self.check_interval)

if __name__ == "__main__":
    monitor = EmailMonitor()
    monitor.run_monitor()
