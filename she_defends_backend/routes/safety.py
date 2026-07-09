from flask import Blueprint, request, jsonify
from datetime import datetime
from middleware.auth import login_required
from services.db_service import db_service

safety_bp = Blueprint("safety", __name__)

@safety_bp.route("/journey/start", methods=["POST"])
@login_required
def start_journey():
    uid = request.uid
    data = request.json
    
    if not data or "source" not in data or "destination" not in data:
        return jsonify({"error": "Missing source or destination"}), 400
        
    journey_data = {
        "source": data["source"],
        "destination": data["destination"],
        "eta": data.get("eta", 30), # minutes
        "start_time": datetime.utcnow().isoformat(),
        "route_history": [],
        "current_location": data.get("current_location", None),
        "status": "active",
        "risk_score": 0.0
    }
    
    journey_id = db_service.start_journey(uid, journey_data)
    journey_data["id"] = journey_id
    
    return jsonify(journey_data), 200

@safety_bp.route("/journey/<journey_id>/location", methods=["POST"])
@login_required
def update_location(journey_id):
    uid = request.uid
    data = request.json
    
    if not data or "latitude" not in data or "longitude" not in data:
        return jsonify({"error": "Missing coordinates"}), 400
        
    location_log = {
        "latitude": data["latitude"],
        "longitude": data["longitude"],
        "speed": data.get("speed", 0.0),
        "timestamp": datetime.utcnow().isoformat()
    }
    
    db_service.update_journey_location(uid, journey_id, location_log)
    return jsonify({"message": "Location updated successfully"}), 200

@safety_bp.route("/journey/<journey_id>/complete", methods=["POST"])
@login_required
def complete_journey(journey_id):
    uid = request.uid
    data = request.json or {}
    status = data.get("status", "completed") # can be completed or escalated_sos
    
    db_service.complete_journey(uid, journey_id, status)
    return jsonify({"message": f"Journey status set to {status}"}), 200

@safety_bp.route("/journeys", methods=["GET"])
@login_required
def get_journeys():
    uid = request.uid
    journeys = db_service.get_journeys(uid)
    return jsonify(journeys), 200

@safety_bp.route("/sos/trigger", methods=["POST"])
@login_required
def trigger_sos():
    uid = request.uid
    data = request.json or {}
    
    # Store SOS log in database
    sos_log = {
        "timestamp": datetime.utcnow().isoformat(),
        "location": data.get("location", None),
        "status": "triggered"
    }
    
    # Trigger SMS mock alert output log
    print(f"[EMERGENCY SOS TRIGGERED] User UID: {uid} at location: {sos_log['location']}")
    
    db_service.add_symptom_log(uid, {
        "symptoms": "EMERGENCY SOS ALERT ACTIVATED",
        "analysis": {
            "possible_conditions": ["SOS Alert"],
            "urgency_level": "High",
            "suggestions": ["Emergency contacts notified.", "Live location broadcast active."],
            "warning_signs": [],
            "disclaimer": "Emergency services contact initiated."
        },
        "timestamp": datetime.utcnow().isoformat()
    })
    
    return jsonify({"message": "SOS alert processed successfully", "sos_log": sos_log}), 200
