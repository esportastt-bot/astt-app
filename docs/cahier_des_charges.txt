# Cahier des Charges - Application ASTT E-sport (V2)

## 1. Objectif de l'application
Créer une application mobile (iOS & Android) dédiée à la section e-sport "ASTT E-sport". Elle permet de suivre l'actualité, d'être notifié des lives Twitch et des annonces importantes, et de s'inscrire ponctuellement à des tournois via HelloAsso. L'application intègre un espace d'administration caché pour le staff.

## 2. Choix Techniques Validés
- **Technologie Mobile** : **Flutter**. Ce framework permet de coder une seule fois et d'obtenir une application ultra-fluide et native pour Android ET iOS. C'est parfait pour maximiser la compatibilité.
- **Backend & Base de données** : **Firebase**. Gestion des actualités en temps réel, authentification du staff, et envoi des notifications Push gratuitement.
- **Design System** : Thème Dark Mode (Fonds carbone/sombre), typographies futuristes/tech (Chakra Petch, Montserrat, Rajdhani) inspirées de votre overlay de stream. Couleurs d'accentuation : Bleu néon et Orange. Intégration du logo avec effet "constellation".

## 3. Fonctionnalités (Côté Utilisateur)
*Note : Aucun compte utilisateur n'est requis pour les visiteurs.*

- **🏠 Accueil Dynamique (Flux d'actualité)** : 
  - Affichage par défaut d'un message de bienvenue et des "Annonces" générales.
  - **Apparition dynamique** : Les tuiles "Live" et "Tournoi" n'apparaissent **que** lorsqu'elles sont actives. Si un live est sur le point d'être lancé, sa tuile se place automatiquement en tout premier (au-dessus des autres). L'accueil n'est ainsi jamais pollué.
- **🌐 Section Réseaux (Fusionnée)** : 
  - Remplacement des accès séparés par un bouton unique "Réseaux" dans la barre de navigation.
  - Au clic, un menu s'ouvre, donnant accès aux boutons "Rejoindre le Discord" et "Accéder à la chaîne Twitch".
- **🏆 Tournois (Ponctuels)** : 
  - Tuile de tournoi conditionnelle. Lorsqu'elle est activée, un bouton d'inscription redirige vers **HelloAsso**.
- **🔔 Notifications Push** : 
  - Réception d'alertes pour 3 catégories : "Lancement d'un Live Twitch", "Nouveau Tournoi", et "Annonce Générale".

## 4. Fonctionnalités (Côté Staff / Administrateur)
- **Accès Staff** : Bouton caché (ex: appui long sur le logo) ou page de connexion dédiée pour le staff.
- **Gestion in-app** :
  - Créer, modifier, supprimer une actualité ou une "Annonce".
  - Mettre en avant un tournoi avec son lien HelloAsso.
  - Bouton "Envoyer une notification Push" pour alerter tous les utilisateurs instantanément.

## 5. Ergonomie et Interface Imagée (UI/UX)
- **Ambiance** : Un fond sombre texturé (légère grille carbone ou constellation en arrière-plan abstrait). Des touches de lumière (glow) bleu et orange sur les bords ou derrière les éléments importants (comme vu sur votre écran d'attente).
- **Navigation** : Une barre de navigation en bas (Bottom Navigation Bar) translucide avec effet "Glassmorphism" (verre dépoli).
- **Animations** : Transitions fluides entre les onglets, effet de "pulsation" sur le bouton Twitch quand un live est détecté, apparition des cartes d'actualité en douceur au défilement.
- **Logo** : Le logo métallique sera placé en haut de l'écran d'accueil, avec un effet de particules/constellation subtil animé derrière lui en fond.

## 6. Prochaines Étapes
1. Validation de cette mise à jour.
2. (Optionnel) Création d'une maquette visuelle de l'interface.
3. Initialisation du projet Flutter et configuration de Firebase.
4. Développement de l'interface utilisateur.
