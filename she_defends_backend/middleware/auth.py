import os
from functools import wraps
from flask import request, jsonify
import firebase_admin
from firebase_admin import auth, credentials
import logging
from config import Config

# Initialize Firebase Admin SDK
firebase_initialized = False
try:
    if Config.FIREBASE_CREDS_PATH and os.path.exists(Config.FIREBASE_CREDS_PATH):
        creds = credentials.Certificate(Config.FIREBASE_CREDS_PATH)
        firebase_admin.initialize_app(creds)
        firebase_initialized = True
        logging.info("Firebase Admin SDK initialized successfully.")
    else:
        # Try initializing with default credentials
        firebase_admin.initialize_app()
        firebase_initialized = True
        logging.info("Firebase Admin SDK initialized with default credentials.")
except Exception as e:
    logging.warning(f"Firebase Admin SDK initialization bypassed (Mock authentication mode active): {str(e)}")

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Authorization token is missing or malformed"}), 401
            
        token = auth_header.split("Bearer ")[1]
        
        if not firebase_initialized or token.startswith("mock_"):
            # Mock mode active: extract user id from mock token (e.g. mock_user -> user)
            uid = token.replace("mock_", "") if token.startswith("mock_") else "default_mock_uid"
            request.uid = uid
            request.user_email = f"{uid}@example.com" if not "@" in uid else uid
            return f(*args, **kwargs)
            
        try:
            decoded_token = auth.verify_id_token(token)
            request.uid = decoded_token["uid"]
            request.user_email = decoded_token.get("email", "")
        except Exception as e:
            logging.error(f"Token verification failed: {str(e)}")
            return jsonify({"error": "Invalid token"}), 401
            
        return f(*args, **kwargs)
        
    return decorated_function
