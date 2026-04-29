// ============================================================
// POC OAuth2 Pennylane
// Flow : Authorization Code → échange → accès API
//
// PRÉREQUIS :
//   1. Créer une application OAuth sur Pennylane :
//      https://app.pennylane.com → Paramètres → Développeur → Applications OAuth
//   2. Renseigner dans config_poc_oauth2.json :
//      - ClientID     : l'ID de votre application OAuth (ex: "abc123")
//      - ClientSecret : le secret de votre application OAuth
//      - RedirectURI  : "http://localhost:9753/callback"
//
// UTILISATION :
//   Étape 1 : Appeler POC_OAuth2_OuvrirNavigateur()
//             → Le navigateur s'ouvre sur la page Pennylane
//             → L'utilisateur se connecte et autorise
//             → Pennylane redirige vers http://localhost:9753/callback?code=XXX&state=YYY
//   Étape 2 : Copier le "code" et le "state" depuis l'URL de redirection
//   Étape 3 : Appeler POC_OAuth2_EchangerCode("XXX", "YYY")
//   Étape 4 : Appeler POC_OAuth2_TesterAcces()
// ============================================================

CONSTANTE
	POC_OAUTH2_CONFIG = "C:\Mes Projets\pennylane\poc\config_poc_oauth2.json"
FIN

// Variable globale pour conserver la facade entre les étapes
gFacadeOAuth2 est un CPennylaneFacade DYNAMIQUE

// ============================================================
// ÉTAPE 1 — Ouvrir le navigateur pour autorisation
// ============================================================
PROCÉDURE POC_OAuth2_OuvrirNavigateur()
	Trace("=== POC OAuth2 — Étape 1 : Ouverture navigateur ===")

	gFacadeOAuth2 <- new CPennylaneFacade()

	SI PAS gFacadeOAuth2.Initialiser(POC_OAUTH2_CONFIG) ALORS
		Trace("ERREUR : Impossible de charger " + POC_OAUTH2_CONFIG)
		Erreur("Config introuvable." + RC + "Vérifiez POC_OAUTH2_CONFIG et le fichier config_poc_oauth2.json.")
		RETOUR
	FIN

	gFacadeOAuth2.CallbackErreur = PROCÉDURE INTERNE(sCode est une Chaîne, sMsg est une Chaîne)
		Trace("ERREUR [" + sCode + "] " + sMsg)
	FIN PROCÉDURE INTERNE

	// Ouvre le navigateur sur la page d'autorisation Pennylane
	gFacadeOAuth2.Authentifier()

	Trace("Navigateur ouvert.")
	Trace("→ Connectez-vous sur Pennylane et autorisez l'application.")
	Trace("→ Après redirection, copiez le 'code' et le 'state' depuis l'URL.")
	Trace("→ URL de redirection attendue : http://localhost:9753/callback?code=XXX&state=YYY")
	Info("Navigateur ouvert sur Pennylane." + RC + RC +
		"1. Connectez-vous et autorisez l'application." + RC +
		"2. Copiez le 'code' et le 'state' depuis l'URL de redirection." + RC +
		"3. Appelez POC_OAuth2_EchangerCode(code, state).")
FIN

// ============================================================
// ÉTAPE 2 — Échanger le code contre les tokens
// ============================================================
PROCÉDURE POC_OAuth2_EchangerCode(sCode est une Chaîne, sState est une Chaîne)
	Trace("=== POC OAuth2 — Étape 2 : Échange du code ===")
	Trace("Code  : " + sCode)
	Trace("State : " + sState)

	SI gFacadeOAuth2 = Null ALORS
		Trace("ERREUR : Appelez d'abord POC_OAuth2_OuvrirNavigateur()")
		RETOUR
	FIN

	SI PAS gFacadeOAuth2.TraiterCallbackOAuth(sCode, sState) ALORS
		Trace("ÉCHEC : Échange du code refusé.")
		RETOUR
	FIN

	Trace("OK : Tokens obtenus et stockés.")
	Trace("→ Appelez maintenant POC_OAuth2_TesterAcces()")
	Info("Tokens obtenus avec succès !" + RC + "Appelez POC_OAuth2_TesterAcces().")
FIN

// ============================================================
// ÉTAPE 3 — Tester l'accès avec le token OAuth
// ============================================================
PROCÉDURE POC_OAuth2_TesterAcces()
	Trace("=== POC OAuth2 — Étape 3 : Test d'accès ===")

	SI gFacadeOAuth2 = Null ALORS
		Trace("ERREUR : Appelez d'abord POC_OAuth2_OuvrirNavigateur() puis POC_OAuth2_EchangerCode()")
		RETOUR
	FIN

	// Test GET /me
	Trace("--- GET /me ---")
	oProfil est un Variant = gFacadeOAuth2.ObtenirProfil()
	SI oProfil = Null ALORS
		Trace("ÉCHEC : ObtenirProfil a retourné Null")
		RETOUR
	FIN
	Trace("OK : " + oProfil.user.first_name + " " + oProfil.user.last_name)
	Trace("OK : company = " + oProfil.company.name)

	// Test GET /customers
	Trace("--- GET /customers ---")
	oClients est un Variant = gFacadeOAuth2.ListerClients()
	SI oClients = Null ALORS
		Trace("ÉCHEC : ListerClients a retourné Null")
		RETOUR
	FIN
	Trace("OK : clients récupérés")

	Trace("=== POC OAuth2 terminé avec succès ===")
	Info("POC OAuth2 réussi !" + RC + "Voir la fenêtre de trace (Ctrl+F8).")
FIN
