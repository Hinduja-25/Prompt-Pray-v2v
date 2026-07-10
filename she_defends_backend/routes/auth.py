from flask import Blueprint, request, jsonify
from middleware.auth import login_required
from services.db_service import db_service

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/login", methods=["POST"])
@login_required
def login_user():
    uid = request.uid
    email = request.user_email
    db_service.record_user_login(uid, email)
    return jsonify({"message": "Login recorded successfully", "uid": uid, "email": email}), 200

@auth_bp.route("/profile", methods=["GET"])
@login_required
def get_profile():
    uid = request.uid
    profile = db_service.get_user_profile(uid)
    if not profile:
        # Return default empty profile
        return jsonify({
            "name": "",
            "age": "",
            "bloodGroup": "",
            "emergencyContacts": [],
            "allergies": "",
            "medicalConditions": "",
            "preferredLanguage": "English"
        }), 200
    return jsonify(profile), 200

@auth_bp.route("/profile", methods=["POST"])
@login_required
def update_profile():
    uid = request.uid
    data = request.json
    
    if not data:
        return jsonify({"error": "Missing profile data"}), 400
        
    # Validation
    required_fields = ["name", "age", "bloodGroup", "emergencyContacts"]
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Missing required field: {field}"}), 400
            
    success = db_service.save_user_profile(uid, data)
    if success:
        return jsonify({"message": "Profile updated successfully", "profile": data}), 200
    return jsonify({"error": "Failed to update profile"}), 500
