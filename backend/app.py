import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
import nltk
from nltk.stem import WordNetLemmatizer
from nltk.tokenize import word_tokenize
import zipfile
import os
from datetime import datetime
from math import ceil
from flask import make_response



nltk.download('punkt')
nltk.download('wordnet')


cred = credentials.Certificate(r"C:\flutterdev\flutterapps\2024-25_GP_11-main\localize-db046-firebase-adminsdk-a36y8-64508c72f2.json")
firebase_admin.initialize_app(cred)


app = Flask(__name__)  


db = firestore.client()


lemmatizer = WordNetLemmatizer()

def preprocess_text(text):
    tokens = word_tokenize(text.lower())  
    lemmatized_tokens = [lemmatizer.lemmatize(token, pos='v') for token in tokens]  
    lemmatized_tokens = [lemmatizer.lemmatize(token, pos='n') for token in lemmatized_tokens]  

    processed_text = " ".join(lemmatized_tokens)  
    print(f"🔍 Original: {text}")  
    print(f"✅ Processed: {processed_text}")  
    return processed_text

def get_time_diff_in_days(created_at):
    try:
        created_date = datetime.strptime(created_at, '%Y-%m-%d') 
        current_date = datetime.now()
        return (current_date - created_date).days  
    except Exception as e:
        return 0  

def recommend_places(user_interests):
    try:
        print("📥 Fetching places data from Firestore...")
        places_ref = db.collection('places').get()
        places_data = [{**doc.to_dict(), "id": doc.id} for doc in places_ref]

        if not places_data:
            print("⚠️ No data in places!")
            return []

        # 🔹 Normalize keys by stripping spaces
        for place in places_data:
            place_clean = {}
            for key, value in place.items():
                clean_key = key.strip()  # Remove extra spaces
                place_clean[clean_key] = value
            place.update(place_clean)

        places_df = pd.DataFrame(places_data)

        # 🔹 Clean data to handle NaN or invalid values
        places_df['place_name'] = places_df['place_name'].apply(lambda x: x if isinstance(x, str) and x.strip() else 'Unknown Place')
        places_df['description'] = places_df['description'].apply(lambda x: x if isinstance(x, str) and x.strip() else 'No description available')

        print("📊 Places Data Sample:")
        print(places_df[['place_name', 'description']].head(10))

        # 🔹 Ensure required columns exist
        required_columns = ['id', 'place_name', 'subcategory', 'imageUrl', 'category', 'description']
        for col in required_columns:
            if col not in places_df.columns:
                places_df[col] = 'Unknown'
                places_df['placeId'] = places_df['id'].where(places_df['id'].notna(), places_df.index.astype(str))
        
        # 🔹 Clean Data
        places_df['subcategory'] = places_df['subcategory'].fillna('Unknown').str.strip().str.lower()
        places_df['description'] = places_df['description'].apply(lambda x: preprocess_text(x) if isinstance(x, str) and x.strip() else "No description available")
        places_df['has_description'] = places_df['description'].apply(lambda x: 1 if x != "No description available" else 0)
        places_df['imageUrl'] = places_df['imageUrl'].fillna('Unknown')
        places_df['category'] = places_df['category'].fillna('Unknown').str.strip().str.lower()
        
        print("✅ Processed text for each place:")
        for index, row in places_df.iterrows():
            print(f"Place: {row['place_name']}, Processed Description: {row['description']}")

        if not user_interests:
            print("⚠️ User has no interests!")
            return []

        user_interests = [preprocess_text(interest.lower().strip()) for interest in user_interests]

        # 🔹 Mark places with subcategory match
        places_df['subcategory_match'] = places_df['subcategory'].apply(lambda x: 1 if x in user_interests else 0)

        # 🔹 Fetch reviews
        print("📥 Fetching reviews from Firestore...")
        reviews_ref = db.collection('Review').get()  
        reviews_data = [doc.to_dict() for doc in reviews_ref]
        
        if reviews_data:
            reviews_df = pd.DataFrame(reviews_data)
            reviews_summary = reviews_df.groupby('placeId').agg({
                'Rating': 'mean',
                'placeId': 'count'
            }).rename(columns={'placeId': 'review_count'}).reset_index()

            # Merge places with reviews using a left join to keep all places
            places_df = places_df.merge(reviews_summary, left_on='id', right_on='placeId', how='left')
        else:
            places_df['Rating'] = 0
            places_df['review_count'] = 0
        
        places_df['Rating'] = places_df['Rating'].fillna(0)
        places_df['review_count'] = places_df['review_count'].fillna(0)

        print("🔍 Processed User Interests:", user_interests)
        print("🔍 Places Descriptions:", places_df['description'].tolist())

        vectorizer = TfidfVectorizer(ngram_range=(1, 3), stop_words='english', min_df=1, token_pattern=r'\b\w+\b')
        
        # Convert places descriptions to TF-IDF
        places_tfidf = vectorizer.fit_transform(places_df['description'])  
        
        # Convert user interests to TF-IDF (flattened for a single "document")
        cosine_scores = []
        for interest in user_interests:
            user_tfidf = vectorizer.transform([interest])
            cosine_sim = cosine_similarity(user_tfidf, places_tfidf)
            cosine_scores.append(cosine_sim.flatten())
        
        places_df['cosine_similarity'] = np.max(np.array(cosine_scores), axis=0)

        places_df['normalized_rating'] = (places_df['Rating'] - places_df['Rating'].min()) / (places_df['Rating'].max() - places_df['Rating'].min())
        places_df['normalized_review_count'] = (places_df['review_count'] - places_df['review_count'].min()) / (places_df['review_count'].max() - places_df['review_count'].min())

        places_df['created_at_days'] = places_df['created_at'].apply(get_time_diff_in_days)

        places_df['final_score'] = (
            0.5 * places_df['subcategory_match'] +  
            0.01 * places_df['normalized_rating'] +  
            0.4 * places_df['cosine_similarity'] +  
            0.01 * places_df['normalized_review_count'] + 
            0.01 * places_df['created_at_days']  
        )

        sorted_places = places_df.sort_values(by='final_score', ascending=False)

        return sorted_places[['id', 'place_name', 'subcategory', 'description', 'Rating', 'review_count', 'imageUrl', 'category', 'cosine_similarity', 'final_score']].to_dict(orient='records')

    except Exception as e:
        print("❌ Error in `recommend_places`:", e)
        return []
