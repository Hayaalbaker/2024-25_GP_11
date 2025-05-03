import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from datetime import datetime
from copy import deepcopy

cred = credentials.Certificate(r"C:\Users\Afnan\Desktop\flutter\2024-25_GP_11\backend\localize-db046-firebase-adminsdk-a36y8-49f6a0c2f8 - Copy.json")
firebase_admin.initialize_app(cred)

app = Flask(__name__)
db = firestore.client()

def recommend_reviews(user_interests):
    try:
        print("📥 Fetching local guides with matching interests...")
        users_ref = db.collection('users').where('local_guide', '==', "yes").get()
        
        local_guide_data = []  # Store guide ID, match score, and matched interests

        for doc in users_ref:
            guide_data = doc.to_dict()
            guide_interests = guide_data.get('interests', [])

            user_interests = {interest.strip().lower() for interest in user_interests}
            guide_interests = {interest.strip().lower() for interest in guide_interests}

            # Find matched interests
            matched_interests = user_interests & guide_interests
            match_score = len(matched_interests) / len(user_interests) if user_interests else 0

            if match_score > 0:  # Only consider guides with at least one match
                local_guide_data.append((doc.id, match_score, matched_interests))  

                print(f"Match found: User interests: {user_interests} -> Guide interests: {guide_interests} | Matched: {matched_interests} | Score: {match_score}")

        # Sort guides by match score (higher match score guides come first)
        local_guide_data.sort(key=lambda x: x[1], reverse=True)

        # Convert to dictionary for quick lookup
        local_guide_scores = {guide_id: score for guide_id, score, _ in local_guide_data}
        local_guide_matched_interests = {guide_id: matched for guide_id, _, matched in local_guide_data}


        if not local_guide_data:
            print("⚠️ No relevant local guides found!")
            return []

        print("📥 Fetching places that match user interests...")
        places_ref = db.collection('places').get()
        places_data = [doc.to_dict() for doc in places_ref]
        places_df = pd.DataFrame(places_data)
        
        places_df['category'] = places_df['category'].fillna('Unknown').str.lower()
        places_df['subcategory'] = places_df['subcategory'].fillna('Unknown').str.lower()
        print(f"place -------: {places_df} ")


        
        matching_places = places_df[places_df['subcategory'].isin(user_interests) | places_df['category'].isin(user_interests)]
        matching_place_ids = matching_places['placeId'].tolist()
        # Create a dictionary mapping placeId to place name and subcategory
        # Drop duplicate placeId values, keeping the first occurrence
        places_df = places_df.drop_duplicates(subset='placeId', keep='first')

        # Create a dictionary mapping placeId to place name and subcategory
        place_info_dict = places_df.set_index('placeId')[['place_name', 'subcategory']].to_dict(orient='index')



        local_guide_ids = [guide_id for guide_id, _, _ in local_guide_data]  # Extract guide IDs

        print("📥 Fetching relevant reviews...")
        if len(local_guide_ids) < 30:
            reviews_ref = db.collection('Review').where('user_uid', 'in', local_guide_ids).get()
            reviews_data = [{**doc.to_dict(), "id": doc.id} for doc in reviews_ref]


         #   places_data = [{**doc.to_dict(), "id": doc.id} for doc in places_ref]
        else:
            batch_size = 30  
            reviews_data = []  

            
            for i in range(0, len(local_guide_ids), batch_size):
                batch_ids = local_guide_ids[i:i + batch_size]  
                
                reviews_ref = db.collection('Review').where('user_uid', 'in', batch_ids).get()
                
                reviews_data.extend([{**doc.to_dict(), "id": doc.id} for doc in reviews_ref])

        print(f"Total reviews fetched: {len(reviews_data)}")




        if not reviews_data:
            print("⚠️ No reviews found!")
            return []

        reviews_df = pd.DataFrame(reviews_data)
        reviews_df['Interests_match'] = reviews_df['user_uid'].apply(lambda uid: local_guide_scores.get(uid, 0))

        reviews_df['Matched_Interests'] = reviews_df['user_uid'].apply(lambda uid: 
            ", ".join(local_guide_matched_interests.get(uid, [])) if uid in local_guide_matched_interests else ""
        )




        reviews_df['Post_Date'] = pd.to_datetime(reviews_df['Post_Date'], errors='coerce')

        reviews_df['Post_Date_to_show']=deepcopy(reviews_df['Post_Date'])
        reviews_df['Like_count'] = pd.to_numeric(reviews_df['Like_count'], errors='coerce').fillna(0)
        
        reviews_df['user_uid'] = reviews_df['user_uid'].fillna('Unknown')
        #reviews_df['id'] = reviews_df.index
        required_columns = ['Interests_match', 'Matched_Interests', 'Review_Text', 'Like_count', 'Rating', 'Post_Date', 'placeId','similarity_score', 'weighted_score', 'user_uid','id']
        for col in required_columns:
            if col not in reviews_df.columns:
                reviews_df[col] = 'Unknown'
        
        reviews_df['place_match'] = reviews_df['placeId'].apply(lambda x: 1 if x in matching_place_ids else 0)

        # Add place_name and subcategory based on placeId
        reviews_df['place_name'] = reviews_df['placeId'].apply(lambda x: place_info_dict[x]['place_name'] if x in place_info_dict else "Unknown")
        reviews_df['subcategory'] = reviews_df['placeId'].apply(lambda x: place_info_dict[x]['subcategory'] if x in place_info_dict else "Unknown")

        
        print("📝 Calculating text similarity...")
        user_profile = " ".join(user_interests)
        all_texts = reviews_df['Review_Text'].tolist() + [user_profile]
        
        vectorizer = TfidfVectorizer()
        tfidf_matrix = vectorizer.fit_transform(all_texts)
        cosine_similarities = cosine_similarity(tfidf_matrix[-1], tfidf_matrix[:-1]).flatten()
        
        reviews_df['similarity_score'] = cosine_similarities
        
        min_date = reviews_df['Post_Date'].min()
        max_date = reviews_df['Post_Date'].max()

         
        reviews_df['Like_count'] = reviews_df['Like_count'] / reviews_df['Like_count'].max()



        
        if min_date == max_date:
            reviews_df['Post_Date'] = 1  
        else:
            reviews_df['Post_Date'] = (reviews_df['Post_Date'] - min_date) / (max_date - min_date)

                









   
        w_interest_match=0.4
        w_place_match = 0.3
        w_like = 0.1
        w_date = 0.05
        w_similarity = 0.05

        reviews_df['similarity_score'] = pd.to_numeric(reviews_df['similarity_score'], errors='coerce').fillna(0.0)
        reviews_df['place_match'] = pd.to_numeric(reviews_df['place_match'], errors='coerce').fillna(0.0)
        reviews_df['Like_count'] = pd.to_numeric(reviews_df['Like_count'], errors='coerce').fillna(0.0)
        reviews_df['Post_Date'] = pd.to_numeric(reviews_df['Post_Date'], errors='coerce').fillna(0.0)

        
        reviews_df['weighted_score'] = (
            w_interest_match * reviews_df['Interests_match'] + 
            w_place_match * reviews_df['place_match'] + 
            w_like * reviews_df['Like_count'] + 
            w_date * reviews_df['Post_Date'] + 
            w_similarity * reviews_df['similarity_score']
        )


        sorted_reviews = reviews_df.sort_values(by=['weighted_score'], ascending=[False])
        
        return sorted_reviews[['Interests_match', 'Matched_Interests', 'Review_Text', 'Like_count', 'Rating', 'Post_Date_to_show', 'placeId', 'similarity_score', 'weighted_score', 'user_uid','id']].to_dict(orient='records')

    
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
