# Cahier des charges — Connecteur Pennylane RFE (WinDev)

**Projet :** Intégration des APIs Pennylane pour la Réforme de la Facturation Électronique  
**Technologie cible :** WinDev (PC SOFT)  
**Date :** 23 avril 2026  
**Source de référence :** [Developer Toolkit RFE Pennylane](https://scribetech.notion.site/Developer-Toolkit-RFE-2452276c03bf80619889ca7ca72bb480)

---

## 1. Contexte et objectif

### 1.1 Contexte

La réforme française de la facturation électronique (RFE) impose à toutes les entreprises assujetties à la TVA de pouvoir émettre et recevoir des factures électroniques via une Plateforme de Dématérialisation Partenaire (PDP). **Pennylane est agréé PDP.**

Le logiciel WinDev doit s'interfacer avec les APIs Pennylane pour automatiser les échanges de factures électroniques (émission, réception, suivi de statuts) conformément aux exigences légales.

### 1.2 Objectif

Développer dans WinDev un connecteur robuste vers les APIs Pennylane couvrant :
1. L'authentification OAuth 2.0
2. La création de comptes / entreprises (Provisioning API)
3. L'émission de factures clients électroniques (Factur-X)
4. La récupération de factures fournisseurs
5. Le suivi du statut des factures électroniques
6. La gestion des inscriptions PA (PA Registrations)

### 1.3 Calendrier légal de référence

| Échéance | Obligation |
| --- | --- |
| T1 2026 | Phase pilote volontaire — réception |
| 1er septembre 2026 | Obligation de réception pour toutes les entreprises |
| 1er septembre 2026 | Obligation d'émission — grandes entreprises et ETI |
| 1er septembre 2027 | Obligation d'émission — PME et TPE |

---

## 2. Prérequis

### 2.1 Côté Pennylane (démarches partenariat)

Avant tout développement en production, le partenaire doit :
- Remplir le [formulaire de partenariat](https://www.pennylane.com/fr/partenaires/partenaire-technologique/) et être validé par l'équipe Pennylane.
- Recevoir les identifiants OAuth 2.0 : `client_id` et `client_secret`.

### 2.2 Côté développeur WinDev

- Accès à l'environnement sandbox Pennylane (fourni par Pennylane après validation).
- WinDev ≥ version supportant les appels HTTP/HTTPS avec gestion des headers personnalisés (fonctions `HTTPEnvoie`, `HTTPRequête` ou composant interne REST).
- Stockage sécurisé des tokens OAuth (base locale chiffrée ou coffre-fort applicatif).

---

## 3. Environnements

| Environnement | URL de base | Usage |
| --- | --- | --- |
| Sandbox (test) | https://sandbox.pennylane.com | Développement, recette, tests |
| Production | https://app.pennylane.com | Données réelles, déploiement final |

> La constante d'URL de base doit être **paramétrable** dans la configuration WinDev pour permettre la bascule sandbox ↔ production sans recompilation.

---

## 4. Authentification

### 4.1 Phase de test — Token développeur

Utilisé uniquement en développement initial pour valider les appels API avant d'implémenter OAuth.

- Généré manuellement dans Pennylane : **Paramètres entreprise > Connectivité > Développeurs**.
- Transmis dans le header HTTP : `Authorization: Bearer <token>`
- Durée et scopes configurables dans Pennylane.

> Ne jamais persister ce token en clair dans le code source ou la configuration versionnable.

### 4.2 Production — OAuth 2.0 (obligatoire)

#### Flow Authorization Code

```
1. WinDev ouvre un navigateur (ou WebView) vers l'URL d'autorisation Pennylane
   avec les paramètres : client_id, redirect_uri, scopes, state (anti-CSRF)

2. L'utilisateur se connecte et autorise l'accès

3. Pennylane redirige vers redirect_uri avec un code temporaire

4. WinDev échange ce code via POST /oauth/token
   → reçoit : access_token (24h) + refresh_token (90 jours)

5. Toutes les requêtes API utilisent : Authorization: Bearer <access_token>
```

#### Gestion des tokens dans WinDev

| Token | Durée de vie | Action à l'expiration |
| --- | --- | --- |
| `access_token` | 24 heures | Appeler `/oauth/token` avec `grant_type=refresh_token` |
| `refresh_token` | 90 jours | Relancer le flow Authorization Code complet |

**Exigences de stockage :**
- Stocker les tokens chiffrés (ex. : `AES256`) dans la base de données locale WinDev.
- Vérifier systématiquement la validité du token avant chaque appel API.
- Implémenter un mécanisme de refresh automatique transparent pour l'utilisateur.

#### Endpoint token

```
POST https://app.pennylane.com/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=<refresh_token>
&client_id=<client_id>
&client_secret=<client_secret>
```

**Ref. :** https://pennylane.readme.io/docs/oauth-20-walkthrough

---

## 5. Fonctionnalités à développer

### 5.1 Provisioning — Création entreprise et utilisateur

Utilisé lorsque le client n'a pas encore de compte Pennylane.

**Endpoint — Créer un utilisateur :**
```
POST https://app.pennylane.com/api/partner/v2/users
Authorization: Bearer <access_token_provisioning>
```

**Endpoint — Créer une entreprise :**
```
POST https://app.pennylane.com/api/partner/v2/companies
Authorization: Bearer <access_token_provisioning>
```

> Spécifier `plan: "v1_freemium"` pour un usage PA gratuit.

**Token de provisioning :**
```
POST https://app.pennylane.com/oauth/token
grant_type=client_credentials
&client_id=<client_id>
&client_secret=<client_secret>
```

**Comportement attendu côté WinDev :**
- Créer l'utilisateur en premier (il recevra un email d'invitation pour finaliser son mot de passe + 2FA + accepter les CGV).
- Récupérer le `company_id` retourné pour les appels suivants.
- ⚠️ En sandbox, l'envoi du mail d'invitation est bloqué — simuler la finalisation via la page de mot de passe oublié.

**Réfs. :**
- https://provisioning-pennylane.readme.io/reference/postusers
- https://provisioning-pennylane.readme.io/reference/companycreate
- https://provisioning-pennylane.readme.io/reference/getcompanies

---

### 5.2 Émission d'une facture client électronique (Factur-X)

**Endpoint :**
```
POST https://app.pennylane.com/api/external/v2/customer_invoices/e_invoice_import
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Corps de la requête :** fichier Factur-X (.pdf avec XMP embarqué ou .xml seul).

**Comportement :**
- Pennylane reçoit le Factur-X et le transmet à la PA.
- Selon le type de client (B2B France / B2B international / B2C), Pennylane achemine en e-invoicing ou e-reporting automatiquement.

**Réf. :** https://pennylane.readme.io/reference/createcustomerinvoiceeinvoiceimport  
**Doc Factur-X :** https://scribetech.notion.site/Documentation-sur-l-import-FacturX-29c2276c03bf81da8e47cb76aab35ccb

---

### 5.3 Récupération des factures fournisseurs (réception PA)

**Endpoint :**
```
GET https://app.pennylane.com/api/external/v2/supplier_invoices
Authorization: Bearer <access_token>
```

**Champ clé à exploiter :** `e_invoicing.status` (statut PA de la facture reçue).

**Comportement WinDev attendu :**
- Appel périodique (polling ou webhook si disponible) pour récupérer les nouvelles factures.
- Stocker et afficher le statut e-invoicing dans l'interface.
- Déclencher une action métier en cas de nouveaux statuts (ex. : comptabilisation automatique).

**Réf. :** https://pennylane.readme.io/reference/getsupplierinvoices

---

### 5.4 Mise à jour du statut d'une facture fournisseur

**Endpoint :**
```
PUT https://app.pennylane.com/api/external/v2/supplier_invoices/{id}/e_invoice_status
Authorization: Bearer <access_token>
Scope requis : supplier_invoices:all
```

**Actions disponibles :**

| Action WinDev | Valeur `status` | Champ `reason` |
| --- | --- | --- |
| Contester | `disputed` | Obligatoire |
| Refuser | `refused` | Obligatoire |
| Annuler une contestation | `approved` | Non applicable |

**Réf. :** https://pennylane.readme.io/reference/putsupplierinvoiceeinvoicestatus

---

### 5.5 Liste des inscriptions PA (PA Registrations)

Permet de vérifier si une entreprise est inscrite à la PA Pennylane avant d'envoyer une facture en e-invoicing.

**Endpoint Company API :**
```
GET https://app.pennylane.com/api/external/v2/pa_registrations
Authorization: Bearer <access_token>
```

**Endpoint Provisioning API :**
```
GET https://app.pennylane.com/api/partner/v2/companies/{company_id}/pa_registrations
Authorization: Bearer <access_token_provisioning>
```

**Réponse — Structure principale :**

| Champ | Type | Description |
| --- | --- | --- |
| `has_more` | boolean | Indique s'il reste des pages |
| `next_cursor` | string / null | Curseur de pagination ; null = dernière page |
| `id` | int64 | Identifiant de l'enregistrement PA |
| `siret` | string / null | SIRET (vide si inscription niveau SIREN) |
| `siren` | string | Numéro SIREN |
| `status` | enum | `provisioned` / `pending` / `activated` |
| `exchange_direction` | enum | `emission` / `reception` / `emission_and_reception` |
| `created_at` | datetime | Date de création |
| `updated_at` | datetime | Date de mise à jour |

**Statuts :**

| Valeur | Signification |
| --- | --- |
| `provisioned` | Enregistrement démarré |
| `pending` | Validation annuaire en cours |
| `activated` | Entreprise inscrite et active dans l'annuaire |

**Gestion de la pagination cursor-based dans WinDev :**
```
// Pseudo-code WinDev
cursor = ""
Répéter
    réponse = AppelAPI("/pa_registrations?cursor=" + cursor)
    TraiterEnregistrements(réponse.data)
    Si réponse.has_more = Faux : Quitter
    cursor = réponse.next_cursor
Fin Répéter
```

---

### 5.6 Récupération du profil utilisateur connecté

Nécessaire pour récupérer le `company_id` après OAuth.

**Endpoint :**
```
GET https://app.pennylane.com/api/external/v2/me
Authorization: Bearer <access_token>
```

**Réf. :** https://pennylane.readme.io/reference/getme

---

## 6. Scénarios d'intégration selon le profil utilisateur

### Scénario A — Nouvel utilisateur (absent de Pennylane)

```
[WinDev] Provisioning API → Création utilisateur + entreprise
     ↓
[Utilisateur] Finalisation onboarding Pennylane (email, mot de passe, 2FA, CGV)
     ↓
[Utilisateur] Désignation PA Pennylane dans l'interface (signature numérique)
     ↓
[WinDev] OAuth 2.0 → récupération access_token + refresh_token
     ↓
[WinDev] Échanges RFE via Company API (émission / réception)
```

### Scénario B — Utilisateur existant sans PA désignée

```
[WinDev] OAuth 2.0 → récupération access_token
     ↓
[WinDev] GET /me → récupération company_id
     ↓
[WinDev] Ouvrir navigateur/WebView vers :
    https://app.pennylane.com/companies/{company_id}/pdp_activation
     ↓
[Utilisateur] Désignation PA Pennylane
     ↓
[WinDev] Échanges RFE via Company API
```

### Scénario C — Utilisateur existant avec PA Pennylane déjà désignée

```
[WinDev] OAuth 2.0 → récupération access_token
     ↓
[WinDev] Échanges RFE via Company API (émission / réception)
```

### Scénario D — Utilisateur existant avec une autre PA désignée

```
[WinDev] OAuth 2.0 → récupération access_token
     ↓
[WinDev/Utilisateur] Demande de portabilité via interface Pennylane
     ↓
[Après portabilité] Échanges RFE via Company API
```

---

## 7. Gestion des erreurs et bonnes pratiques WinDev

### 7.1 Codes HTTP à traiter

| Code HTTP | Signification | Action WinDev |
| --- | --- | --- |
| 200 / 201 | Succès | Traitement normal |
| 401 | Token expiré ou invalide | Déclencher refresh automatique |
| 403 | Scope insuffisant | Logger + alerter l'administrateur |
| 404 | Ressource introuvable | Logger + retour utilisateur |
| 422 | Données invalides | Parser le message d'erreur et afficher |
| 429 | Rate limit atteint | Attendre (backoff exponentiel) et réessayer |
| 500 | Erreur serveur Pennylane | Logger + retry différé |

### 7.2 Gestion du rate limiting (HTTP 429)

Implémenter un **backoff exponentiel** :
```
// Pseudo-code WinDev
tentative = 1
délai = 1 seconde
Tant que tentative <= 5
    résultat = AppelAPI(...)
    Si résultat.code <> 429 : Quitter
    Attendre(délai)
    délai = délai * 2
    tentative++
Fin Tantque
```

### 7.3 Idempotence

- Utiliser un identifiant unique métier (ex. : numéro de facture interne) dans les requêtes POST pour éviter les doublons en cas de retry.
- Conserver localement l'état des envois (date, statut, réponse API).

### 7.4 Logging

Journaliser systématiquement :
- URL appelée
- Code de retour HTTP
- Horodatage
- Identifiant de la ressource (facture, utilisateur, etc.)
- Message d'erreur si applicable

---

## 8. Structure de données suggérée (tables WinDev)

### Table `PL_Token`

| Champ | Type | Description |
| --- | --- | --- |
| `ID_Entreprise` | Entier long | Clé étrangère vers la table entreprise |
| `AccessToken` | Texte (chiffré) | Token OAuth courant |
| `RefreshToken` | Texte (chiffré) | Token de renouvellement |
| `DateExpirationAccess` | DateHeure | Expiration access_token |
| `DateExpirationRefresh` | DateHeure | Expiration refresh_token |
| `CompanyID_Pennylane` | Texte | company_id Pennylane |

### Table `PL_FactureEmise`

| Champ | Type | Description |
| --- | --- | --- |
| `ID_Facture` | Entier long | Clé primaire locale |
| `NumeroFacture` | Texte | Numéro de facture interne |
| `DateEnvoi` | DateHeure | Date d'envoi à Pennylane |
| `StatutPA` | Texte | Statut retourné par Pennylane |
| `IDPennylane` | Texte | Identifiant retourné par l'API |
| `FichierFacturX` | Texte | Chemin ou BLOB du fichier Factur-X |

### Table `PL_FactureRecue`

| Champ | Type | Description |
| --- | --- | --- |
| `ID_FactureFourn` | Entier long | Clé primaire locale |
| `IDPennylane` | Texte | Identifiant Pennylane |
| `Fournisseur` | Texte | Nom / SIREN fournisseur |
| `StatutEInvoicing` | Texte | e_invoicing.status |
| `ActionEffectuee` | Texte | disputed / refused / approved |
| `DateRecuperation` | DateHeure | Dernière synchronisation |

### Table `PL_PARegistration`

| Champ | Type | Description |
| --- | --- | --- |
| `ID` | Entier long | id retourné par l'API |
| `SIREN` | Texte | Numéro SIREN |
| `SIRET` | Texte | Numéro SIRET (vide si SIREN) |
| `Statut` | Texte | provisioned / pending / activated |
| `DirectionEchange` | Texte | emission / reception / emission_and_reception |
| `DateMAJ` | DateHeure | updated_at |

---

## 9. Livrables attendus du développeur WinDev

| # | Livrable | Description |
| --- | --- | --- |
| 1 | Module authentification OAuth | Gestion complète du flow OAuth 2.0 + refresh automatique |
| 2 | Module Provisioning | Création utilisateur + entreprise via API Provisioning |
| 3 | Module émission Factur-X | Upload et envoi de factures électroniques |
| 4 | Module réception factures | Récupération et affichage des factures fournisseurs reçues |
| 5 | Module mise à jour statuts | Disputer / refuser / approuver une facture fournisseur |
| 6 | Module PA Registrations | Liste et suivi des inscriptions PA avec pagination |
| 7 | Interface de configuration | Saisie des paramètres (client_id, secret, redirect_uri, env) |
| 8 | Journal des appels API | Écran de consultation des logs d'échanges |
| 9 | Tests sandbox validés | Preuve de fonctionnement sur l'environnement de test |

---

## 10. Étapes de développement recommandées

1. **Configurer l'environnement sandbox** — créer un accès via l'équipe Pennylane.
2. **Tester les endpoints avec un token développeur** (sans OAuth) pour valider les appels HTTP depuis WinDev.
3. **Implémenter le flow OAuth 2.0** avec gestion des tokens en base.
4. **Développer le Provisioning** (création utilisateur + entreprise).
5. **Développer l'émission Factur-X** + validation du format.
6. **Développer la réception et le suivi des statuts** factures fournisseurs.
7. **Développer le module PA Registrations** avec pagination.
8. **Tests de charge et gestion des erreurs** (429, retry, backoff).
9. **Demander la certification du connecteur** auprès de Pennylane.
10. **Passage en production** après certification.

---

## 11. Contacts et ressources clés

| Ressource | Lien |
| --- | --- |
| API Company — Vue d'ensemble | https://pennylane.readme.io/docs/api-overview |
| API Provisioning | https://provisioning-pennylane.readme.io/reference/companycreate |
| OAuth 2.0 walkthrough | https://pennylane.readme.io/docs/oauth-20-walkthrough |
| Générer un token développeur | https://pennylane.readme.io/docs/generating-my-api-token |
| Créer un environnement sandbox | https://help.pennylane.com/fr/articles/18773-creer-un-environnement-de-test |
| Guide intégration PA Pennylane | https://pennylane-hq.notion.site/Int-gration-PA-Pennylane-Guide-partenaires-21c2276c03bf80139e24eeba11390fd5 |
| Mapping statuts AFNOR | https://scribetech.notion.site/Mapping-Statuts-Pennylane-x-AFNOR-Dev-Toolkit-3252276c03bf800d8324d26ad62d4035 |
| Doc import Factur-X | https://scribetech.notion.site/Documentation-sur-l-import-FacturX-29c2276c03bf81da8e47cb76aab35ccb |
| Roadmap API | https://pennylane.readme.io/docs/api-public-roadmap |
| Partenariats (email) | partnerships@pennylane.com |
| Formulaire partenariat | https://www.pennylane.com/fr/partenaires/partenaire-technologique/ |

---

## Annexe — Checklist avant mise en production

- [ ] Validation partenaire Pennylane effectuée (client_id / client_secret reçus)
- [ ] Tous les modules testés en sandbox
- [ ] Gestion des erreurs HTTP implémentée (401, 429 + backoff, 422)
- [ ] Refresh token automatique opérationnel
- [ ] Tokens OAuth stockés chiffrés en base
- [ ] Logging de tous les appels API activé
- [ ] Pagination cursor-based traitée correctement
- [ ] Certification du connecteur demandée et obtenue
- [ ] Documentation utilisateur finalisée
- [ ] Tests de charge réalisés
