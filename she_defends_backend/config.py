import os
from dotenv import load_dotenv

# Load environment variables from .env file for local development
load_dotenv()

class Config:
    PORT = int(os.getenv("PORT", 5000))
    DEBUG = os.getenv("FLASK_DEBUG", "true").lower() == "true"
    
    # MongoDB Atlas Config
    MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/she_defends")
    
    # Firebase Admin SDK Credentials Config (JSON path or raw JSON string)
    FIREBASE_CREDS_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "")
    
    # Gemini API Config
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
    
    # Cloudinary Config
    CLOUDINARY_CLOUD_NAME = os.getenv("CLOUDINARY_CLOUD_NAME", "")
    CLOUDINARY_API_KEY = os.getenv("CLOUDINARY_API_KEY", "")
    CLOUDINARY_API_SECRET = os.getenv("CLOUDINARY_API_SECRET", "")
    
    # OpenAI & Groq fallback key configs
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
    GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
