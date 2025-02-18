import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Load Firebase data
cred = credentials.Certificate(r"C:\flutterdev\flutterapps\2024-25_GP_11-main\localize-db046-firebase-adminsdk-a36y8-64508c72f2.json")
firebase_admin.initialize_app(cred)

app = Flask(__name__)
db = firestore.client()

# 🔹 Related categories map
related_categories = {
    "pizza restaurant": ["italian restaurant"],
    "italian restaurant": ["pizza restaurant"],
    "sushi restaurant": ["seafood restaurant"],  
    "seafood restaurant": ["sushi restaurant"],
}

# ✅ Enhanced recommendation function
def recommend_places(user_interests):
    try:
        print("📥 Fetching places data from Firestore...")
        places_ref = db.collection('places').get()  # ⬅️ Replace `stream()` with `get()`
        places_data = [{**doc.to_dict(), "id": doc.id} for doc in places_ref]
        if not places_data:
            print("⚠️ No data in places!")
            return []
        
        places_df = pd.DataFrame(places_data)

        # 🔹 Ensure required columns
        required_columns = ['id', 'place_name', 'subcategory', 'imageUrl', 'category']
        for col in required_columns:
            if col not in places_df.columns:
                places_df[col] = 'Unknown'

        # 🔹 Data processing
        places_df['subcategory'] = places_df['subcategory'].fillna('Unknown').str.strip().str.lower()
        places_df['imageUrl'] = places_df['imageUrl'].fillna('Unknown')
        places_df['category'] = places_df['category'].fillna('Unknown').str.strip().str.lower()

        if not user_interests:
            print("⚠️ User has no interests!")
            return []

        user_interests = [interest.lower().strip() for interest in user_interests]
        user_profile = " ".join(user_interests)

        # 🔹 Calculate similarity
        all_texts = places_df['subcategory'].tolist() + [user_profile]
        vectorizer = TfidfVectorizer()
        tfidf_matrix = vectorizer.fit_transform(all_texts)
        cosine_similarities = cosine_similarity(tfidf_matrix[-1], tfidf_matrix[:-1]).flatten()

        places_df['primary_similarity'] = places_df['subcategory'].apply(lambda x: 1 if x in user_interests else 0)
        places_df['secondary_similarity'] = places_df['subcategory'].apply(
            lambda x: 1 if any(x in related_categories.get(interest, []) for interest in user_interests) else 0
        )

        # 📥 Fetch reviews
        print("📥 Fetching reviews from Firestore...")
        reviews_ref = db.collection('Review').get()  # ⬅️ Replace `stream()` with `get()`
        reviews_data = [doc.to_dict() for doc in reviews_ref]
        
        if reviews_data:
            reviews_df = pd.DataFrame(reviews_data)
            reviews_summary = reviews_df.groupby('placeId').agg({
                'Rating': 'mean',
                'placeId': 'count'
            }).rename(columns={'placeId': 'review_count'}).reset_index()

            places_df = places_df.merge(reviews_summary, left_on='id', right_on='placeId', how='left')
        else:
            places_df['Rating'] = 0
            places_df['review_count'] = 0
        
        places_df['Rating'] = places_df.get('Rating', 0).fillna(0)
        places_df['review_count'] = places_df.get('review_count', 0).fillna(0)

        # 🔹 Sort places
        primary_matches = places_df[places_df['primary_similarity'] > 0]
        secondary_matches = places_df[(places_df['primary_similarity'] == 0) & (places_df['secondary_similarity'] > 0)]
        primary_matches = primary_matches.sort_values(by=['Rating', 'review_count'], ascending=[False, False])
        secondary_matches = secondary_matches.sort_values(by=['Rating', 'review_count'], ascending=[False, False])

        sorted_places = pd.concat([primary_matches, secondary_matches])

        return sorted_places[['place_name', 'subcategory', 'Rating', 'review_count', 'imageUrl', 'category']].to_dict(orient='records')

    except Exception as e:
        print("❌ Error in `recommend_places`:", e)
        return []

# ✅ API to receive `userId`
@app.route('/api/receiveUserId', methods=['POST'])
def receive_user_id():
    try:
        data = request.get_json()
        print("📥 Request received:", data)
        
        user_id = data.get("userId")
        if not user_id:
            return jsonify({'message': 'User ID is required'}), 400

        # 🔹 Fetch user data
        user_ref = db.collection('users').document(user_id).get()
        
        if not user_ref.exists:
            print("⚠️ User not found!")
            return jsonify({'message': 'User not found'}), 404
        
        user_data = user_ref.to_dict()
        user_interests = user_data.get('interests', [])
        if not user_interests:
            print("⚠️ User has no interests registered!")
            return jsonify({'recommendations': []}), 200

        user_interests = [interest.strip().lower() for interest in user_interests]
        
        # 🔹 Fetch recommendations
        print("🚀 Generating recommendations...")
        recommendations = recommend_places(user_interests)
        
        print("✅ Recommendations sent:", recommendations)
        return jsonify({'recommendations': recommendations}), 200

    except Exception as e:
        print("❌ Error in API:", e)
        return jsonify({'message': str(e)}), 500

# ✅ Run the server
if __name__ == "__main__":
    print("🚀 Server is running on `http://0.0.0.0:5000`")
    app.run(debug=True, host='0.0.0.0', port=5000)
