// ============================================================
// Classe : CPennylaneTokenStore
// Rôle   : Persiste et recharge les tokens depuis CPennylaneConfig.
// ============================================================
CLASSE CPennylaneTokenStore

// Attributs publics
TokenAcces             est un CPennylaneToken
TokenRafraichissement  est un CPennylaneToken

// Attribut privé — référence configuration
oConfig est un CPennylaneConfig DYNAMIQUE

// ============================================================
// CONSTRUCTEUR
// ============================================================
PROCÉDURE Constructeur(config est un CPennylaneConfig)
	oConfig <- config
FIN

// ============================================================
// MÉTHODES PUBLIQUES
// ============================================================

// Construit et persiste les deux tokens après échange de code ou refresh
PROCÉDURE Stocker(sAcces est une Chaîne, sRefresh est une Chaîne, nExpiresIn est un Entier)
	TokenAcces.Valeur         = sAcces
	TokenAcces.Type           = "Bearer"
	// nExpiresIn est en secondes (fourni par l'API)
	// WLangage : une Durée exprimée en secondes → nExpiresIn * 1s
	dAcces est une Durée = nExpiresIn * 1s
	TokenAcces.DateExpiration = DateHeureSystème() + dAcces

	TokenRafraichissement.Valeur         = sRefresh
	TokenRafraichissement.Type           = "Bearer"
	// Refresh token valide 90 jours = 90 * 24 * 3600 secondes
	dRefresh est une Durée = 90 * 24 * 3600 * 1s
	TokenRafraichissement.DateExpiration = DateHeureSystème() + dRefresh

	// Persister dans la config (sérialisé/chiffré)
	oConfig.Sauvegarder()
FIN

// Recharge les tokens depuis la config
PROCÉDURE Charger() : Booléen
	RETOUR oConfig.Charger(oConfig.CheminFichier)
FIN

// Vrai si le token d'accès est encore valide
PROCÉDURE TokenAccesValide() : Booléen
	RETOUR TokenAcces.EstValide()
FIN

// Supprime les tokens (déconnexion)
PROCÉDURE Effacer()
	TokenAcces.Valeur         = ""
	TokenAcces.DateExpiration = "00000000000000"
	TokenRafraichissement.Valeur         = ""
	TokenRafraichissement.DateExpiration = "00000000000000"
	oConfig.Sauvegarder()
FIN

FIN CLASSE
