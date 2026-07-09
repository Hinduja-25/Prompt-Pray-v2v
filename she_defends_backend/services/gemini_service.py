import os
import json
import logging
import google.generativeai as genai
from config import Config

# Configure Gemini API
gemini_initialized = False
try:
    if Config.GEMINI_API_KEY:
        genai.configure(api_key=Config.GEMINI_API_KEY)
        gemini_initialized = True
        logging.info("Gemini API configured successfully.")
    else:
        logging.warning("Gemini API Key missing. Bypassing to mock AI engine.")
except Exception as e:
    logging.error(f"Failed to configure Gemini API: {str(e)}")

class GeminiService:
    def __init__(self):
        self.model_name = "gemini-2.5-flash"
        if gemini_initialized:
            self.model = genai.GenerativeModel(self.model_name)

    # --- 1. AI Symptom Checker ---
    def analyze_symptoms(self, symptoms_text):
        prompt = f"""
        You are an empathetic medical assistant for a women's health and wellness app named SheDefends.
        Analyze the following symptom description: "{symptoms_text}"
        
        Provide a structured assessment in JSON format. Do not write any explanations before or after the JSON.
        The JSON must contain:
        - "possible_conditions": list of 2-3 common possible causes/conditions (e.g. "Tension Headache", "Dehydration", "Migraine").
        - "urgency_level": Must be exactly one of "Low" (self-care suggested), "Medium" (consult a clinic/physician), or "High" (immediate emergency care needed).
        - "suggestions": list of 3-4 simple, actionable self-care suggestions (e.g., "Hydrate", "Rest in a quiet room").
        - "warning_signs": list of 2-3 severe symptoms that require immediate medical attention (e.g. "vision changes", "loss of balance").
        - "disclaimer": A standard medical disclaimer emphasizing that this is NOT a diagnosis and you should see a doctor.
        
        Return ONLY valid JSON.
        """
        
        if not gemini_initialized:
            return self._mock_symptom_analysis(symptoms_text)
            
        try:
            response = self.model.generate_content(prompt)
            # Clean up markdown formatting if any
            content = response.text.strip()
            if content.startswith("```json"):
                content = content.replace("```json", "").replace("```", "").strip()
            return json.loads(content)
        except Exception as e:
            logging.error(f"Gemini API call failed for symptoms: {str(e)}")
            return self._mock_symptom_analysis(symptoms_text)

    # --- 2. Journal Theme Analyzer ---
    def analyze_journal_entry(self, entry_text):
        prompt = f"""
        You are a mental health assistant analyzing a journal entry.
        Read the following entry: "{entry_text}"
        
        Extract 1 or 2 recurring themes or psychological insights.
        Provide the output in JSON format (do not include markdown ticks or prefix explanations).
        The JSON must contain a "themes" key which maps to a list of objects. Each object has:
        - "label": A short title of the theme (e.g. "Work Stress", "Better Sleep", "Anxiety Pattern").
        - "status": A short tag (e.g., "3 entries", "Improved", "Needs attention").
        - "summary": A brief supportive sentence summarizing what is mentioned and correlating it with mental wellness.
        
        Return ONLY valid JSON.
        """
        
        if not gemini_initialized:
            return self._mock_journal_analysis(entry_text)
            
        try:
            response = self.model.generate_content(prompt)
            content = response.text.strip()
            if content.startswith("```json"):
                content = content.replace("```json", "").replace("```", "").strip()
            return json.loads(content)
        except Exception as e:
            logging.error(f"Gemini API call failed for journal analysis: {str(e)}")
            return self._mock_journal_analysis(entry_text)

    # --- 3. Empathetic Chatbot Assistant & Router ---
    def chat_assistant(self, user_message, chat_history=[]):
        # chat_history format: list of dicts with role ("user" or "model") and parts (string)
        # We will format it for Gemini
        system_instruction = """
        You are the intelligent chatbot assistant for SheDefends, an personal safety, health, and wellness app for women.
        Your tone is warm, professional, supportive, and protective. Keep answers relatively concise and highly actionable.
        
        Crucially, detect if the user's inquiry aligns with one of the app's special modules:
        1. Health Module (symptoms, headache, fever, cramps, medication, doctor) -> Action: recommend accessing the 'Health Module' or 'Symptom Checker'. Set route to "/health/symptoms".
        2. Safety Module (walking home, danger, followed, travel, maps, location) -> Action: recommend 'Guardian Mode' or 'SOS'. Set route to "/safety/guardian".
        3. Wellness Module (stressed, anxious, sad, journal, mood, sleep, meditate) -> Action: recommend logging mood, journaling, or starting a guided session. Set route to "/wellness/meditate".
        4. SOS Emergency (emergency, help now, call police, in danger) -> Action: recommend immediate SOS button trigger. Set route to "/safety/sos".
        
        You must format your response as JSON with two keys:
        - "response": Your empathetic, helpful textual answer.
        - "route": The routing tag if applicable ("/health/symptoms", "/safety/guardian", "/wellness/meditate", "/safety/sos") or null if it's general chat.
        
        Return ONLY valid JSON.
        """
        
        if not gemini_initialized:
            return self._mock_chat_assistant(user_message)
            
        try:
            # We construct a single prompt with system instructions, history, and message
            history_text = ""
            for turn in chat_history[-6:]:  # limit history
                role = "User" if turn.get("role") == "user" else "Assistant"
                history_text += f"{role}: {turn.get('content', '')}\n"
                
            prompt = f"{system_instruction}\n\nChat History:\n{history_text}\nUser: {user_message}\nAssistant:"
            response = self.model.generate_content(prompt)
            content = response.text.strip()
            if content.startswith("```json"):
                content = content.replace("```json", "").replace("```", "").strip()
            return json.loads(content)
        except Exception as e:
            logging.error(f"Gemini API call failed for chatbot: {str(e)}")
            return self._mock_chat_assistant(user_message)

    # --- Local Mock AI Engines (Resiliency Fallbacks) ---
    def _mock_symptom_analysis(self, text):
        text_lower = text.lower()
        if "headache" in text_lower or "migraine" in text_lower:
            return {
                "possible_conditions": ["Tension Headache", "Dehydration", "Migraine"],
                "urgency_level": "Low",
                "suggestions": [
                    "Drink 500ml of water immediately.",
                    "Rest in a quiet, dark room for 30 minutes.",
                    "Apply a cool compress to your forehead or neck."
                ],
                "warning_signs": [
                    "Sudden, severe 'thunderclap' pain",
                    "Headache accompanied by stiff neck, fever, or confusion",
                    "Numbness, weakness, or vision changes"
                ],
                "disclaimer": "Medical Disclaimer: This is a simulated assessment and not a professional diagnosis. If symptoms persist or worsen, please consult a medical practitioner."
            }
        elif "fever" in text_lower or "body pain" in text_lower or "chills" in text_lower:
            return {
                "possible_conditions": ["Viral Fever", "Influenza", "Dehydration"],
                "urgency_level": "Medium",
                "suggestions": [
                    "Monitor body temperature regularly using a thermometer.",
                    "Stay well-hydrated with water, broths, or electrolyte solutions.",
                    "Get plenty of rest and take over-the-counter antipyretics if advised by a doctor."
                ],
                "warning_signs": [
                    "Fever exceeding 103°F (39.4°C) that doesn't respond to medication",
                    "Difficulty breathing or chest tightness",
                    "Severe headache or neck stiffness"
                ],
                "disclaimer": "Medical Disclaimer: This is a mock analysis for preview. If symptoms are severe or fever persists beyond 3 days, seek professional medical attention immediately."
            }
        else:
            return {
                "possible_conditions": ["General Fatigue", "Mild Stress Reaction"],
                "urgency_level": "Low",
                "suggestions": [
                    "Ensure you are getting at least 7-8 hours of sleep.",
                    "Incorporate light stretching or a 10-minute walk into your day.",
                    "Take regular screen breaks and practice deep breathing."
                ],
                "warning_signs": [
                    "Persistent unexplained fatigue lasting over 2 weeks",
                    "Unexplained weight loss or severe muscle weakness"
                ],
                "disclaimer": "Medical Disclaimer: This simulation cannot replace a medical evaluation. In case of doubt, seek clinical care."
            }

    def _mock_journal_analysis(self, text):
        text_lower = text.lower()
        themes = []
        if any(w in text_lower for w in ["stress", "work", "deadline", "busy", "exam", "job"]):
            themes.append({
                "label": "Work Stress",
                "status": "3 entries",
                "summary": "You've mentioned tight deadlines and busy schedules three times this week. Consider scheduling short, scheduled pauses."
            })
        if any(w in text_lower for w in ["sleep", "tired", "insomnia", "bed", "rest"]):
            themes.append({
                "label": "Better Sleep",
                "status": "Improved",
                "summary": "Your entries suggest a positive correlation between winding down without screens and falling asleep faster."
            })
        if not themes:
            themes.append({
                "label": "Self-Reflection",
                "status": "Logged",
                "summary": "Your entry expresses active self-awareness. Taking time to process feelings daily fosters resilience."
            })
        return {"themes": themes}

    def _mock_chat_assistant(self, message):
        msg_lower = message.lower()
        if any(w in msg_lower for w in ["headache", "fever", "cramps", "sick", "pain", "symptom"]):
            return {
                "response": "I'm sorry to hear that you're not feeling well. I've noted that you might be dealing with some symptoms. I strongly recommend opening our Symptom Checker in the Health section to get a preliminary assessment and self-care steps.",
                "route": "/health/symptoms"
            }
        elif any(w in msg_lower for w in ["danger", "follow", "scared", "walk", "home", "night", "travel"]):
            return {
                "response": "Your safety is my top priority. If you are walking somewhere or traveling, please start Guardian Mode. It will monitor your live GPS location, track your ETA, and prompt you to check in to make sure you're safe.",
                "route": "/safety/guardian"
            }
        elif any(w in msg_lower for w in ["anxious", "stressed", "sad", "worry", "cry", "nervous"]):
            return {
                "response": "Take a deep breath. You are not alone, and it is okay to feel this way. I recommend visiting the Wellness tab. We have a simple Mood Tracker and guided breathing sessions that might help ease your mind.",
                "route": "/wellness/meditate"
            }
        elif any(w in msg_lower for w in ["emergency", "sos", "police", "call helper", "help me"]):
            return {
                "response": "Please stay calm. If you are in immediate danger, swipe the SOS button right away to alert your emergency contacts and share your live location.",
                "route": "/safety/sos"
            }
        else:
            return {
                "response": "Hello! I am your SheDefends companion. I'm here to support you with your health, safety tracking, and wellness goals. How can I help you today?",
                "route": None
            }

gemini_service = GeminiService()
