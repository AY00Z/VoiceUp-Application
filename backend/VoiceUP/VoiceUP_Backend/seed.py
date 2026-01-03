from app import app
from models import db, User, Conversation

def seed_data():
    with app.app_context():
        # 1. Nettoyage (Optionnel : à ne faire que si tu veux repartir de zéro)
        # db.drop_all()
        # db.create_all()

        print("Initialisation des contacts fictifs...")

        # 2. Récupérer ou créer l'utilisateur principal (Toi)
        me = User.query.filter_by(name="Moi-même").first()
        if not me:
            me = User(name="Moi-même", avatarUrl="https://api.dicebear.com/7.x/avataaars/svg?seed=me")
            db.session.add(me)
            db.session.commit()
            print("  - Utilisateur 'Moi-même' créé")
        else:
            print(f"  - Utilisateur 'Moi-même' existe déjà (ID: {me.id})")
        
        # 3. Récupérer ou créer les 5 contacts fictifs (VoiceUP Prototype)
        contact_names = ["Amina", "Yassine", "Sonia", "Karim", "Léa"]
        contacts = []
        
        for name in contact_names:
            contact = User.query.filter_by(name=name).first()
            if not contact:
                avatar_url = f"https://api.dicebear.com/7.x/avataaars/svg?seed={name}"
                contact = User(name=name, avatarUrl=avatar_url)
                db.session.add(contact)
                db.session.commit()
                print(f"  - Contact '{name}' créé")
            else:
                print(f"  - Contact '{name}' existe déjà (ID: {contact.id})")
            contacts.append(contact)

        # 4. Création d'une conversation pour chaque contact (si elle n'existe pas déjà)
        print("\nCréation des conversations avec tous les contacts...")
        conversations_created = 0
        conversations_existing = 0
        
        for contact in contacts:
            # Vérifier si une conversation existe déjà entre "Moi-même" et ce contact
            existing_conv = None
            for conv in me.conversations:
                if contact in conv.users and len(conv.users) == 2:
                    existing_conv = conv
                    break
            
            if existing_conv:
                print(f"  - Conversation avec {contact.name} existe déjà (ID: {existing_conv.id})")
                conversations_existing += 1
            else:
                # Créer une nouvelle conversation
                conv = Conversation(title=contact.name)
                conv.users.append(me)
                conv.users.append(contact)
                db.session.add(conv)
                db.session.commit()
                print(f"  - Conversation créée avec {contact.name} (ID: {conv.id})")
                conversations_created += 1

        print("\n" + "=" * 60)
        print("Base de données mise à jour avec succès !")
        print(f"ID de 'Moi-même' : {me.id}")
        print(f"Conversations créées : {conversations_created}")
        print(f"Conversations existantes : {conversations_existing}")
        print(f"Total de conversations : {conversations_created + conversations_existing}")
        print(f"Contacts disponibles : {', '.join([c.name for c in contacts])}")
        print("=" * 60)

if __name__ == '__main__':
    seed_data()