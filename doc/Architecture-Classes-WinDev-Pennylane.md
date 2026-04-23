# Architecture des classes WinDev — Connecteur Pennylane RFE

**Projet :** Composant WinDev — Intégration Pennylane Accounting API v2  
**Spec de référence :** `accounting.json` (OpenAPI 3.0.1) — 119 endpoints  
**Date :** 23 avril 2026

---

## 1. Principes de conception

### SOLID appliqué

| Principe | Application dans le connecteur |
|---|---|
| **S** — Responsabilité unique | Chaque classe gère un seul domaine métier (auth, HTTP, invoice, etc.) |
| **O** — Ouvert/Fermé | Nouvelles stratégies d'auth ou nouveaux repos sans modifier l'existant |
| **L** — Substitution de Liskov | `CPennylaneDevTokenAuth` et `CPennylaneOAuth2Auth` sont interchangeables |
| **I** — Ségrégation des interfaces | Interfaces fines : `IAuthStrategy`, `IObserver`, `IRepository<T>` |
| **D** — Inversion de dépendance | `CPennylaneFacade` dépend des interfaces, pas des implémentations |

### Patterns utilisés

| Pattern | Classes concernées | Rôle |
|---|---|---|
| **Strategy** | `IAuthStrategy`, `CPennylaneDevTokenAuth`, `CPennylaneOAuth2Auth` | Interchanger la méthode d'authentification sans toucher au reste |
| **Observer** | `IObserver`, `CPennylaneEventBus` | Notifier l'application maître (token refresh, facture reçue, erreur) |
| **Repository** | `IRepository<T>`, `CCustomerInvoiceRepository`, … | Isolation des appels API, testabilité |
| **Facade** | `CPennylaneFacade` | Point d'entrée unique exposé au composant externe WinDev |
| **Factory** | `CPennylaneHttpClientFactory` | Créer le bon client HTTP (sandbox / production) |
| **Template Method** | `CPennylanePaginatedFetcher<T>` | Pagination cursor-based réutilisable sur tous les endpoints |
| **Value Object** | `CPennylaneToken`, `CPennylaneConfig` | Objets immuables portant une valeur métier précise |

---

## 2. Vue d'ensemble des couches

```
╔══════════════════════════════════════════════════════════════════╗
║  APPLICATION MAÎTRE (WinDev)                                     ║
║  Fournit : chemin PDF, company_id                                ║
║  Reçoit  : buffer PDF, statuts, objets métier                    ║
╠══════════════════════════════════════════════════════════════════╣
║  FACADE  ──  CPennylaneFacade                                    ║
║              Point d'entrée unique du composant externe          ║
╠════════════════════════════╦═════════════════════════════════════╣
║  COUCHE DOMAINE            ║  COUCHE INFRASTRUCTURE              ║
║  IRepository<T>            ║  CPennylaneHttpClient               ║
║  CCustomerInvoiceRepo      ║  CPennylaneHttpClientFactory        ║
║  CSupplierInvoiceRepo      ║  CPennylaneTokenStore               ║
║  CPARegistrationRepo       ║  CPennylaneConfig          ←──┐     ║
║  CCustomerRepo             ║  CPennylaneEventBus              │     ║
║  CSupplierRepo             ║                                  │     ║
║  CProvisioningRepo         ║  FICHIER CONFIG POSTE           │     ║
╠════════════════════════════╩════════════════════════════ ◄───┘ ══╣
║  AUTHENTIFICATION — Strategy Pattern                             ║
║  IAuthStrategy                                                   ║
║  ├── CPennylaneDevTokenAuth   (tests)                            ║
║  └── CPennylaneOAuth2Auth     (production, obligatoire)         ║
╠══════════════════════════════════════════════════════════════════╣
║  MODÈLES (Value Objects / DTOs)                                  ║
║  CPennylaneCustomerInvoice  CPennylaneSupplierInvoice            ║
║  CPennylaneInvoiceLine       CPennylaneEInvoicing                ║
║  CPennylanePARegistration    CPennylaneCustomer                  ║
║  CPennylaneSupplier          CPennylaneUserProfile               ║
║  CPennylaneToken             CPennylanePaginatedResult           ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3. Diagramme de classes simplifié

```
IAuthStrategy (interface)
├── + ObtenirHeader() : Chaîne
├── + EstValide() : Booléen
└── + Rafraichir() : Booléen
        ▲                    ▲
        │                    │
