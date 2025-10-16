import os

class Config:
    # Flask settings
    SECRET_KEY = os.environ.get('SECRET_KEY', 'change-this-in-production')

    # Database
    DATABASE_PATH = os.environ.get('DATABASE_PATH', 'database/school_debit.db')

    # Email monitoring
    EMAIL_IMAP_SERVER = os.environ.get('EMAIL_IMAP_SERVER', 'imap.ionos.co.uk')
    EMAIL_USER = os.environ.get('testing@harleycloud.com')
    EMAIL_PASS = os.environ.get('Testing.!2222!.')
    EMAIL_CHECK_INTERVAL = int(os.environ.get('EMAIL_CHECK_INTERVAL', '300'))

    # Kiosk settings
    KIOSK_ADMIN_CODE = os.environ.get('KIOSK_ADMIN_CODE', 'ADMIN123')
    KIOSK_TIMEOUT = int(os.environ.get('KIOSK_TIMEOUT', '1800'))  # 30 minutes
    KIOSK_LOCK_TIMEOUT = int(os.environ.get('KIOSK_LOCK_TIMEOUT', '1800'))  # 30 minutes

    # Network settings
    SERVER_HOST = os.environ.get('SERVER_HOST', '0.0.0.0')
    SERVER_PORT = int(os.environ.get('SERVER_PORT', '5000'))
    SERVER_NETWORK = os.environ.get('SERVER_NETWORK', '10.0.0.0/24')

    # Update settings
    GITHUB_REPO = os.environ.get('GITHUB_REPO', 'yourusername/classdojo-debit-system')
    AUTO_UPDATE = os.environ.get('AUTO_UPDATE', 'false').lower() == 'true'

    # Security
    ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'admin123')
    SESSION_TIMEOUT = int(os.environ.get('SESSION_TIMEOUT', '3600'))  # 1 hour

    # Development
    DEBUG = os.environ.get('FLASK_ENV', 'production') == 'development'
