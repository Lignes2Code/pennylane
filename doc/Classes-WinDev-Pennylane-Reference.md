# Référence des classes WinDev — Connecteur Pennylane RFE

**Source API :** OpenAPI 3.0.1 — Accounting v2 (`accounting.json`) — 119 endpoints  
**Composant :** `PennylaneConnecteur.wdp`

---

## CPennylaneConfig

**Fichier :** `Config/CPennylaneConfig.wdp`  
**Rôle :** Lecture/écriture du fichier de configuration local chiffré. Aucune donnée sensible en clair.  
**Pattern :** Value Object + persistance fichier

### Attributs

| Attribut | Type WinDev | Description |
|---|---|---|
| `CheminFichier` | Chaîne | Chemin complet du fichier `.cfg` sur le poste |
| `Environnement` | Chaîne | `"SANDBOX"` ou `"PRODUCTION"` |
| `BaseURL` | Chaîne | URL de base déduite de `Environnement` |
| `BaseURLProvisioning` | Chaîne | URL API Provisioning |
| `ClientID` | Chaîne | OAuth client_id (chiffré dans le fichier) |
| `ClientSecret` | Chaîne | OAuth client_secret (chiffré dans le fichier) |
| `RedirectURI` | Chaîne | ex. `http://localhost:9753/oauth/callback` |
| `CompanyID` | Chaîne | company_id Pennylane de l'utilisateur connecté |
| `UserID` | Chaîne | user_id Pennylane |

### Constantes

```wlangage
CONSTANTE
    ENV_SANDBOX     = "SANDBOX"
    ENV_PRODUCTION  = "PRODUCTION"
    URL_SANDBOX     = "https://sandbox.pennylane.com"
    URL_PRODUCTION  = "https://app.pennylane.com"
    URL_PROV        = "https://app.pennylane.com/api/partner/v2"
    API_BASE        = "/api/external/v2"
FIN
```

### Méthodes

| Méthode | Signature | Description |
|---|---|---|
| `Charger` | `Charger(cheminFichier : Chaîne) : Booléen` | Lit et déchiffre le fichier `.cfg` |
| `Sauvegarder` | `Sauvegarder() : Booléen` | Chiffre et écrit le fichier `.cfg` |
| `URLComplete` | `URLComplete(endpoint : Chaîne) : Chaîne` | Concatène `BaseURL + API_BASE + endpoint` |
| `EstConfigurer` | `EstConfigurer() : Booléen` | Vérifie que `ClientID` et `ClientSecret` sont renseignés |

### Chiffrement

> **Fonctions correctes WLangage :** `ChiffreAES()` / `DéchiffreAES()` **n'existent pas**. Utiliser `CryptageSymétrique` + `Crypte()` / `Décrypte()`.

```wlangage
// Chiffrer une valeur (ex: access_token) avant stockage
PROCÉDURE PRIVÉE ChiffrerValeur(valeur est une Chaîne, cle est une Chaîne) : Buffer
    monCryptage est un CryptageSymétrique
    monCryptage.Algorithme  = cryptAES256CBC
    monCryptage.CléSecrète  = SHA2(cle)  // Clé 256 bits dérivée via SHA-256
    RETOURNER Crypte(monCryptage, valeur)
FIN

// Déchiffrer
PROCÉDURE PRIVÉE DéchiffrerValeur(données est un Buffer, cle est une Chaîne) : Chaîne
    monCryptage est un CryptageSymétrique
    monCryptage.Algorithme  = cryptAES256CBC
    monCryptage.CléSecrète  = SHA2(cle)
    RETOURNER Décrypte(monCryptage, données)
FIN
```

- Clé `cle` dérivée de : `NomMachine() + NomUtilisateur()` — jamais stockée dans le fichier.
- `SHA2()` retourne un `Buffer` de 32 octets = clé AES-256 valide.

---

## CPennylaneToken

**Fichier :** `Config/CPennylaneToken.wdp`  
**Rôle :** Value Object immuable représentant un token OAuth.

### Attributs

| Attribut | Type WinDev | Description |
|---|---|---|
| `Valeur` | Chaîne | Valeur brute du token JWT |
| `DateExpiration` | DateHeure | Timestamp d'expiration |
| `Scopes` | Chaîne | Scopes accordés (séparés par espace) |
| `Type` | Chaîne | `"Bearer"` |

### Méthodes

| Méthode | Signature | Description |
|---|---|---|
| `EstValide` | `EstValide() : Booléen` | `DateHeureSystème() < DateExpiration - 60s` |
| `Header` | `Header() : Chaîne` | Retourne `"Bearer " + Valeur` |

---

## CPennylaneTokenStore

**Fichier :** `Config/CPennylaneTokenStore.wdp`  
**Rôle :** Persiste et recharge les tokens depuis `CPennylaneConfig`.

### Attributs