CPennylaneDevTokenAuth   CPennylaneOAuth2Auth
(lit le token dans        (gère le flow Authorization Code
 CPennylaneConfig)         + refresh automatique)

CPennylaneConfig ──────────────────────────────────────────
│  CheminFichier : Chaîne    (ex: %APPDATA%\app\pl.cfg)   │
│  BaseURL : Chaîne                                         │
│  Environnement : SANDBOX | PRODUCTION                    │
│  ClientID : Chaîne  (chiffré AES dans le fichier)        │
│  ClientSecret : Chaîne  (chiffré AES)                    │
│  + Charger() / Sauvegarder()                              │
└───────────────────────────────────────────────────────────

CPennylaneTokenStore ──────────────────────────────────────
│  Stocke dans CPennylaneConfig (partie chiffrée)           │
│  AccessToken : CPennylaneToken                            │
│  RefreshToken : CPennylaneToken                           │
│  + Stocker(token, refresh)                                │
│  + Charger() : CPennylaneToken                            │
│  + EstExpire() : Booléen                                  │
└───────────────────────────────────────────────────────────

CPennylaneHttpClient ──────────────────────────────────────
│  + Get(url, params) : CPennylaneHttpResponse              │
│  + Post(url, body) : CPennylaneHttpResponse               │
│  + PostMultipart(url, cheminFichier) : CPennylaneHttpResponse
│  + Put(url, body) : CPennylaneHttpResponse                │
│  + Delete(url) : CPennylaneHttpResponse                   │
│  (retry backoff exponentiel intégré sur HTTP 429/5xx)     │
└───────────────────────────────────────────────────────────

IRepository<T> (interface générique)
├── + Lister(params) : CPennylanePaginatedResult<T>
├── + ListerTout(params) : tableau de T (pagination auto)
└── + ParID(id) : T

CPennylaneFacade ──────────────────────────────────────────
│  Point d'entrée unique pour l'application maître          │
│  + Initialiser(cheminConfig)                              │
│  + LancerOAuth()                                          │
│  -- Factures clients --                                   │
│  + EmettreFacture(cheminPDF) : CPennylaneCustomerInvoice  │
│  + FinaliserFacture(id) : Booléen                         │
│  -- Factures fournisseurs --                              │
│  + RecupererFactures() : tab CPennylaneSupplierInvoice    │
│  + RecupererPDFFournisseur(id) : Buffer                   │
│  + MettreAJourStatut(id, statut, motif) : Booléen         │
│  -- PA Registrations --                                   │
│  + ListerInscriptionsPA() : tab CPennylanePARegistration  │
│  + EstInscritPA(siren) : Booléen                          │
│  -- Provisioning --                                       │
│  + CreerUtilisateur(email, prenom, nom) : Chaîne          │
│  + CreerEntreprise(nom, siren, plan) : Chaîne             │
│  -- Observateurs --                                       │
│  + AjouterObservateur(obs : IObserver)                    │
└───────────────────────────────────────────────────────────

IObserver (interface)
├── + SurTokenRefraichi(token : CPennylaneToken)
├── + SurFactureRecue(facture : CPennylaneSupplierInvoice)
├── + SurStatutChange(id, statut)
└── + SurErreur(code, message)

CPennylaneEventBus
│  Implémente le dispatch vers tous les observateurs enregistrés
│  + Abonner(obs : IObserver)
│  + Desabonner(obs : IObserver)
│  + Publier(evenement, donnees)
└──────────────────────────────────────────────────────────
```

---

## 4. Flux — Émission d'une facture (chemin PDF → Pennylane)

```
Application maître
    │
    │ EmettreFacture("C:\factures\F-2026-001.pdf")
    ▼
