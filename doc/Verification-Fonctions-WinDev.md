# Vérification des fonctions WLangage — Connecteur Pennylane

**Date :** 23 avril 2026  
**Objet :** Audit de toutes les fonctions WLangage utilisées dans la documentation d'architecture  
**Référence WinDev :** v29+ (WLangage 29)

---

## Résumé des erreurs trouvées

| # | Erreur | Sévérité | Fichier concerné |
|---|---|---|---|
| 1 | `ChiffreAES()` / `DéchiffreAES()` n'existent pas | ❌ Critique | Classes-Reference, Architecture |
| 2 | `AjouterAuTableau()` n'existe pas | ❌ Critique | Classes-Reference |
| 3 | `Attendre(delai)` : unité milliseconds incorrecte | ⚠️ Erreur de comportement | Classes-Reference, Architecture |
| 4 | `AfficheImageDepuisBuffer()` n'existe pas | ❌ Critique | Architecture |
| 5 | `Entier long` n'est pas un type WLangage valide | ⚠️ Compilation impossible | Classes-Reference |

---

## Tableau complet de vérification

### Fonctions standard

| Fonction / Type | Statut | Commentaire | Correction |
|---|---|---|---|
| `Attendre(delai)` | ⚠️ Unité incorrecte | Paramètre en **centièmes de seconde** (CS), pas en millisecondes. `Attendre(100)` = 1 seconde. | Renommer `DelaiInitialMS` → `DelaiInitialCS`, valeur `1000ms` → `100 cs` |
| `DateHeureSystème()` | ✅ Correct | Retourne la date/heure locale du système. Type retourné : `DateHeure`. | — |
| `OuvreURL(url)` | ✅ Correct | Ouvre une URL dans le navigateur par défaut. Disponible WINDEV Windows. | — |
| `Info(message)` | ✅ Correct | Boîte de dialogue d'information standard. | — |
| `Trace(valeur)` | ✅ Correct | Écriture dans la fenêtre de débogage. | — |
| `ChaîneConstruit(modèle, ...)` | ✅ Correct | Formatage de chaîne avec paramètres `%1`, `%2`... | — |
| `Ajoute(tableau, element)` | ✅ Correct | Ajoute un élément à un tableau dynamique. | — |
| `AjouterAuTableau()` | ❌ N'existe pas | Cette fonction n'existe pas en WLangage. | Remplacer par `Ajoute()` dans une boucle `POUR TOUT` |
| `Dimension(tableau)` | ✅ Correct | Retourne la taille d'un tableau. | — |
| `fChargeBuffer(chemin)` | ✅ Correct | Charge un fichier en mémoire sous forme de `Buffer`. | — |
| `fSauveBuffer(chemin, buffer)` | ✅ Correct | Sauvegarde un `Buffer` dans un fichier. | — |
| `ExtraitChemin(chemin, option)` | ✅ Correct | Extrait la partie nom/extension d'un chemin. Constantes : `fFichier`, `fExtension`, `fRépertoire`. | — |
| `Sérialise(objet, sérieJSON)` | ✅ Correct | Sérialise un objet/structure en JSON. | — |
| `Désérialise(json, objet, sérieJSON)` | ✅ Correct | Désérialise du JSON vers une structure/classe. | — |
| `SHA2(données)` | ✅ Correct | Hash SHA-256. Retourne un `Buffer` de 32 octets (256 bits). Utile pour dériver une clé AES. | — |

### Chiffrement

| Fonction / Type | Statut | Commentaire | Correction |
|---|---|---|---|
| `ChiffreAES(données, clé)` | ❌ N'existe pas | Cette fonction n'existe pas en WLangage. | Voir ci-dessous |
| `DéchiffreAES(données, clé)` | ❌ N'existe pas | Cette fonction n'existe pas en WLangage. | Voir ci-dessous |
| `CryptageSymétrique` (type) | ✅ Correct (v26+) | Variable type pour le chiffrement symétrique AES, 3DES, etc. | **C'est la bonne approche** |
| `Crypte(monCryptage, données)` | ✅ Correct | Chiffre avec la variable `CryptageSymétrique` configurée. | **Remplace `ChiffreAES`** |
| `Décrypte(monCryptage, données)` | ✅ Correct | Déchiffre avec la variable `CryptageSymétrique`. | **Remplace `DéchiffreAES`** |
| `ChiffreMot(données, clé)` | ✅ Correct | Chiffrement Blowfish simple. Plus ancien, non-AES. Acceptable pour protection légère. | Alternative simplifiée |
| `DéchiffreMot(données, clé)` | ✅ Correct | Déchiffrement Blowfish. | Alternative simplifiée |