| Attribut | Type WinDev | Description |
|---|---|---|
| `TokenAcces` | CPennylaneToken | Token d'accès courant (durée 24h) |
| `TokenRafraichissement` | CPennylaneToken | Refresh token (durée 90 jours) |
| `oConfig` | CPennylaneConfig | Référence à la configuration |

### Méthodes

| Méthode | Signature | Description |
|---|---|---|
| `Stocker` | `Stocker(acces, refresh : Chaîne, expiresIn : Entier)` | Construit et persiste les deux tokens |
| `Charger` | `Charger() : Booléen` | Recharge depuis `oConfig` |
| `TokenAccesValide` | `TokenAccesValide() : Booléen` | `TokenAcces.EstValide()` |
| `Effacer` | `Effacer()` | Supprime les tokens (déconnexion) |

---

## IAuthStrategy (Interface)

**Fichier :** `Auth/IAuthStrategy.wdp`  
**Rôle :** Contrat commun des deux méthodes d'authentification.  
**Pattern :** Strategy

### Méthodes abstraites

| Méthode | Signature | Description |
|---|---|---|
| `ObtenirHeader` | `ObtenirHeader() : Chaîne` | Retourne `"Bearer <token>"` |
| `EstValide` | `EstValide() : Booléen` | Vérifie la validité du token courant |
| `Rafraichir` | `Rafraichir() : Booléen` | Renouvelle le token si possible |
| `Authentifier` | `Authentifier() : Booléen` | Lance l'authentification complète |

---

## CPennylaneDevTokenAuth

**Fichier :** `Auth/CPennylaneDevTokenAuth.wdp`  
**Rôle :** Authentification par token développeur (tests uniquement).  
**Implémente :** `IAuthStrategy`

### Attributs

| Attribut | Type | Description |
|---|---|---|
| `TokenDev` | Chaîne | Token fixe chargé depuis `CPennylaneConfig` |

### Méthodes

| Méthode | Description |
|---|---|
| `ObtenirHeader()` | Retourne `"Bearer " + TokenDev` |
| `EstValide()` | Retourne `TokenDev <> ""` |
| `Rafraichir()` | Retourne `Faux` (le token dev ne se rafraîchit pas) |
| `Authentifier()` | Charge `TokenDev` depuis la config |

---

## CPennylaneOAuth2Auth

**Fichier :** `Auth/CPennylaneOAuth2Auth.wdp`  
**Rôle :** Flow Authorization Code complet + refresh automatique.  
**Implémente :** `IAuthStrategy`

### Attributs

| Attribut | Type | Description |
|---|---|---|
| `oConfig` | CPennylaneConfig | Référence config |
| `oTokenStore` | CPennylaneTokenStore | Référence token store |
| `oEventBus` | CPennylaneEventBus | Pour publier `SurTokenRefraichi` |
| `StateOAuth` | Chaîne | Valeur aléatoire anti-CSRF |
| `PortLocal` | Entier | Port du serveur de callback (défaut : 9753) |

### Méthodes

| Méthode | Signature | Description |
|---|---|---|
| `LancerFlow` | `LancerFlow() : Booléen` | Ouvre navigateur + attend le callback |
| `ObtenirHeader` | `ObtenirHeader() : Chaîne` | Vérifie et rafraîchit si besoin, retourne le header |
| `EstValide` | `EstValide() : Booléen` | `oTokenStore.TokenAccesValide()` |
| `Rafraichir` | `Rafraichir() : Booléen` | POST `/oauth/token` avec `grant_type=refresh_token` |
| `EchangerCode` | `EchangerCode(code : Chaîne) : Booléen` | POST `/oauth/token` avec `grant_type=authorization_code` |
| `ConstruireURLAuth` | `ConstruireURLAuth() : Chaîne` | Construit l'URL avec `client_id`, `scopes`, `state` |

### Scopes requis (RFE)

```
customer_invoices:all
supplier_invoices:all
```

### Endpoint token

