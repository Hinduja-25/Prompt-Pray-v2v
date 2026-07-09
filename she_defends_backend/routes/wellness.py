from flask import Blueprint, request, jsonify
from datetime import datetime
from middleware.auth import login_required
from services.db_service import db_service
from services.gemini_service import gemini_service

wellness_bp = Blueprint("wellness", __name__)

@wellness_bp.route("/mood", methods=["POST"])
@login_required
def add_mood():
    uid = request.uid
    data = request.json
    
    if not data or "mood" not in data:
        return jsonify({"error": "Missing mood entry"}), 400
        
    mood_entry = {
        "mood": data["mood"],  # Happy, Neutral, Sad, Anxious, Angry
        "intensity": data.get("intensity", 3), # 1 to 5
        "timestamp": datetime.utcnow().isoformat()
    }
    
    db_service.add_mood_log(uid, mood_entry)
    return jsonify({"message": "Mood logged successfully", "mood": mood_entry}), 200

@wellness_bp.route("/moods", methods=["GET"])
@login_required
def get_moods():
    uid = request.uid
    moods = db_service.get_mood_logs(uid)
    return jsonify(moods), 200

@wellness_bp.route("/journal", methods=["POST"])
@login_required
def save_journal():
    uid = request.uid
    data = request.json
    
    if not data or "content" not in data:
        return jsonify({"error": "Journal content is missing"}), 400
        
    journal_text = data["content"]
    
    # Process text using Gemini to extract key themes
    themes_result = gemini_service.analyze_journal_entry(journal_text)
    
    journal_entry = {
        "content": journal_text,
        "themes": themes_result.get("themes", []),
        "timestamp": datetime.utcnow().isoformat()
    }
    
    db_service.save_journal_entry(uid, journal_entry)
    return jsonify(journal_entry), 200

@wellness_bp.route("/journals", methods=["GET"])
@login_required
def get_journals():
    uid = request.uid
    journals = db_service.get_journal_entries(uid)
    return jsonify(journals), 200
