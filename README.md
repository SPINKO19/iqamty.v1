<div align="center">
  <img src="assets/logo/app_icon.png" alt="Iqamty Logo" width="120" />

  # 🏢 Iqamty (إقامتي) : The Smart Campus Platform
  
  **Final Project Report & Architectural Overview**

  ![Flutter Version](https://img.shields.io/badge/Flutter-3.4+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
  ![Architecture](https://img.shields.io/badge/Architecture-Multi--Tenant-8B5CF6?style=for-the-badge)
  ![Status](https://img.shields.io/badge/Status-Production_Ready-10B981?style=for-the-badge)

</div>

---

## 📖 Executive Summary

**Iqamty** is a high-performance, proprietary mobile and web platform designed to revolutionize and digitize the Algerian university residence experience. Conceived as a centralized operating system for campus living, it seamlessly bridges the gap between **Students**, **Administrators**, and **Maintenance Workers**.

By integrating directly with the official **Progres (WebEtu) API** for identity verification, Iqamty completely eliminates manual onboarding. It employs a dynamic, multi-tenant cloud architecture to isolate data, announcements, and logistics by physical campus, ensuring a secure and localized experience for every user.

---

## 🎯 The Problem & Our Solution

**The Challenge:** Traditional university residences rely on fragmented, paper-based systems for meal ticketing, maintenance requests, and administrative announcements. This leads to inefficiencies, lost requests, and a disconnect between campus management and students.

**The Solution:** Iqamty introduces a fully digital ecosystem. 
* **For Students:** A single app to book meals, report broken plumbing, view bus schedules, and chat with administration.
* **For Administration:** A real-time, unified dashboard to monitor campus operations, approve meal plans, and dispatch technical teams.
* **For Workers:** A streamlined ticketing system to track daily repair assignments across campus blocks.

---

## ✨ Core Modules & Capabilities

The platform dynamically morphs its UI and capabilities based on the authenticated user's role:

### 🎓 1. Student Portal
* **Dashboard & Live Status:** Real-time visibility into whether the campus restaurant or administrative offices are open or closed.
* **Smart Dining Booking:** A 3-day rolling reservation system for Breakfast, Lunch, and Dinner. Features capacity limits and meal ratings.
* **Technical Service Pipeline:** Submit maintenance tickets for room issues (Plumbing, Electrical, Carpentry) with attached images, and track their real-time resolution status.
* **Transport & Logistics:** View live schedules and maps for university shuttle buses (Navettes).
* **Community Forum:** A localized social feed for students of the same campus to share resources and discussions.
* **Direct Administration Chat:** Secure, 1-on-1 messaging with campus management.

### 🛡️ 2. Administrator Control Panel
* **Tenancy Management:** Manage all aspects of a specific campus without seeing cross-contamination from other universities.
* **Dining Configuration Engine:** Visually build weekly menus, set meal capacities, and instantly toggle kitchen status (Open/Closed).
* **Ticketing & Dispatch:** Review incoming student maintenance requests and dispatch them to specific technical workers.
* **Announcement Broadcaster:** Push high-priority, pinned alerts directly to the student dashboard.
* **Document Center:** Upload official PDFs, forms, and rulebooks for mass student download.

### 🛠️ 3. Worker Dashboard
* **Task Queue:** Receive dispatched maintenance tickets detailing the exact room number, issue category, and student notes.
* **Live Status Updates:** Move tickets through the lifecycle (`Pending` ➔ `In Progress` ➔ `Resolved`).

---

## 🏗️ System Architecture & Multi-Tenancy

Iqamty is built on a "Zero-Admin Friction" tenant model. Campuses are not manually created; they are **auto-provisioned** the moment the first student from that physical location logs in.

### The `idresidence` Isolation Engine

```mermaid
graph TD
    A[WebEtu Login / Progres API] -->|Raw Residence Name| B(AuthService)
    B -->|Normalize & Slugify| C{Check residences Collection}
    C -->|Match Found| D[Assign Existing residenceId]
    C -->|No Match| E[Auto-Provision New Residence]
    E -->|Status: pending_setup| F[Generate New residenceId]
    D --> G[User Profile Saved with residenceId]
    F --> G
    G --> H[FirestoreService Enforces Tenancy Filters]
```

To optimize cloud read costs while maintaining strict data silos, Iqamty uses a **Hybrid Stream-Filtering Architecture**. The cloud database performs the initial broad query, while the client layer applies real-time tenant mapping before it reaches the UI.

### ⚠️ Limitation Technique : Restrictions CORS & Géographiques (Progres API)

Lors du développement et du déploiement, l'écosystème a fait face à deux contraintes réseau majeures concernant l'**API Progres (WebEtu)** :
1. **Blocage Géographique** : Les serveurs de l'API Progres rejettent les requêtes HTTP provenant d'adresses IP hors d'Algérie (ce qui inclut les serveurs Cloud de Firebase Hosting).
2. **Politique CORS (Cross-Origin Resource Sharing)** : Le navigateur bloque les requêtes directes vers l'API Progres depuis une application web tierce hébergée.

*Note Historique d'Intégration :* L'intégration de l'application web fonctionnait initialement de manière fluide grâce à un proxy intermédiaire sécurisé développé par l'équipe et déployé sur **Vercel**. Cependant, la semaine précédant les examens finaux, la sécurité de l'API Progres a été considérablement renforcée (durcissement du pare-feu et filtrage géographique strict), bloquant ainsi l'accès depuis des hébergements cloud externes comme Vercel.

**Solution d'Architecture Actuelle (Fallback) & Perspectives d'Hébergement :**
* **Inscription & Première Connexion** : Doit être effectuée depuis l'**application mobile (Android APK)** ou via une **exécution web locale** (qui contourne les politiques CORS du navigateur).
* **Mécanisme de Cache Firestore** : Une fois qu'un étudiant s'est connecté une première fois sur mobile/local, ses informations de profil et de hachage de mot de passe sont enregistrées de manière sécurisée dans la base Firestore.
* **Connexion Web Ultérieure** : L'étudiant peut ensuite se connecter sur le site web hébergé sans problème. L'authentification s'effectue alors via Firestore, sans avoir besoin d'interroger directement l'API Progres externe.
* **Perspective de Déploiement (Hébergement Local en Algérie)** : À l'avenir, pour contourner définitivement ces restrictions géographiques et restaurer l'accès web direct sans étape intermédiaire, le proxy de l'API pourra être hébergé chez un fournisseur local en Algérie (comme le **Datacenter de l'ESTIN** ou le cloud national **Hawiyat**). Disposant d'IP algériennes et faisant partie du réseau académique autorisé, ces infrastructures ne subiront pas le filtrage géographique de l'API Progres.

---

## 🗄️ Database Schema

The application relies on a NoSQL document structure optimized for real-time streams:

* **`users`:** Stores profile data, hashed passwords for offline fallback, role definitions, and `residenceId` bindings.
* **`residences`:** The tenant documents containing configuration flags (e.g., `isRestaurantOpen`, `status`).
* **`restaurant` & `meals`:** Stores rolling 3-day configurations and historical meal reservation arrays.
* **`requests`:** The lifecycle tracking documents for technical repair tickets.
* **`announcements`:** Global and residence-specific broadcast messages.

---

## 💻 Technology Stack

| Domain | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter (Dart) | Single high-performance codebase for Android, iOS, and Web. |
| **State Management** | Provider | Reactive UI updates and dependency injection. |
| **Navigation** | GoRouter | Declarative, URL-based routing with redirection guards. |
| **Authentication** | Firebase Auth | Anonymous bridging to secure WebEtu API logins. |
| **Database** | Cloud Firestore | Real-time, NoSQL document syncing. |
| **Media Storage** | Cloudinary & Firebase | Optimized image uploading and CDN delivery. |
| **Local Storage** | SharedPreferences | JWT caching for offline capabilities. |

---

## 🎨 UI/UX Philosophy
Iqamty utilizes a premium, custom design system built entirely from scratch. Instead of relying purely on Material defaults, it implements:
* **Glassmorphism:** Soft, blurred transparency effects for modal sheets and floating elements.
* **Modern Typography:** Utilizing the `GoogleFonts.inter()` family for high legibility and a sleek aesthetic.
* **Micro-Animations:** Powered by `flutter_animate` to ensure every screen transition, button press, and data load feels dynamic, responsive, and alive.

---

## 🚀 Guide d'Exécution et de Test (Évaluation Académique)

* **Dépôt Git Officiel du Projet** : [https://github.com/SPINKO19/iqamty.v1](https://github.com/SPINKO19/iqamty.v1)

Pour faciliter l'évaluation du projet par le jury, l'application est disponible en direct sur le web et peut également être exécutée localement.

### 🌐 1. Accès Direct en Ligne & Installation
Vous pouvez tester l'ensemble de la plateforme (Étudiant, Admin, Oسuvrier) directement depuis votre navigateur sans aucune installation :
* **Lien de la Démo Web** : [https://iqamty-estin-pp.web.app](https://iqamty-estin-pp.web.app)
* **Installation sur Mobile (Android APK)** : Vous pouvez également installer l'application mobile en téléchargeant l'APK directement depuis le bouton d'installation présent sur l'interface du site web.

---

### 🔑 2. Identifiants de Test Pré-configurés
Pour explorer les différents portails et rôles, veuillez utiliser les comptes de test suivants :

#### 🛡️ A. Espace Administrateur (Admin Portal)
Permet de configurer le restaurant, de publier des annonces et d'assigner les tâches aux ouvriers.
* **Identifiant** : `admin2`
* **Mot de passe** : `admin2`

#### 🛠️ B. Espace Ouvrier (Worker Dashboard)
Permet de visualiser les tâches de maintenance assignées par l'administration et de mettre à jour leur statut.
* **Identifiant** : `worker2`
* **Mot de passe** : `worker2`

#### 🎓 C. Espace Étudiant (Student Portal)
Permet de réserver des repas, signaler des pannes, discuter avec l'administration et publier sur le forum.
* **Option A (Panneau de Test Local - Recommandée)** :
  * Lors de l'exécution locale du projet (mode Debug), un panneau intitulé **"DEV QUICK ACCESS"** s'affiche en bas de la page de connexion. Cliquez simplement sur **"Enter as Student"** pour vous connecter instantanément.
* **Option B (Intégration Progres / WebEtu - Sous conditions)** :
  * Utilisez vos identifiants WebEtu réels de l'ESTIN.
  * *(Note : Des identifiants WebEtu de test réels supplémentaires peuvent être fournis au jury sur simple demande auprès de l'équipe).*
  * *Important : En raison des restrictions géographiques de l'API Progres, la première connexion/inscription d'un nouvel étudiant doit être effectuée via l'application mobile (APK) ou en exécution locale. Une fois cette première connexion réussie, vous pourrez vous connecter normalement sur la version web hébergée.*

---

### 💻 3. Exécution Locale du Projet
Si vous souhaitez exécuter le projet localement à partir du code source :

#### Prérequis :
* **Flutter SDK** : Version 3.4.0 ou supérieure installé et configuré.
* **Navigateur Chrome** ou un émulateur Android/iOS fonctionnel.

#### Étapes d'exécution :
1. Ouvrez un terminal dans le répertoire racine du code source (`3_Code_Source/` ou `iqamty.v1/`).
2. Récupérez les dépendances du projet :
   ```bash
   flutter pub get
   ```
3. Lancez l'application (sur Chrome par défaut pour tester la version multi-plateforme) :
   ```bash
   flutter run -d chrome
   ```

---

<div align="center">
  <b>Built to elevate the student living experience.</b><br>
  <sub>All rights reserved. Proprietary software.</sub>
</div>
