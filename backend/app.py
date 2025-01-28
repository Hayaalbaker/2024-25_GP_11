from flask import Flask, jsonify, request
from firebase_config import db
import random

app = Flask(__name__)

categories = ["Restaurant", "Park", "Shopping", "Edutainment"]

@app.route('/')
def home():
    return "Welcome to the AI Places Recommendation System!"

@app.route('/recommendations', methods=['POST'])
def recommend_places():

    user_preferences = request.json.get("preferences", [])
    
    if not user_preferences:
        return jsonify({"error": "No preferences provided"}), 400


    places_ref = db.collection('places')
    places_snapshot = places_ref.stream()

    recommendations = []


    for place in places_snapshot:
        place_data = place.to_dict()
        match_score = 0
        

        for preference in user_preferences:
            if preference in place_data['category']:
                match_score += 1 
        

        if match_score > 0:
            recommendations.append({
                "place_name": place_data["place_name"],
                "category": place_data["category"],
                "image_url": place_data.get("imageUrl", ""),
                "match_score": match_score
            })


    recommendations.sort(key=lambda x: x['match_score'], reverse=True)

    return jsonify(recommendations), 200

if __name__ == "__main__":
    app.run(debug=True)