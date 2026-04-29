// ============================================================
// Classe : CPennylaneDevTokenAuth
// Rôle   : Authentification par token développeur (tests uniquement).
// Implémente : IAuthStrategy
// ============================================================
CLASSE CPennylaneDevTokenAuth IMPLÉMENTE IAuthStrategy

// Attributs
oConfig  est un CPennylaneConfig DYNAMIQUE
TokenDev est une Chaîne

// ============================================================
// CONSTRUCTEUR
// ============================================================
PROCÉDURE Constructeur(config est un CPennylaneConfig)
	oConfig <- config
FIN

// ============================================================
// IMPLÉMENTATION IAuthStrategy
// ============================================================

PROCÉDURE ObtenirHeader() : Chaîne
	RETOUR "Bearer " + TokenDev
FIN

PROCÉDURE EstValide() : Booléen
	RETOUR TokenDev <> ""
FIN

// Le token développeur ne se rafraîchit pas
PROCÉDURE Rafraichir() : Booléen
	RETOUR Faux
FIN

// Charge le token dev depuis la configuration
PROCÉDURE Authentifier() : Booléen
	TokenDev = oConfig.ClientSecret   // Convention : stocker le dev token dans ClientSecret
	RETOUR TokenDev <> ""
FIN

FIN CLASSE