```
POST https://app.pennylane.com/oauth/token
Content-Type: application/x-www-form-urlencoded

// Authorization Code
grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>

// Refresh
grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

---

## CPennylaneHttpResponse

**Fichier :** `Http/CPennylaneHttpResponse.wdp`  
**Rôle :** Encapsule la réponse HTTP brute.

### Attributs

| Attribut | Type | Description |
|---|---|---|
| `CodeHTTP` | Entier | Code de statut (200, 401, 429…) |
| `Corps` | Chaîne | Corps de la réponse JSON |
| `CorpsBuffer` | Buffer | Corps binaire (pour les PDF) |
| `EstSucces` | Booléen | `CodeHTTP >= 200 ET CodeHTTP < 300` |
| `MessageErreur` | Chaîne | Message parsé en cas d'erreur |

---

## CPennylaneHttpClient

**Fichier :** `Http/CPennylaneHttpClient.wdp`  
**Rôle :** Effectue tous les appels HTTP avec headers, retry backoff, et gestion des erreurs.  
**Pattern :** Decorator (retry wrapping)

### Attributs

| Attribut | Type | Description |
|---|---|---|
| `oAuth` | IAuthStrategy | Stratégie d'auth injectée |
| `oConfig` | CPennylaneConfig | Pour l'URL de base |
| `oEventBus` | CPennylaneEventBus | Pour publier les erreurs |
| `MaxTentatives` | Entier | Défaut : 5 |
| `DelaiInitialCS` | Entier | Délai initial backoff en **centièmes de seconde** (défaut : **100** = 1 seconde). `Attendre()` en WLangage prend des centièmes de seconde, PAS des millisecondes. |

### Méthodes

| Méthode | Signature | Description |
|---|---|---|
| `Get` | `Get(endpoint : Chaîne, params : Chaîne) : CPennylaneHttpResponse` | GET avec query string |
| `Post` | `Post(endpoint : Chaîne, corps : Chaîne) : CPennylaneHttpResponse` | POST JSON |
| `PostMultipart` | `PostMultipart(endpoint : Chaîne, cheminFichier : Chaîne) : CPennylaneHttpResponse` | POST multipart/form-data avec fichier |
| `Put` | `Put(endpoint : Chaîne, corps : Chaîne) : CPennylaneHttpResponse` | PUT JSON |
| `Delete` | `Delete(endpoint : Chaîne) : CPennylaneHttpResponse` | DELETE |
| `GetBuffer` | `GetBuffer(url : Chaîne) : Buffer` | Télécharge une ressource binaire (PDF) |

### Logique de retry (interne)

> **Rappel WLangage :** `Attendre(n)` prend `n` en **centièmes de seconde** (CS).  
> `Attendre(100)` = 1 seconde. Ou utiliser la syntaxe `Durée` : `Attendre(1 s)` (v23+).

```wlangage
PROCÉDURE PRIVÉE ExecuterAvecRetry(fnAppel est une Procédure) : CPennylaneHttpResponse
    delaiCS   <- DelaiInitialCS    // 100 CS = 1 seconde
    tentative <- 1
    TANTQUE tentative <= MaxTentatives
        rep <- Exécute(fnAppel)
        SELON rep.CodeHTTP
            CAS 429, 500, 502, 503 :
                Attendre(delaiCS)          // Centièmes de seconde
                delaiCS   <- delaiCS * 2   // Backoff : 100, 200, 400, 800, 1600 cs
                tentative <- tentative + 1
            CAS 401 :
                SI oAuth.Rafraichir() ALORS
                    tentative <- tentative + 1
                SINON
                    oEventBus.PublierErreur("AUTH_EXPIRED", "")
                    RETOURNER rep
                FIN
            AUTRECAS
                RETOURNER rep
        FIN
    FIN
    RETOURNER rep
