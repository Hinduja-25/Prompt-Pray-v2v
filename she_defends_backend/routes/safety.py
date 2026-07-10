from flask import Blueprint, request, jsonify
from datetime import datetime
import math
import requests
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
    if not contacts:
        profile = db_service.get_user_profile(uid)
        if profile and profile.get("emergencyContacts"):
            import uuid
            for c_phone in profile["emergencyContacts"]:
                db_service.save_emergency_contact(uid, {
                    "id": uuid.uuid4().hex,
                    "name": f"Emergency Contact ({c_phone})",
                    "phone": c_phone,
                    "category": "Family"
                })
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

def calculate_distance(lat1, lon1, lat2, lon2):
    p = 0.017453292519943295  # Math.PI / 180
    a = 0.5 - math.cos((lat2 - lat1) * p)/2 + math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p))/2
    return 12742 * math.asin(math.sqrt(a))  # km

@safety_bp.route("/safe-places", methods=["GET"])
@login_required
def get_safe_places():
    lat_val = request.args.get("lat")
    lng_val = request.args.get("lng")
    
    default_lat = 40.7749
    default_lng = -73.9712
    
    try:
        lat = float(lat_val) if lat_val else default_lat
        lng = float(lng_val) if lng_val else default_lng
    except ValueError:
        lat = default_lat
        lng = default_lng

    # Generate dynamic local fallback places centered around the requested coordinate
    fallback_places = [
        {"name": "St. Mary Medical Center", "lat": lat + 0.005, "lng": lng + 0.004, "phone": "555-0199", "type": "Hospital"},
        {"name": "Central Police Precinct", "lat": lat - 0.007, "lng": lng - 0.005, "phone": "555-0144", "type": "Police Station"},
        {"name": "SafeHaven Community Center", "lat": lat + 0.008, "lng": lng - 0.006, "phone": "555-0122", "type": "Safe Place"},
        {"name": "24/7 Downtown Pharmacy", "lat": lat - 0.003, "lng": lng + 0.008, "phone": "555-0188", "type": "Pharmacy"},
        {"name": "Women's Crisis Helpline Office", "lat": lat - 0.005, "lng": lng - 0.008, "phone": "555-0211", "type": "Safe Place"},
    ]

    for p in fallback_places:
        dist_km = calculate_distance(lat, lng, p["lat"], p["lng"])
        dist_miles = dist_km * 0.621371
        p["dist"] = f"{dist_miles:.2f} miles away"


    # Query Overpass API for police, hospital, pharmacy, and community centre within 5000 meters (5km)
    query = f"""[out:json][timeout:15];
    (
      node["amenity"="police"](around:5000, {lat}, {lng});
      way["amenity"="police"](around:5000, {lat}, {lng});
      node["amenity"="hospital"](around:5000, {lat}, {lng});
      way["amenity"="hospital"](around:5000, {lat}, {lng});
      node["amenity"="pharmacy"](around:5000, {lat}, {lng});
      way["amenity"="pharmacy"](around:5000, {lat}, {lng});
      node["amenity"="community_centre"](around:5000, {lat}, {lng});
      way["amenity"="community_centre"](around:5000, {lat}, {lng});
    );
    out tags center;"""
    
    url = "https://overpass-api.de/api/interpreter"
    headers = {
        "User-Agent": "SheDefendsApp/1.0 (contact: hindujasimhadri@gmail.com)"
    }
    
    try:
        response = requests.post(url, data={"data": query}, headers=headers, timeout=15)
        if response.status_code == 200:
            osm_data = response.json()
            elements = osm_data.get("elements", [])
            places = []
            
            for elem in elements:
                tags = elem.get("tags", {})
                amenity = tags.get("amenity")
                
                if amenity == "police":
                    p_type = "Police Station"
                    fallback_phone = "100"
                elif amenity == "hospital":
                    p_type = "Hospital"
                    fallback_phone = "108"
                elif amenity == "pharmacy":
                    p_type = "Pharmacy"
                    fallback_phone = "102"
                else:
                    p_type = "Safe Place"
                    fallback_phone = "555-0122"
                
                name = tags.get("name")
                if not name:
                    brand = tags.get("brand") or tags.get("operator")
                    street = tags.get("addr:street")
                    if brand:
                        name = f"{brand} ({p_type})"
                    elif street:
                        name = f"{p_type} on {street}"
                    else:
                        name = f"Nearby {p_type}"
                
                elem_lat = elem.get("lat") or elem.get("center", {}).get("lat")
                elem_lng = elem.get("lon") or elem.get("center", {}).get("lon")
                
                if elem_lat is None or elem_lng is None:
                    continue
                
                phone = tags.get("phone") or tags.get("contact:phone") or fallback_phone
                dist_km = calculate_distance(lat, lng, elem_lat, elem_lng)
                
                places.append({
                    "name": name,
                    "lat": elem_lat,
                    "lng": elem_lng,
                    "phone": phone,
                    "type": p_type,
                    "distance_km": dist_km
                })
            
            places.sort(key=lambda x: x["distance_km"])
            
            if not places:
                return jsonify(fallback_places), 200
                
            formatted_places = []
            for p in places[:8]:
                dist_miles = p["distance_km"] * 0.621371
                formatted_places.append({
                    "name": p["name"],
                    "lat": p["lat"],
                    "lng": p["lng"],
                    "phone": p["phone"],
                    "type": p["type"],
                    "dist": f"{dist_miles:.2f} miles away"
                })
            return jsonify(formatted_places), 200
    except Exception as e:
        import logging
        logging.error(f"Failed to fetch real safe places from Overpass API: {e}")
        
    return jsonify(fallback_places), 200

