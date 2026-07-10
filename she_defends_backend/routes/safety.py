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
    
    battery = data.get("battery", 100)
    speed = data.get("speed", 0.0)
    location = data.get("location", "Unknown Location")
    phone = data.get("phone", "Unknown Phone")
    msg = data.get("message", "I may be in danger. This is my live location. Please help immediately.")
    
    sos_log = {
        "timestamp": datetime.utcnow().isoformat(),
        "location": location,
        "speed": speed,
        "battery": battery,
        "status": "triggered"
    }
    
    # Trigger SMS mock alert output log
    print("=" * 60)
    print("!!! EMERGENCY SOS TRIGGERED !!!")
    print(f"User UID: {uid}")
    print(f"Phone: {phone}")
    print(f"Battery: {battery}%")
    print(f"Current Speed: {speed} mph")
    print(f"Location: {location}")
    print(f"Distress Message: '{msg}'")
    print(f"Live Map Link: https://maps.google.com/?q={location.replace(' ', '')}")
    print("=" * 60)
    
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

@safety_bp.route("/contacts", methods=["GET"])
@login_required
def get_contacts():
    uid = request.uid
    contacts = db_service.get_emergency_contacts(uid)
    return jsonify(contacts), 200

@safety_bp.route("/contacts", methods=["POST"])
@login_required
def save_contact():
    uid = request.uid
    data = request.json
    if not data or "name" not in data or "phone" not in data:
        return jsonify({"error": "Missing name or phone"}), 400
    
    contact_id = db_service.save_emergency_contact(uid, data)
    return jsonify({"message": "Contact saved successfully", "id": contact_id}), 200

@safety_bp.route("/contacts/<contact_id>", methods=["DELETE"])
@login_required
def delete_contact(contact_id):
    uid = request.uid
    success = db_service.delete_emergency_contact(uid, contact_id)
    if success:
        return jsonify({"message": "Contact deleted successfully"}), 200
    else:
        return jsonify({"error": "Contact not found or could not be deleted"}), 404

@safety_bp.route("/recordings", methods=["GET"])
@login_required
def get_recordings():
    uid = request.uid
    recordings = db_service.get_emergency_recordings(uid)
    return jsonify(recordings), 200

@safety_bp.route("/recordings", methods=["POST"])
@login_required
def upload_recording():
    uid = request.uid
    data = request.json
    if not data or "filename" not in data:
        return jsonify({"error": "Missing filename"}), 400
    
    recording_data = {
        "filename": data["filename"],
        "timestamp": datetime.utcnow().isoformat(),
        "duration": data.get("duration", "0:00"),
        "size": data.get("size", "0 KB")
    }
    recording_id = db_service.add_emergency_recording(uid, recording_data)
    recording_data["id"] = recording_id
    recording_data.pop("_id", None)  # Remove MongoDB ObjectId to prevent JSON serialization error
    return jsonify({"message": "Recording uploaded successfully", "recording": recording_data}), 200

@safety_bp.route("/safe-places", methods=["GET"])
@login_required
def get_safe_places():
    places = [
        {"name": "St. Mary Medical Center", "dist": "0.8 miles away", "phone": "555-0199", "type": "Hospital", "address": "123 Health Ave", "status": "Open 24/7"},
        {"name": "Central Police Precinct", "dist": "1.2 miles away", "phone": "555-0144", "type": "Police Station", "address": "456 Safety St", "status": "Open 24/7"},
        {"name": "SafeHaven Community Center", "dist": "1.5 miles away", "phone": "555-0122", "type": "Safe Place", "address": "789 Care Rd", "status": "Open 08:00 AM - 10:00 PM"},
        {"name": "24/7 Downtown Pharmacy", "dist": "1.8 miles away", "phone": "555-0188", "type": "Pharmacy", "address": "101 Pill Blvd", "status": "Open 24/7"},
        {"name": "Women's Crisis Helpline Office", "dist": "2.1 miles away", "phone": "555-0211", "type": "Safe Place", "address": "202 Support Dr", "status": "Open 24/7"},
    ]
    return jsonify(places), 200