FIN
```

---

## CPennylanePaginatedResult

**Fichier :** `Models/CPennylanePaginatedResult.wdp`  
**Rôle :** Encapsule le résultat paginé d'un endpoint cursor-based.  
**Pattern :** Value Object générique (simulé en WinDev avec tableau d'objets)

### Attributs

| Attribut | Type | Description |
|---|---|---|
| `APlus` | Booléen | `has_more` — indique s'il reste des pages |
| `CurseurSuivant` | Chaîne | `next_cursor` — `""` si dernière page |
| `Elements` | Tableau d'objets | Items de la page courante |
| `Total` | Entier | Nombre d'éléments dans cette page |

---

## CPennylaneUserProfile

**Fichier :** `Models/CPennylaneUserProfile.wdp`  
**Rôle :** Profil de l'utilisateur connecté.  
**Endpoint source :** `GET /api/external/v2/me`

### Attributs

| Attribut | Type | Champ API |
|---|---|---|
| `ID` | Entier sur 8 octets | `id` |
| `Email` | Chaîne | `email` |
| `Prenom` | Chaîne | `first_name` |
| `Nom` | Chaîne | `last_name` |
| `Locale` | Chaîne | `locale` |
| `CompanyID` | Chaîne | `company.id` |
| `CompanyNom` | Chaîne | `company.name` |
| `Statut` | Chaîne | `status` |

---

## CPennylaneCustomer

**Fichier :** `Models/CPennylaneCustomer.wdp`  
**Endpoints source :** `GET /api/external/v2/customers`, `GET /api/external/v2/customers/{id}`

### Attributs

| Attribut | Type | Champ API |
|---|---|---|
| `ID` | Chaîne | `id` |
| `Nom` | Chaîne | `name` |
| `Prenom` | Chaîne | `first_name` |
| `NumeroClient` | Chaîne | `reference` |
| `TypeClient` | Chaîne | `customer_type` (company/individual) |
| `Email` | Chaîne | `emails` (premier) |
| `Telephone` | Chaîne | `phone` |
| `Adresse` | Chaîne | `address` |
| `Ville` | Chaîne | `city` |
| `CodePostal` | Chaîne | `postal_code` |
| `PaysAlpha2` | Chaîne | `country_alpha2` |
| `NumeroTVA` | Chaîne | `vat_number` |
| `SIREN` | Chaîne | `reg_no` |
| `DateCreation` | DateHeure | `created_at` |
| `DateMAJ` | DateHeure | `updated_at` |

---

## CPennylaneSupplier

**Fichier :** `Models/CPennylaneSupplier.wdp`  
**Endpoints source :** `GET /api/external/v2/suppliers`, `GET /api/external/v2/suppliers/{id}`

### Attributs

| Attribut | Type | Champ API |
|---|---|---|
| `ID` | Chaîne | `id` |
| `Nom` | Chaîne | `name` |
| `NumeroFournisseur` | Chaîne | `number` |
| `Email` | Chaîne | `emails` (premier) |
| `Adresse` | Chaîne | `address` |
| `Ville` | Chaîne | `city` |
| `CodePostal` | Chaîne | `postal_code` |
| `PaysAlpha2` | Chaîne | `country_alpha2` |
| `NumeroTVA` | Chaîne | `vat_number` |
| `IBAN` | Chaîne | `iban` |
| `ModePaiement` | Chaîne | `supplier_payment_method` |
| `DelaiPaiement` | Entier | `supplier_due_date_delay` |
| `DateCreation` | DateHeure | `created_at` |
| `DateMAJ` | DateHeure | `updated_at` |

---

## CPennylaneEInvoicing

**Fichier :** `Models/CPennylaneEInvoicing.wdp`  
**Rôle :** Cycle de vie e-invoicing géré par la PA Pennylane.  
**Champ source :** `e_invoicing` dans les réponses supplier/customer invoices

### Attributs

| Attribut | Type | Champ API |
|---|---|---|
| `Statut` | Chaîne | `status` |
| `Motif` | Chaîne | `reason` (nullable) |

### Valeurs de statut possibles

| Valeur | Signification |
|---|---|
| `submitted` | Soumis à la PA |
| `sent` | Transmis au destinataire |
| `accepted` | Accepté par le destinataire |
| `in_dispute` | En litige |
| `refused` | Refusé |
| `rejected` | Rejeté par la PA |
| `approved` | Litige annulé / approuvé |
| `collected` | Payé |
| `partially_collected` | Partiellement payé |

---

## CPennylaneInvoiceLine

**Fichier :** `Models/CPennylaneInvoiceLine.wdp`  
**Rôle :** Ligne d'une facture (client ou fournisseur).

### Attributs

| Attribut | Type | Champ API |
|---|---|---|
| `ID` | Chaîne | `id` |
| `Label` | Chaîne | `label` |
| `Quantite` | Réel | `quantity` |
| `PrixUnitaireBrut` | Réel | `raw_currency_unit_price` |
| `TauxTVA` | Chaîne | `vat_rate` |
| `Remise` | Réel | `discount` |
| `Devise` | Chaîne | `currency` |
| `IDProduit` | Chaîne | `product_id` |
| `Rang` | Entier | `rank` |

---

## CPennylaneCustomerInvoice

**Fichier :** `Models/CPennylaneCustomerInvoice.wdp`  
**Endpoints source :**
- `POST /api/external/v2/customer_invoices` — Créer
- `POST /api/external/v2/customer_invoices/e_invoices/imports` — Importer Factur-X
- `GET /api/external/v2/customer_invoices/{id}` — Lire
- `PUT /api/external/v2/customer_invoices/{id}/finalize` — Finaliser
- `PUT /api/external/v2/customer_invoices/{id}/mark_as_paid` — Marquer payé
- `POST /api/external/v2/customer_invoices/{id}/send_by_email` — Envoyer par mail

### Attributs

| Attribut | Type | Champ API |
|---|---|---|
| `ID` | Chaîne | `id` |
| `Label` | Chaîne | `label` |
| `Statut` | Chaîne | `status` (voir enum ci-dessous) |
| `DateFacture` | Date | `date` |
| `DateEcheance` | Date | `deadline` |
| `Devise` | Chaîne | `currency` |
| `ReferenceExterne` | Chaîne | `external_reference` |
| `IDClient` | Chaîne | `customer_id` |
| `EInvoicing` | CPennylaneEInvoicing | `e_invoicing` |
| `Lignes` | Tableau de CPennylaneInvoiceLine | `invoice_lines` |
| `DateCreation` | DateHeure | `created_at` |
| `DateMAJ` | DateHeure | `updated_at` |

### Statuts (enum `status`)

`draft` · `outstanding` · `late` · `paid` · `cancelled`

---

## CPennylaneSupplierInvoice

**Fichier :** `Models/CPennylaneSupplierInvoice.wdp`  
**Endpoints source :**
- `GET /api/external/v2/supplier_invoices` — Lister
- `GET /api/external/v2/supplier_invoices/{id}` — Lire
- `PUT /api/external/v2/supplier_invoices/{id}/validate_accounting` — Valider comptabilité
- `PUT /api/external/v2/supplier_invoices/{sup_id}/e_invoice_status` — Mettre à jour statut PA
- `PUT /api/external/v2/supplier_invoices/{sup_id}/payment_status` — Mettre à jour statut paiement
- `POST /api/external/v2/supplier_invoices/e_invoices/imports` — Importer Factur-X fournisseur

### Attributs

| Attribut | Type | Champ API |
|---|---|---|
| `ID` | Chaîne | `id` |
| `Label` | Chaîne | `label` |
| `Statut` | Chaîne | `status` |
| `NumeroFacture` | Chaîne | `invoice_number` |
| `DateFacture` | Date | `date` |
| `DateEcheance` | Date | `deadline` |
| `Devise` | Chaîne | `currency` |
| `Montant` | Réel | `amount` |
| `MontantDevise` | Réel | `currency_amount` |
| `MontantHTDevise` | Réel | `currency_amount_before_tax` |
| `TVADevise` | Réel | `currency_tax` |
| `TauxChange` | Réel | `exchange_rate` |
| `StatutPaiement` | Chaîne | `payment_status` |
| `MontantRestantTTC` | Réel | `remaining_amount_with_tax` |
| `MontantRestantHT` | Réel | `remaining_amount_without_tax` |
| `URLFichierPublic` | Chaîne | `public_file_url` |
| `NomFichier` | Chaîne | `filename` |
| `EInvoicing` | CPennylaneEInvoicing | `e_invoicing` |
| `Fournisseur` | CPennylaneSupplier | `supplier` |
| `Lignes` | Tableau de CPennylaneInvoiceLine | `invoice_lines` |
| `DateCreation` | DateHeure | `created_at` |

---

## CPennylanePARegistration

**Fichier :** `Models/CPennylanePARegistration.wdp`  
**Endpoints source :**
- `GET /api/external/v2/pa_registrations` (Company API)
- `GET /api/partner/v2/companies/{id}/pa_registrations` (Provisioning API)

### Attributs

| Attribut | Type | Champ API |
|---|---|---|
| `ID` | Entier sur 8 octets | `id` |
| `SIREN` | Chaîne | `siren` |
| `SIRET` | Chaîne | `siret` (vide = inscription niveau SIREN) |
| `Statut` | Chaîne | `status` |
| `DirectionEchange` | Chaîne | `exchange_direction` |
| `DateCreation` | DateHeure | `created_at` |
| `DateMAJ` | DateHeure | `updated_at` |

### Valeurs `statut`

| Valeur | Signification |
|---|---|
| `provisioned` | Enregistrement PA démarré |
| `pending` | Validation annuaire en cours |
| `activated` | Entreprise inscrite et active |

### Valeurs `exchange_direction`

| Valeur | Signification |
|---|---|
| `emission` | Émet via PA Pennylane uniquement |
| `reception` | Reçoit via PA Pennylane uniquement |
| `emission_and_reception` | Émet et reçoit via PA Pennylane |

---

## IRepository (Interface générique)

**Fichier :** `Repositories/IRepository.wdp`  
**Pattern :** Repository

```wlangage
INTERFACE IRepository
    PROCÉDURE Lister(params : Chaîne) : CPennylanePaginatedResult
    PROCÉDURE ListerTout(params : Chaîne) : Tableau
    PROCÉDURE ParID(id : Chaîne) : Objet
