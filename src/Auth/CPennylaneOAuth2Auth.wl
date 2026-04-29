// ============================================================
// Classe : CPennylaneOAuth2Auth
// Rôle   : Flow Authorization Code complet + refresh automatique.
// Implémente : IAuthStrategy
// Scopes requis : customer_invoices:all  supplier_invoices:all
// ============================================================
CLASSE CPennylaneOAuth2Auth IMPLÉMENTE IAuthStrategy

// Constantes
CONSTANTE
	cTokenURL = "https://app.pennylane.com/oauth/token"
FIN

// Attributs privés

oConfig      est un CPennylaneConfig     DYNAMIQUE
oTokenStore  est un CPennylaneTokenStore  DYNAMIQUE
oEventBus    est un CPennylaneEventBus    DYNAMIQUE
StateOAuth   est une Chaîne
PortLocal    est un Entier = 9753

// ============================================================
// CONSTRUCTEUR
// ============================================================
PROCÉDURE Constructeur(
	config     est un CPennylaneConfig,
	tokenStore est un CPennylaneTokenStore,
	eventBus   est un CPennylaneEventBus
)
	oConfig     <- config
	oTokenStore <- tokenStore
	oEventBus   <- eventBus
FIN

// ============================================================
// IMPLÉMENTATION IAuthStrategy
// ============================================================

PROCÉDURE ObtenirHeader() : Chaîne
	// Rafraîchir si expiré
	SI PAS oTokenStore.TokenAccesValide() ALORS
		SI PAS Rafraichir() ALORS
			oEventBus.PublierErreur("OAuth2", "Échec du rafraîchissement du token : header non disponible")
			RETOUR ""
		FIN
	FIN
	RETOUR oTokenStore.TokenAcces.Header()
FIN

PROCÉDURE EstValide() : Booléen
	RETOUR oTokenStore.TokenAccesValide()
FIN

// Renouvelle le token via grant_type=refresh_token
PROCÉDURE Rafraichir() : Booléen
	req est un httpRequête
	req.URL			= cTokenURL
	req.Méthode		= httpPost
	req.ContentType	= "application/x-www-form-urlencoded"
	req.Contenu		= ChaîneConstruit(
		"grant_type=refresh_token&refresh_token=%1&client_id=%2&client_secret=%3",
		URLEncode(oTokenStore.TokenRafraichissement.Valeur),
		URLEncode(oConfig.ClientID),
		URLEncode(oConfig.ClientSecret)
	)
	rep est un httpRéponse = HTTPEnvoie(req)
	SI rep.CodeEtat <> 200 ALORS
		oEventBus.PublierErreur("OAuth2", ChaîneConstruit("Échec du rafraîchissement HTTP %1", rep.CodeEtat))
		RETOUR Faux
	FIN
	// Parser la réponse JSON
	jReponse est un Variant
	Désérialise(rep.Contenu, jReponse, psdJSON)
	oTokenStore.Stocker(
		jReponse.access_token,
		jReponse.refresh_token,
		jReponse.expires_in
	)
	oEventBus.PublierTokenRefraichi(oTokenStore.TokenAcces)
	RETOUR Vrai
FIN

// Lance le flow OAuth complet : ouvre navigateur + attend callback local
PROCÉDURE Authentifier() : Booléen
	RETOUR LancerFlow()
FIN

// ============================================================
// MÉTHODES PUBLIQUES
// ============================================================

// Ouvre le navigateur et attend le callback OAuth
PROCÉDURE LancerFlow() : Booléen
	// Générer un state aléatoire anti-CSRF
	StateOAuth = ChaîneConstruit("%1%2", DateHeureSystème(), Hasard(100000, 999999))
	sURL est une Chaîne = ConstruireURLAuth()
	OuvreURL(sURL)
	// Le callback est capturé via un serveur HTTP local sur PortLocal
	// → L'implémentation du serveur HTTP local dépend de l'app maître
	// → Appeler EchangerCode(code) quand le code est reçu
	RETOUR Vrai
FIN

// Échange le code d'autorisation contre les tokens
// sState : valeur reçue dans le callback, vérifiée anti-CSRF
PROCÉDURE EchangerCode(sCode est une Chaîne, sState est une Chaîne) : Booléen
	// Vérification anti-CSRF : le state reçu doit correspondre au state émis
	SI sState <> StateOAuth ALORS
		oEventBus.PublierErreur("OAuth2", "Vérification anti-CSRF échouée : state invalide")
		RETOUR Faux
	FIN
	req est un httpRequête
	req.URL			= cTokenURL
	req.Méthode		= httpPost
	req.ContentType	= "application/x-www-form-urlencoded"
	req.Contenu		= ChaîneConstruit(
		"grant_type=authorization_code&code=%1&redirect_uri=%2&client_id=%3&client_secret=%4",
		URLEncode(sCode),
		URLEncode(oConfig.RedirectURI),
		URLEncode(oConfig.ClientID),
		URLEncode(oConfig.ClientSecret)
	)
	rep est un httpRéponse = HTTPEnvoie(req)
	SI rep.CodeEtat <> 200 ALORS
		oEventBus.PublierErreur("OAuth2", ChaîneConstruit("Échec de l'échange de code HTTP %1", rep.CodeEtat))
		RETOUR Faux
	FIN
	jReponse est un Variant
	Désérialise(rep.Contenu, jReponse, psdJSON)
	oTokenStore.Stocker(
		jReponse.access_token,
		jReponse.refresh_token,
		jReponse.expires_in
	)
	oEventBus.PublierTokenRefraichi(oTokenStore.TokenAcces)
	RETOUR Vrai
FIN

// Construit l'URL d'autorisation avec client_id, scopes et state
PROCÉDURE ConstruireURLAuth() : Chaîne
	RETOUR ChaîneConstruit(
		"https://app.pennylane.com/oauth/authorize?response_type=code&client_id=%1&redirect_uri=%2&scope=%3&state=%4",
		oConfig.ClientID,
		oConfig.RedirectURI,
		"customer_invoices:all supplier_invoices:all",
		StateOAuth
	)
FIN

FIN CLASSE