CPennylaneFacade
    │ 1. Vérifie token via IAuthStrategy.EstValide()
    │    Si expiré → CPennylaneOAuth2Auth.Rafraichir()
    │ 2. Lit le PDF depuis le chemin fourni (buffer binaire)
    │ 3. Appelle CPennylaneHttpClient.PostMultipart(
    │         "/api/external/v2/customer_invoices/e_invoices/imports",
    │         cheminPDF)
    ▼
CPennylaneHttpClient
    │ Construit la requête multipart/form-data
    │ Ajoute header : Authorization: Bearer <access_token>
    │ Envoie via HTTPEnvoie() WinDev
    ▼
API Pennylane
    │ Retourne CPennylaneCustomerInvoice (id, statut, e_invoicing)
    ▼
CPennylaneFacade
    │ Publie SurFactureEmise() → CPennylaneEventBus → IObserver(s)
    │ Retourne CPennylaneCustomerInvoice à l'application maître
    ▼
Application maître
```

---

## 5. Flux — Réception d'une facture fournisseur (Pennylane → buffer)

```
Application maître
    │
    │ RecupererPDFFournisseur("fa_2026_001_pennylane_id")
    ▼
CPennylaneFacade
    │ 1. Vérifie token
    │ 2. GET /api/external/v2/supplier_invoices/{id}
    │    → Récupère public_file_url
    │ 3. GET public_file_url → télécharge le PDF en mémoire
    ▼
CPennylaneHttpClient
    │ Retourne tableau d'octets (Buffer)
    ▼
CPennylaneFacade
    │ Publie SurFactureRecue()
    │ Retourne Buffer à l'application maître
    ▼
Application maître (traite le PDF directement en mémoire)
```

---

## 6. Flux — OAuth 2.0 (Authorization Code)

```
Application maître
    │ LancerOAuth()
    ▼
CPennylaneFacade → CPennylaneOAuth2Auth.LancerFlow()
    │ 1. Construit l'URL d'autorisation avec state aléatoire
    │ 2. Ouvre le navigateur (OuvreURL() WinDev)
    │ 3. Démarre un serveur HTTP local temporaire
    │    (écoute sur redirect_uri localhost:{port})
    │ 4. Reçoit le code + valide le state
    │ 5. POST /oauth/token → access_token + refresh_token
    │ 6. CPennylaneTokenStore.Stocker(...)
    ▼
CPennylaneEventBus.Publier(SurTokenRefraichi)
    ▼
Application maître (notifiée, prête pour les appels API)
```

---

## 7. Fichier de configuration local

Le fichier est stocké sur le poste utilisateur, en dehors du répertoire de l'application.

**Emplacement par défaut :**
```
%APPDATA%\<NomApp>\pennylane.cfg
```

**Format JSON chiffré (AES-256) :**
```json
{
  "env": "SANDBOX",
  "base_url": "https://sandbox.pennylane.com",
  "client_id": "<chiffré>",
  "client_secret": "<chiffré>",
  "redirect_uri": "http://localhost:9753/oauth/callback",
  "access_token": "<chiffré>",
  "access_token_expiry": "2026-04-23T18:00:00Z",
  "refresh_token": "<chiffré>",
  "refresh_token_expiry": "2026-07-22T00:00:00Z",
  "company_id": "166859",
  "user_id": "42"
}
```

**Règles de sécurité :**
- `client_secret`, `access_token`, `refresh_token` : chiffrés AES-256 avec une clé dérivée du `SID` Windows de l'utilisateur courant (DPAPI ou équivalent WinDev `ChiffreAES`).
- Le fichier ne doit jamais être versionné (ajouter au `.gitignore` si applicable).
- La clé de chiffrement n'est jamais stockée dans le fichier lui-même.

---

## 8. Gestion des erreurs — Strategy de retry

```
HTTP 200/201  → Succès, retourner le modèle désérialisé
HTTP 401      → Appeler IAuthStrategy.Rafraichir()
               Si échec → Publier SurErreur("AUTH_EXPIRED") → relancer flow OAuth