#### Implémentation correcte du chiffrement AES-256

```wlangage
// Chiffrement AES-256-CBC via CryptageSymétrique
PROCÉDURE PRIVÉE ChiffrerAES(données est une Chaîne, cle est une Chaîne) : Buffer
    monCryptage est un CryptageSymétrique
    monCryptage.Algorithme = cryptAES256CBC
    monCryptage.CléSecrète  = SHA2(cle)       // Clé 256 bits dérivée
    RETOURNER Crypte(monCryptage, données)
FIN

PROCÉDURE PRIVÉE DéchiffrerAES(données est un Buffer, cle est une Chaîne) : Chaîne
    monCryptage est un CryptageSymétrique
    monCryptage.Algorithme = cryptAES256CBC
    monCryptage.CléSecrète  = SHA2(cle)
    RETOURNER Décrypte(monCryptage, données)
FIN
```

> **Note sécurité :** La clé `cle` doit être dérivée du SID Windows de l'utilisateur + nom de machine, jamais stockée en clair.

### Types WLangage

| Type utilisé | Statut | Correction |
|---|---|---|
| `Chaîne` | ✅ | — |
| `Booléen` | ✅ | — |
| `Entier` | ✅ | 32 bits signé |
| `Entier long` | ❌ N'existe pas | Remplacer par `Entier sur 8 octets` (64 bits) |
| `Entier sur 8 octets` | ✅ | 64 bits signé — pour les IDs potentiellement grands |
| `Réel` | ✅ | Flottant double précision (64 bits) |
| `DateHeure` | ✅ | Date + heure combinées |
| `Date` | ✅ | Date seule |
| `Buffer` | ✅ | Tableau d'octets binaire |
| `Durée` | ✅ | Représentation d'une durée, utilisable dans `Attendre()` |

### HTTP (API REST)

| Fonction / Type | Statut | Commentaire |
|---|---|---|
| `httpRequête` (type) | ✅ Correct (v24+) | Variable type pour préparer une requête HTTP |
| `httpRéponse` (type) | ✅ Correct (v24+) | Résultat retourné par `HTTPEnvoie()` |
| `httpPartie` (type) | ✅ Correct | Pour les requêtes multipart/form-data |
| `HTTPEnvoie(maRequête)` | ✅ Correct | Envoie la requête, retourne une `httpRéponse` |
| `.CodeHTTP` (propriété) | ✅ | Code de statut HTTP (200, 401, 429...) sur `httpRéponse` |
| `.Corps` (propriété) | ✅ | Corps de la réponse en chaîne (JSON) |
| `.CorpsBuffer` (propriété) | ✅ | Corps binaire (PDF) |
| `.AjouteEntête(nom, valeur)` | ✅ | Ajoute un entête HTTP à la requête |
| `HTTPDonneRésultat()` | ✅ | Ancienne API (avant httpRequête) — encore valide mais non recommandée |

#### Structure httpRequête correcte

```wlangage
// Exemple : GET avec authentification
maRequête est une httpRequête
maRequête.Méthode     = httpGet
maRequête.URL         = oConfig.URLComplete("/customer_invoices")
maRequête.AjouteEntête("Authorization", oAuth.ObtenirHeader())
maRequête.AjouteEntête("Accept", "application/json")

maRéponse est une httpRéponse = HTTPEnvoie(maRequête)
SI maRéponse.CodeHTTP = 200 ALORS
    // Traiter maRéponse.Corps (JSON)
FIN

// Exemple : POST multipart/form-data (envoi PDF)
maRequête est une httpRequête
maRequête.Méthode = httpPost
maRequête.URL     = oConfig.URLComplete("/customer_invoices/e_invoices/imports")
maRequête.AjouteEntête("Authorization", oAuth.ObtenirHeader())

maPart est une httpPartie
maPart.Nom         = "file"
maPart.NomFichier  = ExtraitChemin(cheminPDF, fFichier + fExtension)
maPart.Corps       = fChargeBuffer(cheminPDF)
maPart.TypeContenu = "application/pdf"
Ajoute(maRequête.Partie, maPart)

maRéponse = HTTPEnvoie(maRequête)
```

### Syntaxe WLangage

