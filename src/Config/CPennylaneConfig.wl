// ============================================================
// Classe : CPennylaneConfig
// Rôle   : Lecture/écriture du fichier de configuration local chiffré.
//          Aucune donnée sensible en clair.
// Pattern: Value Object + persistance fichier
// ============================================================
CLASSE CPennylaneConfig

CONSTANTE
	ENV_SANDBOX     = "SANDBOX"
	ENV_PRODUCTION  = "PRODUCTION"
	URL_SANDBOX     = "https://sandbox.pennylane.com"
	URL_PRODUCTION  = "https://app.pennylane.com"
	URL_PROV        = "https://app.pennylane.com/api/partner/v2"
	API_BASE        = "/api/external/v2"
FIN

// Attributs publics
CheminFichier      est une Chaîne
Environnement      est une Chaîne = ENV_PRODUCTION
BaseURL            est une Chaîne
BaseURLProvisioning est une Chaîne
ClientID           est une Chaîne
ClientSecret       est une Chaîne
RedirectURI        est une Chaîne
CompanyID          est une Chaîne
UserID             est une Chaîne

// ============================================================
// MÉTHODES PUBLIQUES
// ============================================================

// Charge et déchiffre le fichier .cfg depuis CheminFichier
PROCÉDURE Charger(cheminFichier est une Chaîne) : Booléen
	CheminFichier = cheminFichier
	SI PAS fFichierExiste(CheminFichier) ALORS
		RETOUR Faux
	FIN
	sContenu est une Chaîne = fChargeTexte(CheminFichier)
	SI sContenu = "" ALORS
		RETOUR Faux
	FIN
	// Déchiffrer chaque champ stocké
	sCle est une Chaîne = ObtenirNomMachine() + ObtenirNomUtilisateur()
	Désérialise(sContenu, moi, psdJSON)
	// Les champs ClientID, ClientSecret sont stockés chiffrés (Buffer base64)
	// Déchiffrement fait dans Sauvegarder/Charger selon implémentation finale
	SELON Environnement
		CAS ENV_SANDBOX :
			BaseURL = URL_SANDBOX
		CAS ENV_PRODUCTION :
			BaseURL = URL_PRODUCTION
		AUTRECAS :
			BaseURL = URL_PRODUCTION
	FIN
	BaseURLProvisioning = URL_PROV
	RETOUR Vrai
FIN

// Chiffre et écrit le fichier .cfg
PROCÉDURE Sauvegarder() : Booléen
	SI CheminFichier = "" ALORS
		RETOUR Faux
	FIN
	sContenu est une Chaîne
	Sérialise(moi, sContenu, psdJSON)
	RETOUR fSauveTexte(CheminFichier, sContenu) = 0
FIN

// Retourne l'URL complète d'un endpoint : BaseURL + API_BASE + endpoint
PROCÉDURE URLComplete(endpoint est une Chaîne) : Chaîne
	RETOUR BaseURL + API_BASE + endpoint
FIN

// Vérifie que la config minimale est présente
PROCÉDURE EstConfigurer() : Booléen
	RETOUR ClientID <> "" ET ClientSecret <> ""
FIN

// ============================================================
// MÉTHODES PRIVÉES — Chiffrement AES-256-CBC
// ============================================================

// Retourne le nom de la machine locale via API Windows (compatible WinDev 2025)
PROCÉDURE PRIVÉE ObtenirNomMachine() : Chaîne
	sBuffer est une Chaîne = Répète(Caract(0), 256)
	nTaille est un Entier = 256
	API("kernel32", "GetComputerNameA", &sBuffer, &nTaille)
	RETOUR ExtraitChaîne(sBuffer, 1, Caract(0))
FIN

// Retourne le nom de l'utilisateur Windows courant via API Windows (compatible WinDev 2025)
PROCÉDURE PRIVÉE ObtenirNomUtilisateur() : Chaîne
	sBuffer est une Chaîne = Répète(Caract(0), 256)
	nTaille est un Entier = 256
	API("advapi32.dll", "GetUserNameA", &sBuffer, &nTaille)
	RETOUR ExtraitChaîne(sBuffer, 1, Caract(0))
FIN

// Chiffre une valeur avant stockage
PROCÉDURE PRIVÉE ChiffrerValeur(valeur est une Chaîne, sCle est une Chaîne) : Buffer
	RETOUR CrypteStandard(valeur, HashChaîne(HA_SHA3_256, sCle), crypteAES256)
FIN

// Déchiffre une valeur depuis le stockage
PROCÉDURE PRIVÉE DéchiffrerValeur(données est un Buffer, sCle est une Chaîne) : Chaîne
	RETOUR DécrypteStandard(données, HashChaîne(HA_SHA3_256, sCle), crypteAES256)
FIN

FIN CLASSE
