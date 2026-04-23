# Developer Toolkit - RFE

Source : https://scribetech.notion.site/Developer-Toolkit-RFE-2452276c03bf80619889ca7ca72bb480

## Guide d'integration RFE pour partenaires technologiques

## TL;DR

- Objectif : integrer les APIs Pennylane (Company API + OAuth + Provisioning API).
- Demarrage recommande : acces sandbox -> tests via token developpeur -> implementation OAuth 2.0.
- En production : OAuth 2.0 est obligatoire pour les partenaires technologiques.
- Support : partnerships@pennylane.com

## Introduction

Bienvenue dans le Developer Toolkit de Pennylane.

Ce guide couvre :
- authentification,
- environnements,
- tests,
- mise en production,
- ressources RFE.

Pennylane est un OS financier et comptable pour les PME et cabinets comptables francais. Les APIs permettent notamment d'automatiser :
- la facturation client,
- les abonnements,
- la centralisation et le traitement des factures fournisseurs,
- des flux lies a la reforme de la facturation electronique.

## Avant de commencer

### 1) Processus de partenariat

Etape obligatoire : etre valide comme partenaire technologique.

- Formulaire : https://www.pennylane.com/fr/partenaires/partenaire-technologique/
- Validation par l'equipe Partenariats.
- Reception des identifiants OAuth 2.0 (client_id et client_secret).

### 2) Environnements et donnees de test

#### Environnements Pennylane

- Production : app.pennylane.com
  - Donnees reelles (legales et fiscales).
- Test (sandbox) : sandbox.pennylane.com
  - Environnement isole pour developpement et tests.

#### Sandbox Company

Entreprise fictive dans l'environnement sandbox pour tester les appels API sans impact client reel.

| Environnement | URL de base | Type de compte / donnees | Usage |
| --- | --- | --- | --- |
| Test | sandbox.pennylane.com | Comptes de test | Tester les scripts de creation de dossiers (Provisioning API). |
| Test | sandbox.pennylane.com | Sandbox Company | Tester les echanges de donnees (Company API). |
| Production | app.pennylane.com | Comptes clients reels | Deploiement final du connecteur. |

## Authentification API Company

### Comparatif rapide