| Élément | Statut | Commentaire |
|---|---|---|
| `TANTQUE...FIN` | ✅ | Boucle while |
| `POUR TOUT elem DE tableau...FIN` | ✅ | For-each sur tableau |
| `SELON...CAS...AUTRECAS...FIN` | ✅ | Switch/case |
| `SI...ALORS...SINON...FIN` | ✅ | If/else |
| `PROCÉDURE INTERNE...FIN PROCÉDURE` | ✅ (v27+) | Procédure locale / fermeture (closure) |
| `PROCÉDURE PRIVÉE...FIN` | ✅ | Méthode privée dans une classe |
| `RETOURNER` | ✅ | Return |
| `CONSTANTE...FIN` | ✅ | Bloc de constantes |
| `INTERFACE...FIN` | ✅ | Déclaration d'interface |
| `NIL` | ✅ | Référence nulle pour les classes |
| `QUITTER` | ✅ | Break (sortie de boucle) |

### Fonction `Attendre` — correction

```wlangage
// ❌ INCORRECT (délai en millisecondes interprété comme centièmes de seconde)
DelaiInitialMS est un Entier = 1000
Attendre(DelaiInitialMS)  // Attend 10 secondes au lieu d'1 seconde !

// ✅ CORRECT (délai en centièmes de secondes)
DelaiInitialCS est un Entier = 100  // 100 centièmes = 1 seconde
Attendre(DelaiInitialCS)            // Attend bien 1 seconde

// ✅ ALTERNATIF — utiliser le type Durée (plus lisible, v23+)
Attendre(1 s)    // Attend 1 seconde
Attendre(500 ms) // Attend 500 millisecondes
```

> **Note :** La syntaxe `Attendre(1 s)` utilise le type `Durée` de WLangage et est disponible depuis WinDev 23. Elle est préférable car explicite sur l'unité.

---

## Correction du code de retry dans CPennylaneHttpClient

```wlangage
// ✅ Version corrigée avec Durée
PROCÉDURE PRIVÉE ExecuterAvecRetry(fnAppel est une Procédure) : CPennylaneHttpResponse
    delaiCS   <- DelaiInitialCS    // 100 centièmes = 1 seconde
    tentative <- 1
    TANTQUE tentative <= MaxTentatives
        rep <- Exécute(fnAppel)
        SELON rep.CodeHTTP
            CAS 429, 500, 502, 503 :
                Attendre(delaiCS)           // Paramètre en centièmes de seconde
                delaiCS   <- delaiCS * 2    // Backoff : 100, 200, 400, 800, 1600 cs
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

## Correction de la pagination dans CPARegistrationRepository

```wlangage
// ❌ INCORRECT — AjouterAuTableau n'existe pas
AjouterAuTableau(resultats, page.Elements)

// ✅ CORRECT — ajouter élément par élément avec Ajoute()
POUR TOUT elem DE page.Elements
    Ajoute(resultats, elem)
FIN

// Version complète corrigée :
PROCÉDURE ListerTout(params est une Chaîne) : Tableau de CPennylanePARegistration
    resultats est un tableau de CPennylanePARegistration
    curseur   est une Chaîne = ""
    TANTQUE Vrai
        rep <- oHttp.Get("/pa_registrations", params + "&cursor=" + curseur)
        page est un CPennylanePaginatedResult = DeserialiserPage(rep.Corps)
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

## Mécanismes de retour d'information à l'application maître

### Mécanisme 1 — Interface IObserver (Pattern Observer — recommandé)

> Déjà documenté. Permet plusieurs observateurs simultanés. Optimal pour un composant réutilisé par plusieurs fenêtres/modules.

```wlangage
// L'app maître implémente IObserver :
CLASSE CMaFenetreObservateur IMPLÉMENTE IObserver
    PROCÉDURE SurFactureRecue(oFacture est un CPennylaneSupplierInvoice)
        // Rafraîchir la liste à l'écran
        TableauAjouteLigne(TABLE_Factures, oFacture.ID, oFacture.Label, oFacture.Statut)
    FIN
    PROCÉDURE SurErreur(code est une Chaîne, message est une Chaîne)
        Erreur(code + " : " + message)
    FIN
    // ... autres méthodes ...
FIN

// Abonnement :
monObs est un CMaFenetreObservateur
goPennylane.AjouterObservateur(monObs)
```

### Mécanisme 2 — Variable Procédure (Callback direct — plus simple)

> Depuis WinDev 19+. Adapté lorsqu'un seul module est abonné à un événement précis.

