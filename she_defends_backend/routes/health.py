from flask import Blueprint, request, jsonify
from datetime import datetime
from middleware.auth import login_required
from services.db_service import db_service
from services.gemini_service import gemini_service
from services.cloudinary_service import CloudinaryService

health_bp = Blueprint("health", __name__)

@health_bp.route("/analyze", methods=["POST"])
@login_required
def analyze_symptom():
    uid = request.uid
    data = request.json
    
    if not data or "symptoms" not in data:
        return jsonify({"error": "Missing symptoms text"}), 400
        
    symptoms_text = data["symptoms"]
    
    # Run Gemini AI analysis
    analysis_result = gemini_service.analyze_symptoms(symptoms_text)
    
    # Log the symptom check in DB
    log_entry = {
        "symptoms": symptoms_text,
        "analysis": analysis_result,
        "timestamp": datetime.utcnow().isoformat()
    }
    log_id = db_service.add_symptom_log(uid, log_entry)
    log_entry["id"] = log_id
    
    return jsonify(log_entry), 200

@health_bp.route("/history", methods=["GET"])
@login_required
def get_health_history():
    uid = request.uid
    logs = db_service.get_symptom_logs(uid)
    return jsonify(logs), 200

@health_bp.route("/medications/sync", methods=["POST"])
@login_required
def sync_meds():
    uid = request.uid
    data = request.json
    
    if not isinstance(data, list):
        return jsonify({"error": "Medications data must be a list"}), 400
        
    db_service.sync_medications(uid, data)
    return jsonify({"message": "Medications synced successfully"}), 200

@health_bp.route("/medications", methods=["GET"])
@login_required
def get_meds():
    uid = request.uid
    meds = db_service.get_medications(uid)
    return jsonify(meds), 200

@health_bp.route("/reports/upload", methods=["POST"])
@login_required
def upload_report():
    uid = request.uid
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400
        
    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400
        
    # Upload to Cloudinary (resilient fallback is active)
    upload_result = CloudinaryService.upload_image(file, folder=f"she_defends/reports/{uid}")
    
    # Save the report to health history
    log_entry = {
        "symptoms": f"Uploaded medical report: {file.filename}",
        "analysis": {
            "possible_conditions": ["Report Uploaded"],
            "urgency_level": "Low",
            "suggestions": ["View uploaded file to consult doctor."],
            "warning_signs": [],
            "disclaimer": "This is an uploaded document.",
            "report_url": upload_result["url"]
        },
        "timestamp": datetime.utcnow().isoformat()
    }
    
    log_id = db_service.add_symptom_log(uid, log_entry)
    log_entry["id"] = log_id
    
    return jsonify(log_entry), 200
