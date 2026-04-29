# Connecteur Pennylane RFE — WinDev

> **Référence :** LC-2026-PENNYLANE-001 — Version validée client
> **Date :** 29 avril 2026
> **Durée totale :** 7 jours

---

## Titre de la mission _(à coller dans Malt)_

```
Développement d'un connecteur WinDev vers l'API Pennylane (Réforme Facturation Électronique — RFE)
```

---

## Description de la mission _(à coller dans Malt)_

```
Développement d'un composant WinDev permettant de connecter un logiciel de gestion existant
à l'API REST v2 de Pennylane, plateforme de dématérialisation partenaire (PDP) agréée dans
le cadre de la Réforme de la Facturation Électronique (RFE).

La mission couvre l'ensemble de la chaîne d'intégration : authentification OAuth 2.0,
gestion des factures clients et fournisseurs (Factur-X), fenêtres de connexion et de
provisioning, ainsi que la recette en environnement sandbox et production.

Contexte légal :
- 1er septembre 2026 : obligation de réception pour toutes les entreprises
- 1er septembre 2026 : obligation d'émission pour les grandes entreprises et ETI
- 1er septembre 2027 : obligation d'émission pour les PME et TPE
```

---

## Livrables / Périmètre _(à coller dans Malt)_

```
PHASE 1 — Infrastructure et authentification (2 jours)
──────────────────────────────────────────────────────
• Architecture logicielle simplifiée en WLangage
• Authentification OAuth 2.0 : Flow Authorization Code, gestion du refresh token
• Gestion de configuration : bascule sandbox / production sans recompilation
• Gestion des tokens : persistance et vérification d'expiration automatique
• Composant OpenAPI + structures métier typées (factures, clients, fournisseurs)

PHASE 2 — Couche métier RFE (2,5 jours)
────────────────────────────────────────
• Factures clients : création, récupération, pagination, support Factur-X
• Factures fournisseurs : récupération, gestion des statuts, pagination
• Client HTTP centralisé : headers, gestion d'erreurs, multi-environnements

PHASE 3 — Intégration et recette (2,5 jours)
─────────────────────────────────────────────
• Fenêtre WinDev de connexion OAuth (lancement autorisation, saisie du code, validation)
• Fenêtre de provisioning / création d'utilisateur Pennylane (1re utilisation)
• Intégration dans l'application maître WinDev
• Tests et recette : validation sandbox + données réelles, correction des anomalies

──────────────────────────────────────────────────────
TOTAL : 7 jours
```

---

## Conditions _(à coller dans Malt)_

```
Prérequis côté client (nécessaires avant démarrage) :
• Partenariat Pennylane validé (formulaire sur pennylane.com)
• Identifiants OAuth 2.0 (client_id / client_secret) fournis par Pennylane
• Accès à l'environnement sandbox Pennylane
• Accès au projet WinDev (dépôt source, environnement de compilation)

Modalités :
• Facturation : 30 % à la commande / 40 % à la livraison Phase 2 / 30 % à la recette
• Garantie : 30 jours après recette
• Suivi : point hebdomadaire de 30 min

Exclusions :
• Souscription à l'offre PDP Pennylane (contrat direct client / Pennylane)
• Formation des utilisateurs finaux
• Hébergement et infrastructure
• Développements non listés ci-dessus
```

---

## Notes internes

- Devis original : 10 jours — version négociée validée par le client : **7 jours**
- Architecture simplifiée (sans design patterns SOLID) par rapport à la proposition initiale
- Phase 3 enrichie : ajout fenêtre de provisioning et fenêtre OAuth vs version initiale
