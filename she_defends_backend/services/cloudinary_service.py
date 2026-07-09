import cloudinary
import cloudinary.uploader
import logging
from config import Config

cloudinary_initialized = False
try:
    if Config.CLOUDINARY_CLOUD_NAME and Config.CLOUDINARY_API_KEY and Config.CLOUDINARY_API_SECRET:
        cloudinary.config(
            cloud_name=Config.CLOUDINARY_CLOUD_NAME,
            api_key=Config.CLOUDINARY_API_KEY,
            api_secret=Config.CLOUDINARY_API_SECRET,
            secure=True
        )
        cloudinary_initialized = True
        logging.info("Cloudinary configured successfully.")
    else:
        logging.warning("Cloudinary credentials missing. Bypassing upload calls with mock URLs.")
except Exception as e:
    logging.error(f"Failed to configure Cloudinary: {str(e)}")

class CloudinaryService:
    @staticmethod
    def upload_image(file_to_upload, folder="she_defends"):
        """
        Uploads an image file object to Cloudinary.
        If Cloudinary is not configured, returns a mock image URL.
        """
        if not cloudinary_initialized:
            # Return a default placeholder URL for development
            logging.info("Cloudinary mock upload: returning fallback placeholder.")
            return {
                "url": "https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=600&q=80",
                "public_id": "mock_report_id_123"
            }
            
        try:
            upload_result = cloudinary.uploader.upload(
                file_to_upload,
                folder=folder
            )
            return {
                "url": upload_result.get("secure_url"),
                "public_id": upload_result.get("public_id")
            }
        except Exception as e:
            logging.error(f"Cloudinary upload failed: {str(e)}")
            return {
                "url": "https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=600&q=80",
                "public_id": "error_fallback_id"
            }
