// ============================================================
// Classe : CPennylaneToken
// Rôle   : Value Object immuable représentant un token OAuth.
// ============================================================
CLASSE CPennylaneToken

// Attributs publics
Valeur          est une Chaîne
DateExpiration  est une DateHeure
Scopes          est une Chaîne
Type            est une Chaîne = "Bearer"

// ============================================================
// MÉTHODES PUBLIQUES
// ============================================================

// Vrai si le token n'est pas expiré (marge de 60 secondes)
PROCÉDURE EstValide() : Booléen
	dMarge est une Durée = 60s
	RETOUR DateHeureSystème() < DateExpiration - dMarge
FIN

// Retourne le header Authorization : "Bearer <valeur>"
PROCÉDURE Header() : Chaîne
	RETOUR "Bearer " + Valeur
FIN

FIN CLASSE
