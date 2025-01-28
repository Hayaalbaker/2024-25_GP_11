import pandas as pd
import numpy as np
from sklearn.neighbors import NearestNeighbors


user_preferences = {
    "restaurantTypes": ["Indian Restaurant", "Pizza Restaurant"],
    "parkTypes": ["Water parks", "Family parks"],
    "shoppingTypes": ["Clothing store", "Jewellery store"],
    "edutainmentTypes": ["Football academy", "Art studio"]
}


places_data = pd.DataFrame({
    "place_name": ["Place A", "Place B", "Place C", "Place D"],
    "restaurantTypes": ["Indian Restaurant", "Pizza Restaurant", "Korean Restaurant", "Sushi Restaurant"],
    "parkTypes": ["Water parks", "Public parks", "Family parks", "Water parks"],
    "shoppingTypes": ["Clothing store", "Electronics store", "Furniture store", "Jewellery store"],
    "edutainmentTypes": ["Football academy", "Art studio", "Swimming academy", "Yoga studio"]
})

def recommend_places(user_preferences, places_data):

    preference_matrix = pd.DataFrame(np.zeros((len(places_data), len(user_preferences))), columns=user_preferences.keys())
    
    for index, row in places_data.iterrows():
        for category in user_preferences:
            if any(item in row[category] for item in user_preferences[category]):
                preference_matrix.at[index, category] = 1  
    
    model = NearestNeighbors(n_neighbors=3)
    model.fit(preference_matrix)

    distances, indices = model.kneighbors(preference_matrix)
    
    recommended_places = []
    for idx in indices:
        recommended_places.extend(places_data.iloc[idx]["place_name"])

    return recommended_places

recommended_places = recommend_places(user_preferences, places_data)
print("Recommended places:", recommended_places)