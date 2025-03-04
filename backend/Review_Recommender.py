import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from datetime import datetime

cred = credentials.Certificate(r"C:\Users\Afnan\Desktop\flutter\2024-25_GP_11\localize-db046-firebase-adminsdk-a36y8-49f6a0c2f8 - Copy.json")
firebase_admin.initialize_app(cred)

app = Flask(__name__)
db = firestore.client()

def recommend_reviews(user_interests):
    try:
        print("📥 Fetching local guides with matching interests...")
        users_ref = db.collection('users').where('local_guide', '==', "yes").get()
        
        local_guide_ids = []
        for doc in users_ref:
            guide_data = doc.to_dict()
            guide_interests = guide_data.get('interests', [])
            user_interests = {interest.strip().lower() for interest in user_interests}
            guide_interests = {interest.strip().lower() for interest in guide_interests}

            user_interests_set = set(user_interests)  
            guide_interests_set = set(guide_interests)  




            if any(interest in user_interests for interest in guide_interests): 
                local_guide_ids.append(doc.id)
                print(f"Match found: User interests: {user_interests} -> Guide interests: {guide_interests}")

        if not local_guide_ids:
            print("⚠️ No relevant local guides found!")
            return []

        print("📥 Fetching places that match user interests...")
        places_ref = db.collection('places').get()
        places_data = [doc.to_dict() for doc in places_ref]
        places_df = pd.DataFrame(places_data)
        
        places_df['category'] = places_df['category'].fillna('Unknown').str.lower()
        places_df['subcategory'] = places_df['subcategory'].fillna('Unknown').str.lower()
        



        
        matching_places = places_df[places_df['subcategory'].isin(user_interests) | places_df['category'].isin(user_interests)]
        matching_place_ids = matching_places['placeId'].tolist()

        print("📥 Fetching relevant reviews...")
        if len(local_guide_ids) < 30:
            reviews_ref = db.collection('Review').where('user_uid', 'in', local_guide_ids).get()
            reviews_data = [doc.to_dict() for doc in reviews_ref]
        else:
            batch_size = 30  # Firestore 'IN' query limit
            reviews_data = []  # Store all reviews

            # Split `local_guide_ids` into chunks of 30
            for i in range(0, len(local_guide_ids), batch_size):
                batch_ids = local_guide_ids[i:i + batch_size]  # Get a batch of up to 30 IDs
                
                reviews_ref = db.collection('Review').where('user_uid', 'in', batch_ids).get()
                
                reviews_data.extend([doc.to_dict() for doc in reviews_ref])

        print(f"Total reviews fetched: {len(reviews_data)}")




        if not reviews_data:
            print("⚠️ No reviews found!")
            return []

        reviews_df = pd.DataFrame(reviews_data)
        reviews_df['Post_Date'] = pd.to_datetime(reviews_df['Post_Date'], errors='coerce')
        reviews_df['Like_count'] = reviews_df['Like_count'].fillna(0)
        
        required_columns = ['Review_Text', 'like_count', 'Rating', 'Post_Date', 'placeId']
        for col in required_columns:
            if col not in reviews_df.columns:
                reviews_df[col] = 'Unknown'
        
        reviews_df['place_match'] = reviews_df['placeId'].apply(lambda x: 1 if x in matching_place_ids else 0)
        
        print("📝 Calculating text similarity...")
        user_profile = " ".join(user_interests)
        all_texts = reviews_df['Review_Text'].tolist() + [user_profile]
        
        vectorizer = TfidfVectorizer()
        tfidf_matrix = vectorizer.fit_transform(all_texts)
        cosine_similarities = cosine_similarity(tfidf_matrix[-1], tfidf_matrix[:-1]).flatten()
        
        reviews_df['similarity_score'] = cosine_similarities
        
        sorted_reviews = reviews_df.sort_values(by=['similarity_score', 'place_match', 'like_count', 'Post_Date'], ascending=[False, False, False, False])
        
        return sorted_reviews[['Review_Text', 'like_count', 'Rating', 'Post_Date', 'placeId']].to_dict(orient='records')
    
    except Exception as e:
        print("❌ Error in `recommend_reviews`:", e)
        return []

@app.route('/api/recommendReviews', methods=['POST'])
def recommend_reviews_api():
    try:
        data = request.get_json()
        print("📥 Request received:", data)
        
        user_id = data.get("userId")
        if not user_id:
            return jsonify({'message': 'User ID is required'}), 400

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
        
        print("🚀 Generating review recommendations...")
        recommendations = recommend_reviews(user_interests)
        
        print("✅ Recommendations sent:", recommendations)
        return jsonify({'recommendations': recommendations}), 200

    except Exception as e:
        print("❌ Error in API:", e)
        return jsonify({'message': str(e)}), 500

if __name__ == "__main__":
    print("🚀 Server is running on `http://0.0.0.0:5000`")
    app.run(debug=True, host='0.0.0.0', port=5000)
