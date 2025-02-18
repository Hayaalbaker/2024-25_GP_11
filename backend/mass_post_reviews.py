import random
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

cred = credentials.Certificate("backend/localize-db046-firebase-adminsdk-a36y8-3b9b0004fd.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

users_ref = db.collection('users')
users_docs = users_ref.stream()
users = [{'id': doc.id, 'name': doc.to_dict().get('Name', 'Unknown')} for doc in users_docs]

places_ref = db.collection('places')
places_docs = places_ref.stream()
places = [{'id': doc.id, 'name': doc.to_dict().get('place_name', 'Unknown'), 'category': doc.to_dict().get('category', 'general')} for doc in places_docs]

if not users or not places:
    print("❌ No users or places found!")
    exit()

review_texts = {
    "restaurant": {
        1: [
            "Avoid this place at all costs. Terrible food and even worse service.",
            "Food was completely burnt. How do you mess up pasta?",
            "Never coming back! Took an hour to get cold, tasteless food."
        ],
        2: [
            "Overpriced and underwhelming. Small portions and bland flavors.",
            "Nothing special. Expected better quality for the price.",
            "Service was slow, and the food was just okay."
        ],
        3: [
            "Decent food, but nothing memorable. Wouldn't go out of my way to eat here again.",
            "Good flavors, but portion sizes were a little small.",
            "Average experience—some dishes were great, others not so much."
        ],
        4: [
            "Great atmosphere and tasty food! Would recommend for a casual dinner.",
            "Loved the ambiance! The staff were super friendly and the food was great.",
            "Good food, reasonable prices. Will be coming back!"
        ],
        5: [
            "Absolutely incredible! Best steak I’ve ever had. Highly recommended!",
            "10/10 experience! Amazing food, friendly staff, and beautiful presentation.",
            "I could eat here every day! Everything was just perfect."
        ]
    },
    "park": {
        1: [
            "Completely neglected! Dirty benches and garbage everywhere.",
            "Would not recommend—felt unsafe and poorly maintained.",
            "Awful experience. Too noisy, unclean, and no proper seating areas."
        ],
        2: [
            "Could be better with more maintenance and cleaner facilities.",
            "Not a great park. Lacking shade and has too much litter.",
            "Had potential, but not well-maintained. Needs improvement."
        ],
        3: [
            "Nice enough for a short walk, but nothing special.",
            "A decent spot for jogging, but not a lot of green areas.",
            "Okay place to sit and relax, but not much to do."
        ],
        4: [
            "Beautiful place to unwind and read a book.",
            "Loved the walking trails! A great place to spend an afternoon.",
            "Peaceful, clean, and perfect for a family outing."
        ],
        5: [
            "One of the best parks I’ve visited! So relaxing and well-kept.",
            "Perfect for picnics and long strolls. Just wonderful!",
            "Absolutely stunning! Great views, clean paths, and lots of open space."
        ]
    },
    "shopping": {
        1: [
            "Horrible experience. Staff was rude, and everything was overpriced.",
            "Limited variety, no customer service, and just a waste of time.",
            "Would not recommend. The products were either broken or overpriced."
        ],
        2: [
            "Not much to choose from. Very few good stores.",
            "Crowded and overpriced. Expected better deals.",
            "The store layout was confusing, and there wasn’t much variety."
        ],
        3: [
            "Some nice shops, but nothing extraordinary.",
            "Good selection but prices were a little high.",
            "Average mall. Decent shopping options but nothing unique."
        ],
        4: [
            "Really enjoyed shopping here! Lots of good brands.",
            "Great selection, good prices, and friendly staff.",
            "Nice experience! The mall was clean and well-organized."
        ],
        5: [
            "One of the best malls I’ve been to! Great deals and amazing stores.",
            "Fantastic shopping experience! Found everything I needed.",
            "Loved it! Perfect mix of luxury and affordable shopping."
        ]
    },
    "edutainment": {
        1: [
            "A complete waste of time. Nothing engaging or educational.",
            "Felt like a scam. Not worth the entrance fee.",
            "Boring and poorly organized. Would not recommend."
        ],
        2: [
            "Had some interesting parts, but not very interactive.",
            "Not as fun as I expected. Needs more engaging activities.",
            "Mediocre experience. Some things were cool, but overall underwhelming."
        ],
        3: [
            "Some good exhibits, but could be better organized.",
            "Decent experience. Good for kids, but adults might get bored.",
            "Nice for a first-time visit, but not exciting enough to return."
        ],
        4: [
            "Really fun and informative! Perfect for a family trip.",
            "Great place for kids to learn and play!",
            "Well-organized and interactive. Had a great time!"
        ],
        5: [
            "Absolutely amazing! Super fun and educational.",
            "Loved every part of it! Engaging and well-thought-out exhibits.",
            "Best learning experience I’ve ever had! So much fun!"
        ]
    },
    "general": {
        1: [
            "Very disappointing. Not worth the trip.",
            "Nothing good about this place. Total waste of time.",
            "Would not visit again. Poorly maintained and boring."
        ],
        2: [
            "Meh. Not great, not terrible. Just very average.",
            "Lacking in quality, could use some upgrades.",
            "Needs improvement, but not the worst experience."
        ],
        3: [
            "Pretty average experience overall.",
            "Not bad, but nothing to rave about.",
            "It was okay. Some good, some bad."
        ],
        4: [
            "Enjoyed my visit! Would recommend it to friends.",
            "Nice and well-organized. Good experience overall.",
            "Would come back! Pleasant atmosphere."
        ],
        5: [
            "Amazing experience! Everything was perfect.",
            "Loved it! Had such a fantastic time.",
            "Highly recommend! A must-visit place."
        ]
    }
}

def get_review_by_category(category, rating):
    return random.choice(review_texts.get(category, review_texts["general"])[rating])

# 50 reviews will be generated
review_count = 50

for _ in range(review_count): 
    randomUser = random.choice(users)
    randomPlace = random.choice(places)
    
    placeCategory = randomPlace.get("category", "general")
    randomRating = random.choices([1, 2, 3, 4, 5], weights=[5, 10, 20, 30, 35])[0]  
    randomReviewText = get_review_by_category(placeCategory, randomRating) 

    db.collection('Review').add({
        'Review_Text': randomReviewText,
        'user_uid': randomUser['id'],
        'placeId': randomPlace['id'],
        'Rating': randomRating,
        'Post_Date': datetime.now(),
        'Like_count': [],
    })

    print(f"✅ Review added: {randomUser['name']} → {randomPlace['name']} ({placeCategory}) | {randomRating}⭐ - {randomReviewText}")

print("🎉 Mass review posting completed!")