@app.route('/api/receiveUserId', methods=['POST'])
def receive_user_id():
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
            recommendations = []
            response = make_response(jsonify({"recommendations": recommendations, "total": 0}), 200)
            response.headers["Content-Type"] = "application/json"
            return response

        user_interests = [interest.strip().lower() for interest in user_interests]

        print("🚀 Generating recommendations...")
        recommendations = recommend_places(user_interests)

        filter_category = data.get("filterCategory", "").strip().lower()
        if filter_category and filter_category != "all categories":
            print("📌 Filtering by category:", filter_category)
            valid_categories = [cat.strip() for cat in filter_category.split(",")]
            filtered = []
            for rec in recommendations:
                place_cat = rec.get("category", "").strip().lower()
                if any(cat in place_cat for cat in valid_categories):
                    filtered.append(rec)
            recommendations = filtered

      
        page = int(data.get("page", 1))
        limit = int(data.get("limit", 50))
        start = (page - 1) * limit
        end = start + limit
        paginated = recommendations[start:end]

        print("✅ Final recommendations count (paginated):", len(paginated))
        return jsonify({'recommendations': paginated, 'total': len(recommendations)}), 200  # إضافة total

    except Exception as e:
        print("❌ Error in API:", e)
        return jsonify({'message': str(e)}), 500


if __name__ == "__main__":
    print("🚀 Server is running on `http://0.0.0.0:5000`")
    app.run(host="0.0.0.0", port=5000, debug=True, threaded=True)