FIN
```

---

## CCustomerInvoiceRepository

**Fichier :** `Repositories/CCustomerInvoiceRepository.wdp`  
**Implémente :** `IRepository`

### Méthodes

| Méthode | Endpoint | Description |
|---|---|---|
| `Lister(params)` | `GET /customer_invoices` | Liste paginée avec filtres |
| `ListerTout(params)` | `GET /customer_invoices` (loop) | Dépile toutes les pages automatiquement |
| `ParID(id)` | `GET /customer_invoices/{id}` | Facture par ID |
| `Creer(facture)` | `POST /customer_invoices` | Crée une facture brouillon |
| `ImporterFacturX(cheminPDF)` | `POST /customer_invoices/e_invoices/imports` | Importe un Factur-X depuis un chemin PDF |
| `Finaliser(id)` | `PUT /customer_invoices/{id}/finalize` | Finalise la facture |
| `MarquerPayee(id, params)` | `PUT /customer_invoices/{id}/mark_as_paid` | Marque comme payée |
| `EnvoyerParEmail(id)` | `POST /customer_invoices/{id}/send_by_email` | Envoie par email |
| `ListerLignes(id)` | `GET /customer_invoices/{id}/invoice_lines` | Lignes de la facture |

---

## CSupplierInvoiceRepository

**Fichier :** `Repositories/CSupplierInvoiceRepository.wdp`  
**Implémente :** `IRepository`

### Méthodes

| Méthode | Endpoint | Description |
|---|---|---|
| `Lister(params)` | `GET /supplier_invoices` | Liste paginée |
| `ListerTout(params)` | `GET /supplier_invoices` (loop) | Toutes les pages |
| `ParID(id)` | `GET /supplier_invoices/{id}` | Facture fournisseur par ID |
| `RecupererPDF(id)` | `GET public_file_url` | Télécharge le PDF en tant que Buffer |
| `MettreAJourStatutEInvoice(id, statut, motif)` | `PUT /supplier_invoices/{id}/e_invoice_status` | Disputer / Refuser / Approuver |
| `MettreAJourStatutPaiement(id, statut)` | `PUT /supplier_invoices/{id}/payment_status` | Met à jour statut paiement |
| `ValiderComptabilite(id)` | `PUT /supplier_invoices/{id}/validate_accounting` | Valide la comptabilité |
| `ImporterFacturX(cheminPDF)` | `POST /supplier_invoices/e_invoices/imports` | Importe un Factur-X fournisseur |
| `LierDemandeAchat(id, idDA)` | `POST /supplier_invoices/{id}/linked_purchase_requests` | Lie une demande d'achat |

### Méthode `MettreAJourStatutEInvoice` — détail

```wlangage
PROCÉDURE MettreAJourStatutEInvoice(
    id     : Chaîne,
    statut : Chaîne,   // "disputed" | "refused" | "approved"
    motif  : Chaîne    // Obligatoire pour disputed et refused
) : Booléen
// Scope requis : supplier_invoices:all
// PUT /api/external/v2/supplier_invoices/{id}/e_invoice_status
// Body : {"status": statut, "reason": motif}
```

---

## CPARegistrationRepository

**Fichier :** `Repositories/CPARegistrationRepository.wdp`  
**Implémente :** `IRepository`

### Méthodes

| Méthode | Endpoint | Description |
|---|---|---|
| `Lister(params)` | `GET /pa_registrations` | Liste paginée des inscriptions PA |
| `ListerTout(params)` | `GET /pa_registrations` (loop) | Toutes les inscriptions (pagination auto) |
| `EstInscrit(siren)` | Dérivée de `ListerTout` | Vérifie si un SIREN est `activated` |
| `ObtenirDirection(siren)` | Dérivée de `ListerTout` | Retourne `exchange_direction` pour un SIREN |

### Algorithme de pagination

> **Correction :** `AjouterAuTableau()` **n'existe pas** en WLangage. Utiliser `Ajoute()` dans une boucle `POUR TOUT`.

```wlangage
PROCÉDURE ListerTout(params est une Chaîne) : Tableau de CPennylanePARegistration
    resultats est un tableau de CPennylanePARegistration
    curseur   est une Chaîne = ""
    TANTQUE Vrai
        rep <- oHttp.Get("/pa_registrations", params + "&cursor=" + curseur)
        page est un CPennylanePaginatedResult = DeserialiserPage(rep.Corps)
        // Ajouter les éléments un par un — AjouterAuTableau() n'existe pas
        POUR TOUT elem DE page.Elements
            Ajoute(resultats, elem)
        FIN
        SI PAS page.APlus ALORS QUITTER
        curseur <- page.CurseurSuivant
    FIN
    RETOURNER resultats
