# Proposition commerciale — Connecteur Pennylane RFE pour WinDev

---

**Prestataire :** Lignes2Code  
**Contact :** contact@lignes2code.fr  
**Référence :** LC-2026-PENNYLANE-001  
**Date d'émission :** 27 avril 2026  
**Validité :** 30 jours

---

## 1. Contexte et enjeux

La **Réforme de la Facturation Électronique (RFE)** impose à toutes les entreprises assujetties à la TVA de pouvoir émettre et recevoir des factures électroniques via une **Plateforme de Dématérialisation Partenaire (PDP)** agréée.

**Pennylane est agréé PDP.** Son API REST v2 permet de couvrir intégralement les obligations légales :

| Échéance légale | Obligation |
|---|---|
| 1er septembre 2026 | Réception obligatoire — toutes entreprises |
| 1er septembre 2026 | Émission obligatoire — grandes entreprises et ETI |
| 1er septembre 2027 | Émission obligatoire — PME et TPE |

L'objectif de cette prestation est de **connecter votre logiciel WinDev à l'API Pennylane** afin d'automatiser les échanges de factures électroniques, sans que vos utilisateurs n'aient à quitter votre application.

---

## 2. Périmètre de la mission

### Phase 1 — Infrastructure et authentification

| # | Livrable | Description | Charge |
|---|---|---|---|
| 1.1 | **Architecture logicielle** | Conception complète — design patterns SOLID adaptés à WinDev/WLangage | 1 j |
| 1.2 | **Authentification OAuth 2.0** | Flow Authorization Code, anti-CSRF, échange de code, refresh automatique | 1 j |
| 1.3 | **Gestion de configuration** | Paramétrage JSON, bascule sandbox/production sans recompilation | 0,5 j |
| 1.4 | **Gestion des tokens** | Persistance sécurisée, vérification d'expiration automatique | 0,5 j |
| 1.5 | **Façade unifiée + bus d'événements** | Point d'entrée unique, notifications vers l'application maître | 0,5 j |
| 1.6 | **Composant OpenAPI + structures métier** | Typage fort de tous les objets Pennylane (factures, clients, fournisseurs) | 1 j |

**Charge Phase 1 : 4 jours**

---

### Phase 2 — Couche métier RFE

> Périmètre centré sur les obligations légales de la RFE (émission + réception de factures électroniques).

| # | Livrable | Description | Charge |
|---|---|---|---|
| 2.1 | **Factures clients** | Création, récupération, pagination, Factur-X (obligation sept. 2026) | 2 j |
| 2.2 | **Factures fournisseurs** | Récupération, statuts, pagination (obligation sept. 2026) | 0,5 j |
| 2.3 | **Client HTTP centralisé** | Gestion des headers, erreurs, sandbox/production | 0,5 j |

**Charge Phase 2 : 3 jours**

---

### Phase 3 — Intégration et recette

| # | Livrable | Description | Charge |
|---|---|---|---|
| 3.1 | **Intégration dans WinDev** | Connexion du composant à votre application maître | 1 j |
| 3.2 | **Tests et recette** | Validation sandbox + données réelles, correction des anomalies | 0,5 j |

**Charge Phase 3 : 1 jour**

---

## 3. Récapitulatif financier

| Phase | Description | Charge (jours) | TJM (€ HT) | Montant HT |
|---|---|---|---|---|
| Phase 1 | Infrastructure, auth OAuth2, composants WinDev | 4 j | _____ € | _____ € |
| Phase 2 | Factures clients + fournisseurs (RFE) | 3 j | _____ € | _____ € |
| Phase 3 | Intégration, tests, recette | 1 j | _____ € | _____ € |
| **TOTAL** | | **8 jours** | | **_____ €** |

> TVA applicable au taux légal en vigueur (20%).

---

## 4. Conditions de réalisation

### 4.1 Prérequis côté client

Pour démarrer la prestation, vous devez au préalable :

- [ ] **Valider le partenariat Pennylane** : formulaire sur https://www.pennylane.com/fr/partenaires/partenaire-technologique/
- [ ] **Obtenir les identifiants OAuth 2.0** : `client_id` et `client_secret` fournis par l'équipe Pennylane après validation
- [ ] **Accès sandbox Pennylane** : fourni par Pennylane après validation du partenariat
- [ ] **Accès au projet WinDev** : dépôt source, environnement de compilation

> Sans ces éléments, l'implémentation OAuth 2.0 et les tests sandbox ne sont pas réalisables.

### 4.2 Livrables attendus à chaque phase

- **Phase 1** : Code source WinDev (7 classes .wl), composant OpenAPI, POC de validation
- **Phase 2** : Code source WinDev (2 repositories .wl + HTTP client), POC par endpoint
- **Phase 3** : Composant WinDev intégré, rapport de recette

### 4.3 Modalités

| | |
|---|---|
| **Mode de travail** | Régie ou forfait (à définir) |
| **Réunions de suivi** | Point hebdomadaire de 30 min |
| **Facturation** | 30% à la commande, 40% à la livraison Phase 2, 30% à la recette |
| **Garantie** | 30 jours après recette |

---

## 5. Exclusions

Ne sont pas compris dans cette prestation :
- La souscription à l'offre PDP Pennylane (contrat entre le client et Pennylane)
- La gestion des données fiscales et légales (responsabilité du client)
- La formation des utilisateurs finaux
- L'hébergement et les coûts d'infrastructure
- Les développements spécifiques non listés ci-dessus

---

## 6. Pour nous contacter

**Lignes2Code**  
contact@lignes2code.fr  

---

*Ce document est une proposition commerciale confidentielle établie à l'attention exclusive du destinataire. Toute reproduction ou diffusion est interdite sans accord préalable.*
