from flask import Blueprint, request, jsonify
from middleware.auth import login_required
from services.gemini_service import gemini_service

assistant_bp = Blueprint("assistant", __name__)

@assistant_bp.route("/chat", methods=["POST"])
@login_required
def chat_companion():
    data = request.json
    
    if not data or "message" not in data:
        return jsonify({"error": "Message content is required"}), 400
        
    user_message = data["message"]
    chat_history = data.get("history", [])
    
    chat_result = gemini_service.chat_assistant(user_message, chat_history)
    return jsonify(chat_result), 200