FIN
```

---

## CCustomerRepository

**Fichier :** `Repositories/CCustomerRepository.wdp`

### Méthodes

| Méthode | Endpoint | Description |
|---|---|---|
| `Lister(params)` | `GET /customers` | Liste paginée des clients |
| `ParID(id)` | `GET /customers/{id}` | Client par ID |
| `ListerContacts(id)` | `GET /customers/{id}/contacts` | Contacts du client |
| `ListerChangements(depuis)` | `GET /changelogs/customers` | Clients modifiés depuis une date |

---

## CSupplierRepository

**Fichier :** `Repositories/CSupplierRepository.wdp`

### Méthodes

| Méthode | Endpoint | Description |
|---|---|---|
| `Lister(params)` | `GET /suppliers` | Liste paginée des fournisseurs |
| `ParID(id)` | `GET /suppliers/{id}` | Fournisseur par ID |
| `ListerChangements(depuis)` | `GET /changelogs/suppliers` | Fournisseurs modifiés depuis une date |

---

## CProvisioningRepository

**Fichier :** `Repositories/CProvisioningRepository.wdp`  
**Rôle :** Appels à l'API Provisioning (différente de la Company API).  
**Base URL :** `https://app.pennylane.com/api/partner/v2`  
**Auth :** Client Credentials (`grant_type=client_credentials`)

