from pymongo import MongoClient
from config import Config
import logging

class MockCursor:
    def __init__(self, data):
        self.data = data

    def sort(self, key, direction=-1):
        try:
            self.data.sort(key=lambda x: x.get(key, ""), reverse=(direction == -1))
        except Exception:
            pass
        return self

    def __iter__(self):
        return iter(self.data)

    def __getitem__(self, index):
        return self.data[index]

class MockCollection:
    def __init__(self, name):
        self.name = name
        self.data = []

    def find_one(self, filter, projection=None):
        for item in self.data:
            match = True
            for k, v in filter.items():
                if item.get(k) != v:
                    match = False
                    break
            if match:
                res = dict(item)
                if projection:
                    for k in list(res.keys()):
                        if projection.get(k) == 0:
                            res.pop(k, None)
                return res
        return None

    def find(self, filter=None, projection=None):
        res_list = []
        filter = filter or {}
        for item in self.data:
            match = True
            for k, v in filter.items():
                if item.get(k) != v:
                    match = False
                    break
            if match:
                res = dict(item)
                if projection:
                    for k in list(res.keys()):
                        if projection.get(k) == 0:
                            res.pop(k, None)
                res_list.append(res)
        return MockCursor(res_list)

    def insert_one(self, document):
        import uuid
        if "_id" not in document:
            document["_id"] = uuid.uuid4().hex
        self.data.append(dict(document))
        class Result:
            inserted_id = document["_id"]
        return Result()

    def update_one(self, filter, update, upsert=False):
        set_data = update.get("$set", {})
        found = False
        for item in self.data:
            match = True
            for k, v in filter.items():
                if item.get(k) != v:
                    match = False
                    break
            if match:
                item.update(set_data)
                found = True
                break
        if not found and upsert:
            new_item = dict(filter)
            new_item.update(set_data)
            self.data.append(new_item)
        class Result:
            modified_count = 1 if found else 0
            upserted_id = None
        return Result()

    def delete_one(self, filter):
        found_idx = -1
        for idx, item in enumerate(self.data):
            match = True
            for k, v in filter.items():
                if item.get(k) != v:
                    match = False
                    break
            if match:
                found_idx = idx
                break
        if found_idx != -1:
            self.data.pop(found_idx)
            class Result:
                deleted_count = 1
            return Result()
        class Result:
            deleted_count = 0
        return Result()

    def delete_many(self, filter):
        self.data = [item for item in self.data if not all(item.get(k) == v for k, v in filter.items())]
        class Result:
            deleted_count = 1
        return Result()

    def insert_many(self, documents):
        for doc in documents:
            self.insert_one(doc)
        return True

class MockDatabase:
    def __init__(self):
        self.users = MockCollection("users")
        self.health_history = MockCollection("health_history")
        self.medications = MockCollection("medications")
        self.journals = MockCollection("journals")
        self.contacts = MockCollection("contacts")
        self.recordings = MockCollection("recordings")

class DBService:
    def __init__(self):
        # 1. Try MongoDB Atlas (with invalid certificates bypass and connection ping test)
        try:
            logging.info("Connecting to MongoDB Atlas...")
            self.client = MongoClient(
                Config.MONGO_URI, 
                tlsAllowInvalidCertificates=True, 
                serverSelectionTimeoutMS=3000
            )
            self.client.admin.command('ping')
            try:
                self.db = self.client.get_default_database()
            except Exception:
                self.db = self.client["she_defends"]
            logging.info("Successfully connected to MongoDB Atlas.")
            return
        except Exception as e:
            logging.error(f"MongoDB Atlas connection failed: {str(e)}")

        # 2. Try Local MongoDB (with invalid certificates bypass)
        try:
            logging.info("Attempting Local MongoDB connection...")
            self.client = MongoClient("mongodb://localhost:27017/", serverSelectionTimeoutMS=2000)
            self.client.admin.command('ping')
            self.db = self.client["she_defends"]
            logging.info("Successfully connected to Local MongoDB.")
            return
        except Exception as e:
            logging.error(f"Local MongoDB connection failed: {str(e)}")

        # 3. Fallback to In-Memory Decoy DB
        logging.warning("Falling back to In-Memory Decoy Database.")
        self.db = MockDatabase()

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

    # --- Emergency Contacts Methods ---
    def get_emergency_contacts(self, uid):
        return list(self.db.contacts.find({"uid": uid}, {"_id": 0}))

    def save_emergency_contact(self, uid, contact_data):
        import uuid
        contact_data["uid"] = uid
        if "id" not in contact_data or not contact_data["id"]:
            contact_data["id"] = uuid.uuid4().hex
        
        self.db.contacts.update_one(
            {"uid": uid, "id": contact_data["id"]},
            {"$set": contact_data},
            upsert=True
        )
        return contact_data["id"]

    def delete_emergency_contact(self, uid, contact_id):
        result = self.db.contacts.delete_one({"uid": uid, "id": contact_id})
        return result.deleted_count > 0

    # --- Audio Recordings Methods ---
    def add_emergency_recording(self, uid, recording_data):
        recording_data["uid"] = uid
        result = self.db.recordings.insert_one(recording_data)
        return str(result.inserted_id)

    def get_emergency_recordings(self, uid):
        return list(self.db.recordings.find({"uid": uid}, {"_id": 0}).sort("timestamp", -1))

db_service = DBService()
