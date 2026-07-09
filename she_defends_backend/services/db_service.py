from pymongo import MongoClient
from config import Config
import logging

class DBService:
    def __init__(self):
        try:
            self.client = MongoClient(Config.MONGO_URI)
            self.db = self.client.get_default_database()
            logging.info("Successfully connected to MongoDB.")
        except Exception as e:
            logging.error(f"Failed to connect to MongoDB: {str(e)}")
            # Fallback to localhost if default db is not resolved
            self.client = MongoClient("mongodb://localhost:27017/")
            self.db = self.client["she_defends"]

    # --- User Profile Methods ---
    def get_user_profile(self, uid):
        return self.db.users.find_one({"uid": uid}, {"_id": 0})

    def save_user_profile(self, uid, profile_data):
        profile_data["uid"] = uid
        result = self.db.users.update_one(
            {"uid": uid},
            {"$set": profile_data},
            upsert=True
        )
        return result.modified_count > 0 or result.upserted_id is not None

    # --- Symptom Checker Methods ---
    def add_symptom_log(self, uid, log_data):
        log_data["uid"] = uid
        result = self.db.health_history.insert_one(log_data)
        return str(result.inserted_id)

    def get_symptom_logs(self, uid):
        return list(self.db.health_history.find({"uid": uid}, {"_id": 0}).sort("timestamp", -1))

    # --- Medication Manager Methods (Sync) ---
    def sync_medications(self, uid, medications):
        # medications is a list of dicts
        self.db.medications.delete_many({"uid": uid})
        if medications:
            for med in medications:
                med["uid"] = uid
            self.db.medications.insert_many(medications)
        return True

    def get_medications(self, uid):
        return list(self.db.medications.find({"uid": uid}, {"_id": 0}))

    # --- Guardian Journey Methods ---
    def start_journey(self, uid, journey_data):
        journey_data["uid"] = uid
        journey_data["status"] = "active"
        result = self.db.journeys.insert_one(journey_data)
        return str(result.inserted_id)

    def update_journey_location(self, uid, journey_id, location_log):
        self.db.journeys.update_one(
            {"_id": journey_id, "uid": uid},
            {"$push": {"route_history": location_log}, "$set": {"current_location": location_log}}
        )

    def complete_journey(self, uid, journey_id, status="completed"):
        self.db.journeys.update_one(
            {"_id": journey_id, "uid": uid},
            {"$set": {"status": status}}
        )

    def get_journeys(self, uid):
        return list(self.db.journeys.find({"uid": uid}, {"_id": 0}).sort("timestamp", -1))

    # --- Wellness Mood Tracker Methods ---
    def add_mood_log(self, uid, mood_data):
        mood_data["uid"] = uid
        result = self.db.moods.insert_one(mood_data)
        return str(result.inserted_id)

    def get_mood_logs(self, uid, limit=30):
        return list(self.db.moods.find({"uid": uid}, {"_id": 0}).sort("timestamp", -1).limit(limit))

    # --- Journal Methods ---
    def save_journal_entry(self, uid, journal_data):
        journal_data["uid"] = uid
        result = self.db.journals.insert_one(journal_data)
        return str(result.inserted_id)

    def get_journal_entries(self, uid):
        return list(self.db.journals.find({"uid": uid}, {"_id": 0}).sort("timestamp", -1))

db_service = DBService()