```wlangage
// ===== Déclaration dans CPennylaneFacade =====
ATTRIBUT
    // Callbacks optionnels — l'app maître les assigne si elle le souhaite
    CallbackFactureEmise  est une Procédure(CPennylaneCustomerInvoice)
    CallbackFactureRecue  est une Procédure(CPennylaneSupplierInvoice)
    CallbackStatutChange  est une Procédure(Chaîne, Chaîne)
    CallbackTokenRefraichi est une Procédure(CPennylaneToken)
    CallbackErreur        est une Procédure(Chaîne, Chaîne)
FIN ATTRIBUT

// Appel interne (après traitement API) :
PROCÉDURE PRIVÉE NotifierFactureEmise(oFacture est un CPennylaneCustomerInvoice)
    // Observer pattern
    oEventBus.PublierFactureEmise(oFacture)
    // Callback direct
    SI CallbackFactureEmise <> NIL ALORS
        Exécute(CallbackFactureEmise, oFacture)
    FIN
FIN

// ===== Dans l'application maître =====

// Option A : assigner une procédure globale nommée
goPennylane.CallbackFactureRecue = MaProc_SurFactureRecue

PROCÉDURE MaProc_SurFactureRecue(oFacture est un CPennylaneSupplierInvoice)
    // Traiter la facture reçue
    TableauAjouteLigne(TABLE_Factures, oFacture.ID, oFacture.Montant)
FIN

// Option B : procédure interne (closure) — WinDev 27+
goPennylane.CallbackFactureRecue = PROCÉDURE INTERNE(f est un CPennylaneSupplierInvoice)
    // Accède aux variables locales de la fenêtre (fermeture)
    TableauAjouteLigne(TABLE_Factures, f.ID, f.Montant)
FIN PROCÉDURE
```

### Mécanisme 3 — Comparaison et recommandations

| Critère | IObserver | Variable Procédure |
|---|---|---|
| Plusieurs abonnés | ✅ Oui | ❌ Non (un seul) |
| Simple à câbler depuis l'app maître | Moyen (nécessite implémenter l'interface) | ✅ Très simple |
| Support closure / lambda | ❌ Non | ✅ Oui (v27+) |
| Désabonnement propre | ✅ `Desabonner()` | ✅ Assigner `NIL` |
| Compatible composant externe | ✅ | ✅ |
| Recommandé pour | Modules multiples, architecture événementielle | Fenêtre unique, usage rapide |

### Mécanisme 4 — Combinaison (recommandé en production)

Exposer **les deux** sur `CPennylaneFacade` :

```wlangage
// L'EventBus notifie les IObserver enregistrés
// ET les callbacks directs (si assignés)
// → l'app maître choisit le mécanisme qui lui convient
goPennylane.AjouterObservateur(monObservateur)   // Mécanisme 1
goPennylane.CallbackErreur = MaGestionErreurs     // Mécanisme 2 (pour erreurs critiques)
```

---

## Récapitulatif des corrections à appliquer

| Fichier | Emplacement | Correction |
|---|---|---|
| `Classes-WinDev-Pennylane-Reference.md` | `CPennylaneConfig` — Chiffrement | `ChiffreAES()` → `CryptageSymétrique` + `Crypte()` / `Décrypte()` |
| `Classes-WinDev-Pennylane-Reference.md` | `CPennylaneHttpClient` — Attributs | `DelaiInitialMS = 1000` → `DelaiInitialCS = 100` (centièmes de seconde) |
| `Classes-WinDev-Pennylane-Reference.md` | `CPennylaneHttpClient` — Retry | `Attendre(delai)` : préciser unité CS + utiliser `Durée` |
| `Classes-WinDev-Pennylane-Reference.md` | `CPARegistrationRepository` — Pagination | `AjouterAuTableau()` → `POUR TOUT elem DE... Ajoute()` |
| `Classes-WinDev-Pennylane-Reference.md` | `CPennylaneUserProfile` — Attribut ID | `Entier long` → `Entier sur 8 octets` |
| `Classes-WinDev-Pennylane-Reference.md` | `CPennylanePARegistration` — Attribut ID | `Entier long` → `Entier sur 8 octets` |
| `Classes-WinDev-Pennylane-Reference.md` | `CPennylaneFacade` | Ajouter attributs de callback `Procédure` |
| `Architecture-Classes-WinDev-Pennylane.md` | Section 11 — Intégration | `AfficheImageDepuisBuffer()` → code correct |
| `Architecture-Classes-WinDev-Pennylane.md` | Retry section | Corriger unité `Attendre` |
| `Architecture-Classes-WinDev-Pennylane.md` | Ajouter | Section 13 — Callbacks vers app maître |
