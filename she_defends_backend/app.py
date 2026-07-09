import logging
from flask import Flask, jsonify
from flask_cors import CORS
from config import Config

# Import blueprints
from routes.auth import auth_bp
from routes.health import health_bp
from routes.safety import safety_bp
from routes.wellness import wellness_bp
from routes.assistant import assistant_bp

# Set up logging configuration
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # Configure CORS for mobile clients
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    
    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(health_bp, url_prefix="/api/health")
    app.register_blueprint(safety_bp, url_prefix="/api/safety")
    app.register_blueprint(wellness_bp, url_prefix="/api/wellness")
    app.register_blueprint(assistant_bp, url_prefix="/api/assistant")
    
    # Root Health Check Route
    @app.route("/", methods=["GET"])
    def index():
        return jsonify({
            "status": "online",
            "service": "SheDefends Backend Service API",
            "version": "1.0.0"
        }), 200
        
    # Global Error Handlers
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Resource not found"}), 404
        
    @app.errorhandler(500)
    def internal_error(e):
        logging.error(f"Internal server error: {str(e)}")
        return jsonify({"error": "Internal server error occurred"}), 500
        
    return app

app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=Config.PORT, debug=Config.DEBUG)