### Méthodes

| Méthode | Endpoint Provisioning | Description |
|---|---|---|
| `CreerUtilisateur(email, prenom, nom)` | `POST /users` | Crée un utilisateur — retourne user_id |
| `CreerEntreprise(nom, siren, plan)` | `POST /companies` | Crée une entreprise — retourne company_id |
| `ListerEntreprises()` | `GET /companies` | Liste les entreprises provisionnées |
| `ObtenirInscriptionsPA(companyId)` | `GET /companies/{id}/pa_registrations` | Inscriptions PA via Provisioning |
| `ObtenirTokenProvisioning()` | `POST /oauth/token` (client_credentials) | Token dédié Provisioning |

### Création entreprise — paramètre plan

```wlangage
// plan = "v1_freemium" pour usage PA gratuit
// Retourne company_id à stocker dans CPennylaneConfig
```

---

## IObserver (Interface)

**Fichier :** `Events/IObserver.wdp`  
**Pattern :** Observer

```wlangage
INTERFACE IObserver
    PROCÉDURE SurTokenRefraichi(oToken : CPennylaneToken)
    PROCÉDURE SurFactureEmise(oFacture : CPennylaneCustomerInvoice)
    PROCÉDURE SurFactureRecue(oFacture : CPennylaneSupplierInvoice)
    PROCÉDURE SurStatutChange(id : Chaîne, statut : Chaîne)
    PROCÉDURE SurErreur(code : Chaîne, message : Chaîne)
FIN
```

---

## CPennylaneEventBus

**Fichier :** `Events/CPennylaneEventBus.wdp`  
**Pattern :** Observer / Event Bus

### Attributs

| Attribut | Type | Description |
|---|---|---|
| `Observateurs` | Tableau de IObserver | Liste des abonnés |

### Méthodes

| Méthode | Signature | Description |
|---|---|---|
| `Abonner` | `Abonner(obs : IObserver)` | Ajoute un observateur |
| `Desabonner` | `Desabonner(obs : IObserver)` | Retire un observateur |
| `PublierTokenRefraichi` | `PublierTokenRefraichi(token)` | Notifie tous les observateurs |
| `PublierFactureEmise` | `PublierFactureEmise(facture)` | Notifie facture émise |
| `PublierFactureRecue` | `PublierFactureRecue(facture)` | Notifie facture reçue |
| `PublierStatutChange` | `PublierStatutChange(id, statut)` | Notifie changement de statut |
| `PublierErreur` | `PublierErreur(code, message)` | Notifie une erreur |

---

## CPennylaneFacade

**Fichier :** `CPennylaneFacade.wdp`  
**Rôle :** Point d'entrée unique du composant WinDev. C'est la seule classe exposée à l'application maître.  
**Pattern :** Facade + Dependency Injection

### Attributs (privés — infrastructure)

| Attribut | Type |
|---|---|
| `oConfig` | CPennylaneConfig |
| `oTokenStore` | CPennylaneTokenStore |
| `oAuth` | IAuthStrategy |
| `oHttp` | CPennylaneHttpClient |
| `oEventBus` | CPennylaneEventBus |
| `oRepoFacturesClient` | CCustomerInvoiceRepository |
| `oRepoFacturesFourn` | CSupplierInvoiceRepository |
| `oRepoPA` | CPARegistrationRepository |
| `oRepoClients` | CCustomerRepository |
| `oRepoFournisseurs` | CSupplierRepository |
| `oRepoProvisioning` | CProvisioningRepository |

### Attributs publics — Callbacks (mécanisme 2)

> Alternative à `IObserver` : l'application maître assigne directement une `Procédure` sans implémenter d'interface.  
> Utiliser `Exécute(callback, param)` pour appeler. Assigner `NIL` pour désabonner.

| Attribut | Type WLangage | Déclenchement |
|---|---|---|
| `CallbackFactureEmise` | `Procédure(CPennylaneCustomerInvoice)` | Après émission d'une facture client |
| `CallbackFactureRecue` | `Procédure(CPennylaneSupplierInvoice)` | Après réception d'une facture fournisseur |
| `CallbackStatutChange` | `Procédure(Chaîne, Chaîne)` | Changement de statut e-invoicing (id, statut) |
| `CallbackTokenRefraichi` | `Procédure(CPennylaneToken)` | Après refresh automatique du token |
| `CallbackErreur` | `Procédure(Chaîne, Chaîne)` | Erreur API non récupérable (code, message) |