HTTP 403      → Publier SurErreur("SCOPE_INSUFFISANT", scope_manquant)
HTTP 404      → Retourner NIL, Publier SurErreur("RESSOURCE_INTROUVABLE")
HTTP 422      → Parser message d'erreur, Publier SurErreur("VALIDATION", details)
HTTP 429      → Backoff exponentiel : Attendre(100 CS), 200 CS, 400 CS, 800 CS, 1600 CS
               (100 centièmes de seconde = 1 seconde — WLangage : Attendre(n) en CS)
               Ou syntaxe lisible : Attendre(1 s), Attendre(2 s), ... (v23+)
HTTP 500/503  → Retry différé (3 tentatives, intervalle 5 s)
```

---

## 9. Conventions de nommage WinDev

| Élément | Convention | Exemple |
|---|---|---|
| Classe | Préfixe `C` + PascalCase | `CPennylaneFacade` |
| Interface | Préfixe `I` + PascalCase | `IAuthStrategy` |
| Attribut de classe | PascalCase | `AccessToken` |
| Méthode | PascalCase | `EmettreFacture()` |
| Paramètre | camelCase | `cheminPDF` |
| Constante | MAJUSCULES_UNDERSCORE | `ENV_PRODUCTION` |
| Fichier de classe | Même nom que la classe | `CPennylaneFacade.wdp` |

---

## 10. Organisation des fichiers dans le composant WinDev

```
PennylaneConnecteur.wdp (Composant externe)
│
├── Config/
│   ├── CPennylaneConfig.wdp
│   └── CPennylaneTokenStore.wdp
│
├── Auth/
│   ├── IAuthStrategy.wdp          (interface)
│   ├── CPennylaneDevTokenAuth.wdp
│   └── CPennylaneOAuth2Auth.wdp
│
├── Http/
│   ├── CPennylaneHttpClient.wdp
│   ├── CPennylaneHttpClientFactory.wdp
│   └── CPennylaneHttpResponse.wdp
│
├── Models/
│   ├── CPennylaneToken.wdp
│   ├── CPennylaneUserProfile.wdp
│   ├── CPennylaneCustomer.wdp
│   ├── CPennylaneSupplier.wdp
│   ├── CPennylaneCustomerInvoice.wdp
│   ├── CPennylaneInvoiceLine.wdp
│   ├── CPennylaneEInvoicing.wdp
│   ├── CPennylaneSupplierInvoice.wdp
│   ├── CPennylanePARegistration.wdp
│   └── CPennylanePaginatedResult.wdp
│
├── Repositories/
│   ├── IRepository.wdp             (interface générique)
│   ├── CCustomerInvoiceRepository.wdp
│   ├── CSupplierInvoiceRepository.wdp
│   ├── CPARegistrationRepository.wdp
│   ├── CCustomerRepository.wdp
│   ├── CSupplierRepository.wdp
│   └── CProvisioningRepository.wdp
│
├── Events/
│   ├── IObserver.wdp               (interface)
│   └── CPennylaneEventBus.wdp
│
└── CPennylaneFacade.wdp            (point d'entrée public)
```

---

## 11. Intégration dans l'application maître

```wlangage
// Dans l'application maître WinDev
// Déclaration et initialisation
goPennylane est un CPennylaneFacade

// Enregistrer l'application comme observateur
goPennylane.AjouterObservateur(MonObservateur)

// Initialiser depuis le fichier config du poste
goPennylane.Initialiser("%APPDATA%\MonApp\pennylane.cfg")

// Lancer OAuth (si pas encore de token valide)
SI PAS goPennylane.EstAuthentifie() ALORS
    goPennylane.LancerOAuth()
FIN

// Émettre une facture (chemin PDF fourni par l'app maître)
oFacture est un CPennylaneCustomerInvoice
oFacture = goPennylane.EmettreFacture("C:\factures\F-2026-001.pdf")
SI oFacture <> NIL ALORS
    Info("Facture transmise, ID Pennylane : " + oFacture.ID)
FIN

// Récupérer le buffer PDF d'une facture fournisseur
bufPDF est un Buffer
bufPDF = goPennylane.RecupererPDFFournisseur("fa_pennylane_id_123")
SI bufPDF <> NIL ALORS
    // Traiter le PDF en mémoire dans l'app maître
    // Exemples valides :
    //   PDF_MonLecteur.Charge(bufPDF)          // Afficher dans un champ Lecteur PDF
    //   fSauveBuffer("C:\temp\facture.pdf", bufPDF)  // Sauvegarder sur disque
    //   EnvoyerBufferVersAutreAppli(bufPDF)    // Transmettre à un autre module
FIN

// Vérifier qu'un fournisseur est inscrit PA avant envoi
SI goPennylane.EstInscritPA("123456789") ALORS
    goPennylane.EmettreFacture(cheminPDF)
FIN

// Option : callback direct au lieu d'observer (plus simple pour une seule fenêtre)
goPennylane.CallbackFactureRecue = PROCÉDURE INTERNE(f est un CPennylaneSupplierInvoice)
    TableauAjouteLigne(TABLE_Factures, f.ID, f.Label, f.Montant)
FIN PROCÉDURE
```

---

## 12. Dépendances entre classes (ordre d'instanciation)

```
1. CPennylaneConfig          (lit le fichier local)
2. CPennylaneTokenStore      (dépend de Config)
3. IAuthStrategy             (dépend de Config + TokenStore)
4. CPennylaneHttpClientFactory → CPennylaneHttpClient  (dépend de AuthStrategy)
5. CPennylaneEventBus        (indépendant)
6. IRepository<T> (x6)      (dépendent de HttpClient + EventBus)
7. CPennylaneFacade          (dépend de tout ce qui précède)
```

---

## 13. Retour d'information vers l'application maître

Deux mécanismes sont disponibles et **combinables**.

### Mécanisme A — Interface IObserver (Pattern Observer)

Optimal pour plusieurs modules qui écoutent les mêmes événements.

```
Application maître
    │
    │ Implémente IObserver
    │ → SurFactureRecue(oFacture)
    │ → SurErreur(code, message)
    ▼
CPennylaneFacade.AjouterObservateur(monObservateur)
    │
    │ CPennylaneEventBus.Publier(...)
    │ → Dispatche vers tous les IObserver enregistrés
    ▼
Application maître notifiée (callback via interface)
```

```wlangage
CLASSE CMaFenetre IMPLEMENTE IObserver
    PROCÉDURE SurFactureRecue(oFacture est un CPennylaneSupplierInvoice)
        TableauAjouteLigne(TABLE_Factures, oFacture.ID, oFacture.Label)
    FIN
    PROCÉDURE SurErreur(code est une Chaîne, msg est une Chaîne)
        Erreur("[" + code + "] " + msg)
    FIN
    // ... autres méthodes requises par l'interface ...
FIN
```

### Mécanisme B — Variable Procédure (Callback direct)

Optimal lorsqu'une seule fenêtre gère les événements. Plus simple à câbler.

```wlangage
// Assigner depuis n'importe où dans l'app maître
goPennylane.CallbackFactureEmise  = MaProc_FactureEmise
goPennylane.CallbackFactureRecue  = MaProc_FactureRecue
goPennylane.CallbackErreur        = MaProc_Erreur

// Ou closure (WinDev 27+)
goPennylane.CallbackFactureRecue = PROCÉDURE INTERNE(f est un CPennylaneSupplierInvoice)
    TableauAjouteLigne(TABLE_Factures, f.ID, f.Label, f.Montant)
FIN PROCÉDURE

// Désabonnement
goPennylane.CallbackFactureRecue = NIL
```

### Comparaison

| Critère | IObserver | Procédure (callback) |
|---|---|---|
| Plusieurs abonnés simultanés | ✅ Oui | ❌ Un seul par événement |
| Simplicité de câblage | Moyen (implémenter interface) | ✅ Simple (1 ligne) |
| Closure / lambda (WinDev 27+) | ❌ Non | ✅ Oui |
| Désabonnement propre | ✅ `Desabonner()` | ✅ Assigner `NIL` |
| Compatible composant externe | ✅ | ✅ |

> **Recommandation :** Exposer les deux. L'EventBus (`IObserver`) pour la couche métier, les `CallbackXxx` pour les appels rapides depuis une fenêtre unique.
