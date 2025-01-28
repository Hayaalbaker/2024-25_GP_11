import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate('localize-db046-firebase-adminsdk-a36y8-3b9b0004fd.json')
firebase_admin.initialize_app(cred)

db = firestore.client()