```wlangage
// ===== Utilisation depuis l'application maître =====

// Option A — Procédure nommée
goPennylane.CallbackFactureRecue = MaFonction_SurFactureRecue

PROCÉDURE MaFonction_SurFactureRecue(oFacture est un CPennylaneSupplierInvoice)
    TableauAjouteLigne(TABLE_Factures, oFacture.ID, oFacture.Label, oFacture.Montant)
FIN

// Option B — Procédure interne (closure WinDev 27+)
goPennylane.CallbackFactureRecue = PROCÉDURE INTERNE(f est un CPennylaneSupplierInvoice)
    TableauAjouteLigne(TABLE_Factures, f.ID, f.Label, f.Montant)
FIN PROCÉDURE

// Désabonnement
goPennylane.CallbackFactureRecue = NIL
```

### Méthodes publiques

#### Initialisation

| Méthode | Signature | Description |
|---|---|---|
| `Initialiser` | `Initialiser(cheminConfig : Chaîne) : Booléen` | Charge la config, instancie toutes les dépendances |
| `AjouterObservateur` | `AjouterObservateur(obs : IObserver)` | Enregistre un observateur depuis l'app maître |
| `EstAuthentifie` | `EstAuthentifie() : Booléen` | Vérifie si un token valide est disponible |
| `LancerOAuth` | `LancerOAuth() : Booléen` | Démarre le flow OAuth 2.0 complet |
| `DefinirModeTest` | `DefinirModeTest(tokenDev : Chaîne)` | Active l'auth par token développeur |

#### Profil utilisateur

| Méthode | Signature | Description |
|---|---|---|
| `ObtenirProfil` | `ObtenirProfil() : CPennylaneUserProfile` | `GET /me` |

#### Factures clients (émission)

| Méthode | Signature | Description |
|---|---|---|
| `EmettreFacture` | `EmettreFacture(cheminPDF : Chaîne) : CPennylaneCustomerInvoice` | Import Factur-X depuis le chemin PDF fourni par l'app maître |
| `FinaliserFacture` | `FinaliserFacture(id : Chaîne) : Booléen` | Finalise une facture brouillon |
| `ListerFacturesClient` | `ListerFacturesClient(params : Chaîne) : Tableau` | Liste toutes les factures clients |

#### Factures fournisseurs (réception)

| Méthode | Signature | Description |
|---|---|---|
| `ListerFacturesFournisseur` | `ListerFacturesFournisseur(params : Chaîne) : Tableau` | Liste toutes les factures fournisseurs |
| `RecupererFactureFournisseur` | `RecupererFactureFournisseur(id : Chaîne) : CPennylaneSupplierInvoice` | Détail d'une facture |
| `RecupererPDFFournisseur` | `RecupererPDFFournisseur(id : Chaîne) : Buffer` | Retourne le PDF en tant que Buffer à l'app maître |
| `ContesterFacture` | `ContesterFacture(id : Chaîne, motif : Chaîne) : Booléen` | Met statut `disputed` |
| `RefuserFacture` | `RefuserFacture(id : Chaîne, motif : Chaîne) : Booléen` | Met statut `refused` |
| `AnnulerContestation` | `AnnulerContestation(id : Chaîne) : Booléen` | Met statut `approved` |

#### PA Registrations

| Méthode | Signature | Description |
|---|---|---|
| `ListerInscriptionsPA` | `ListerInscriptionsPA() : Tableau de CPennylanePARegistration` | Toutes les inscriptions PA |
| `EstInscritPA` | `EstInscritPA(siren : Chaîne) : Booléen` | Vérifie si un SIREN est `activated` |
| `ObtenirDirectionEchange` | `ObtenirDirectionEchange(siren : Chaîne) : Chaîne` | `emission` / `reception` / `emission_and_reception` |

#### Provisioning

| Méthode | Signature | Description |
|---|---|---|
| `CreerUtilisateur` | `CreerUtilisateur(email, prenom, nom : Chaîne) : Chaîne` | Retourne le `user_id` Pennylane |
| `CreerEntreprise` | `CreerEntreprise(nom, siren : Chaîne, plan : Chaîne) : Chaîne` | Retourne le `company_id` Pennylane |

---

## Résumé des endpoints couverts par domaine

| Domaine | Endpoints couverts | Classe Repository |
|---|---|---|
| Factures clients | POST, GET, PUT (finalize, paid, email), e_invoices/imports | `CCustomerInvoiceRepository` |
| Factures fournisseurs | GET, PUT (e_invoice_status, payment_status, validate), e_invoices/imports | `CSupplierInvoiceRepository` |
| PA Registrations | GET (Company + Provisioning) | `CPARegistrationRepository` |
| Clients | GET, GET/{id}, GET contacts, GET changelogs | `CCustomerRepository` |
| Fournisseurs | GET, GET/{id}, GET changelogs | `CSupplierRepository` |
| Provisioning | POST users, POST companies, GET companies | `CProvisioningRepository` |
| Profil | GET /me | via `CPennylaneFacade` directement |