| Methode | Quand l'utiliser | Pour qui | Production |
| --- | --- | --- | --- |
| Token developpeur | Tester rapidement l'API Company sur une entreprise | Dev partenaire (tests) | Possible selon droits, recommande surtout pour tests |
| OAuth 2.0 | Connexion utilisateurs finaux (autorisation d'acces) | Integrations partenaires technologiques | Obligatoire |

### 1) Token developpeur (pour tester)

- Genere dans : Parametres entreprise -> Connectivite -> Developpeurs.
- Caracteristiques :
  - unique par entreprise,
  - scopes configurables,
  - expiration personnalisable,
  - revocable,
  - droits administrateur requis,
  - disponible en sandbox et production.
- Securite : ne jamais partager publiquement ; visible une seule fois a la creation.
- Doc : https://pennylane.readme.io/docs/generating-my-api-token

### 2) OAuth 2.0 (obligatoire pour les partenaires)

- Permet d'acceder aux donnees sans partager les identifiants utilisateur.
- Flow :
  - l'utilisateur clique sur "Se connecter avec Pennylane",
  - autorise les scopes,
  - l'application recoit :
    - access_token (24h),
    - refresh_token (90 jours).
- Avantages : securite, scopes fins, revocation, renouvellement automatique.
- Prerequis : validation partenaire.
- Doc : https://pennylane.readme.io/docs/oauth-20-walkthrough

## Parcours recommande (du test a la production)

1. Acces sandbox ouvert par l'equipe Partenariats.
2. Tests Company API avec token developpeur.
3. Implementation OAuth 2.0 (tests en sandbox).
4. Tests Provisioning API (si besoin).
5. Certification du connecteur.
6. Passage en production.

Guide sandbox : https://help.pennylane.com/fr/articles/18773-creer-un-environnement-de-test

## Reforme de la facturation electronique (RFE)

### Calendrier (rappel)

- Reception obligatoire :
  - T1 2026 : phase pilote volontaire
  - 1er septembre 2026 : toutes les entreprises
- Emission obligatoire (progressif) :
  - 1er septembre 2026 : grandes entreprises et ETI
  - 1er septembre 2027 : PME et TPE

### Guide integration PA Pennylane

- https://pennylane-hq.notion.site/Int-gration-PA-Pennylane-Guide-partenaires-21c2276c03bf80139e24eeba11390fd5?pvs=24

### Documentations techniques

- API Company : https://pennylane.readme.io/docs/api-overview
- API Provisioning : https://provisioning-pennylane.readme.io/reference/companycreate

## Fonctionnalites RFE

- Emettre une facture electronique vers la PA Pennylane
  - Endpoint : https://pennylane.readme.io/reference/createcustomerinvoiceeinvoiceimport
  - Doc Factur-X : https://scribetech.notion.site/Documentation-sur-l-import-FacturX-29c2276c03bf81da8e47cb76aab35ccb?pvs=25
- Recuperer une facture d'achat depuis la PA
  - Endpoint : https://pennylane.readme.io/reference/getsupplierinvoices
- Recuperer le statut d'une facture electronique
  - Voir champ e_invoicing.status
  - Mapping statuts : https://scribetech.notion.site/Mapping-Statuts-Pennylane-x-AFNOR-Dev-Toolkit-3252276c03bf800d8324d26ad62d4035?pvs=25
- Provisioning (creation compte client / entreprise)
  - Get companies : https://provisioning-pennylane.readme.io/reference/getcompanies
  - Create company : https://provisioning-pennylane.readme.io/reference/companycreate
  - Create user : https://provisioning-pennylane.readme.io/reference/postusers

## Endpoint PA Registrations

- Methode : GET
- URL : https://app.pennylane.com/api/external/v2/pa_registrations
- Auth : Bearer token (OAuth2 Company API)
- Pagination : cursor-based (next_cursor)

### Champs principaux

| Champ | Type | Description |
| --- | --- | --- |
| has_more | boolean | Indique s'il reste des resultats |
| next_cursor | string/null | Curseur de pagination ; null = derniere page |
| id | int64 | Identifiant unique |
| siret | string/null | SIRET de l'etablissement (vide au niveau SIREN) |
| siren | string | Numero SIREN |
| status | enum | provisioned / pending / activated |
| exchange_direction | enum | emission / reception / emission_and_reception |
| created_at | datetime | Date de creation |
| updated_at | datetime | Date de mise a jour |

### Statuts possibles (status)

| Valeur | Signification |
| --- | --- |
| provisioned | Enregistrement PA commence |
| pending | Validation annuaire en cours |
| activated | Enregistrement annuaire effectif |

### Directions d'echange (exchange_direction)

| Valeur | Signification |
| --- | --- |
| emission | Emission via PA Pennylane |
| reception | Reception via PA Pennylane |
| emission_and_reception | Emission + reception via PA Pennylane |

### Pagination

1. Requete initiale sans cursor.
2. Si has_more = true, rejouer avec ?cursor={next_cursor}.
3. Recommencer jusqu'a next_cursor = null.

## Cas d'usage par profil utilisateur

### 1) Utilisateur absent de Pennylane

- Provisioning utilisateur + entreprise.
- Onboarding dans l'interface Pennylane.
- Autorisation OAuth 2.0.
- Echanges RFE via Company API (emission / reception).

### 2) Utilisateur existant dans Pennylane

- Sans PA designee :
  1. Autoriser OAuth 2.0.
  2. Rediriger vers : https://app.pennylane.com/companies/<company_id>/pdp_activation
  3. Echanges RFE via Company API.
- Avec PA Pennylane designee : OAuth + echanges RFE.
- Avec autre PA designee : portabilite possible depuis l'interface Pennylane.

company_id recuperable via : https://pennylane.readme.io/reference/getme

## APIs AFNOR

- API AFNOR Flow
  - Doc : https://afnor-flow-api.readme.io/reference/getflow
  - Fonctionnalites annoncees (Q2 2026) : e-invoicing et e-reporting.
- API AFNOR Directory
  - Documentation a venir (Q2 2026).

## Ressources techniques

- Collection Postman : Pennylane - RFE endpoints examples.postman_collection.json
- Diagrammes de sequence (utilisateur absent / existant).
- Prototype UI : nexio-prototype-integration-pennylane-rfe-v9.html

## Temps d'echanges

### Webinaire decouverte API - RFE

- Inscription : https://app.livestorm.co/sales-marketing-pennylane/webinar-decouverte-api-rfe
- Replay : https://app.livestorm.co/p/b31d564c-bf85-4dcf-bdc3-b8efda703f3e/live?s=f7c9adfb-db01-48c6-8a7a-4216707288cf

### Partners Office Hours - Support technique

- Reservation : https://app.livestorm.co/sales-marketing-pennylane/partners-office-hours

## FAQ (themes)

1. Acces et authentification (OAuth, tests, redirect_uri, sandbox vs production, duree de vie tokens).
2. API et scopes/permissions (erreurs, limitations, idempotence, visibilite docs, suivi statuts).
3. Certification et publication (etapes, criteres, marketplace, support technique).

## Support et ressources

### Contacts

- Partenariats : partnerships@pennylane.com
- Support technique : https://pennylane3952.zendesk.com/hc/fr

### Liens utiles

- Termes contrat API : https://pennylane.readme.io/page/api-contract-terms
- Marketplace partenaires : https://www.pennylane.com/fr/integrations

### Checklist avant mise en production

- Validation partenaire effectuee
- Tests complets en sandbox
- Gestion erreurs implementee (429 + backoff)
- OAuth avec refresh token automatique
- Logging et monitoring configures
- Documentation utilisateur finalisee
- Tests de charge effectues

## Changelog et mises a jour

- Roadmap API : https://pennylane.readme.io/docs/api-public-roadmap
- API changelog : https://pennylane.readme.io/docs/stay-updated-with-our-api-changes

Ce toolkit est maintenu par l'equipe Partenariats de Pennylane.
Pour toute suggestion : partnerships@pennylane.com

---

Note : contenu transcrit et reformate en Markdown a partir de la page Notion source.
Certaines pieces jointes integrees (fichiers et elements visuels) peuvent necessiter une consultation directe de la page Notion pour recuperation exhaustive.