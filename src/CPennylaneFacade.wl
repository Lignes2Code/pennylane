// ============================================================
// Classe : CPennylaneFacade
// Rôle   : Point d'entrée UNIQUE du composant WinDev.
//          C'est la seule classe exposée à l'application maître.
// Pattern: Facade + Dependency Injection
// Migré  : Utilise le composant OpenAPI Accounting.wdopapi
//          au lieu des repositories manuels.
//
// UTILISATION DEPUIS L'APPLICATION MAÎTRE :
//   goPennylane est un CPennylaneFacade
//   SI goPennylane.Initialiser("C:\config\pennylane.cfg") ALORS
//       goPennylane.Authentifier()
//   FIN
// ============================================================
CLASSE CPennylaneFacade

// ============================================================
// ATTRIBUTS PRIVÉS — Infrastructure
// ============================================================
oConfig     est un CPennylaneConfig     DYNAMIQUE
oTokenStore est un CPennylaneTokenStore DYNAMIQUE
oAuth       est un IAuthStrategy
oOAuth2     est un CPennylaneOAuth2Auth DYNAMIQUE
oDevAuth    est un CPennylaneDevTokenAuth DYNAMIQUE
bModeOAuth2 est un Booléen = Faux
oEventBus   est un CPennylaneEventBus   DYNAMIQUE

// ============================================================
// ATTRIBUTS PUBLICS — Callbacks optionnels (Mécanisme B)
// Assigner NIL pour désabonner.
// Compatibles PROCÉDURE INTERNE (closure WinDev 27+).
// ============================================================
CallbackFactureEmise   est une Procédure(CustomerInvoices__Response)
CallbackFactureRecue   est une Procédure(SupplierInvoices__Response)
CallbackStatutChange   est une Procédure(sID est une Chaîne, sStatut est une Chaîne)
CallbackTokenRefraichi est une Procédure(CPennylaneToken)
CallbackErreur         est une Procédure(sCode est une Chaîne, sMsg est une Chaîne)

// ============================================================
// INITIALISATION
// ============================================================

// Initialise tout le stack à partir du chemin du fichier de config
PROCÉDURE Initialiser(cheminConfig est une Chaîne) : Booléen
	oConfig <- new CPennylaneConfig()
	SI PAS oConfig.Charger(cheminConfig) ALORS
		RETOUR Faux
	FIN
	oEventBus   <- new CPennylaneEventBus()
	oTokenStore <- new CPennylaneTokenStore(oConfig)
	oTokenStore.Charger()
	oOAuth2     <- new CPennylaneOAuth2Auth(oConfig, oTokenStore, oEventBus)
	oAuth       <- oOAuth2
	bModeOAuth2 = Vrai
	RETOUR Vrai
FIN

// Utilise un token dev fixe (mode test sandbox)
// Si sTokenDev = "" le token est lu depuis oConfig.ClientSecret
PROCÉDURE InitialiserAvecTokenDev(cheminConfig est une Chaîne, sTokenDev est une Chaîne) : Booléen
	SI PAS Initialiser(cheminConfig) ALORS RETOUR Faux
	oDevAuth <- new CPennylaneDevTokenAuth(oConfig)
	SI sTokenDev <> "" ALORS
		oDevAuth.TokenDev = sTokenDev
	SINON
		oDevAuth.Authentifier()   // charge depuis oConfig.ClientSecret
	FIN
	oAuth       <- oDevAuth
	bModeOAuth2 = Faux
	RETOUR oDevAuth.EstValide()
FIN

// Ajoute un observateur (Mécanisme A — IObserver)
// Retourne l'identifiant d'abonnement à passer à RetirerObservateur
PROCÉDURE AjouterObservateur(obs est un IObserver) : Chaîne
	RETOUR oEventBus.Abonner(obs)
FIN

PROCÉDURE RetirerObservateur(sID est une Chaîne)
	oEventBus.Desabonner(sID)
FIN

// ============================================================
// AUTHENTIFICATION
// ============================================================

PROCÉDURE Authentifier() : Booléen
	RETOUR oAuth.Authentifier()
FIN

// Appeler depuis l'app maître quand le navigateur retourne le code + state OAuth
PROCÉDURE TraiterCallbackOAuth(sCode est une Chaîne, sState est une Chaîne) : Booléen
	SI PAS bModeOAuth2 ALORS RETOUR Faux
	RETOUR oOAuth2.EchangerCode(sCode, sState)
FIN

// ============================================================
// MÉTHODES PRIVÉES
// ============================================================

// Crée une apiRequête avec l'en-tête Authorization prêt à l'emploi
PROCÉDURE PRIVÉE CréerRequête() : apiRequête
	oReq est une apiRequête
	oReq.EntêteHTTP["Authorization"] = oAuth.ObtenirHeader()
	RETOUR oReq
FIN

// Envoie une requête POST JSON authentifiée et retourne le corps de la réponse
// Utilisé pour les endpoints sans paramètres de chemin (pas d'apiRequête générée)
PROCÉDURE PRIVÉE EnvoyerPOST(sEndpoint est une Chaîne, sSource est une Chaîne, sCorpsJSON est une Chaîne, sCodeHTTP est une Chaîne) : Chaîne
	req est un httpRequête
	req.URL         = oConfig.URLComplete(sEndpoint)
	req.Méthode     = httpPost
	req.ContentType = "application/json"
	req.Entête["Authorization"] = oAuth.ObtenirHeader()
	req.Contenu     = sCorpsJSON
	rep est un httpRéponse = HTTPEnvoie(req)
	sCodeHTTP = rep.CodeEtat
	SI rep.CodeEtat >= 300 ALORS
		sCode est une Chaîne = rep.CodeEtat
		sMsg  est une Chaîne = rep.Contenu + " [" + sSource + "]"
		SI CallbackErreur <> Null ALORS CallbackErreur(sCode, sMsg)
		oEventBus.PublierErreur(sCode, sMsg)
		RETOUR ""
	FIN
	RETOUR rep.Contenu
FIN

// Centralise la publication d'erreur à partir d'une apiRéponse
PROCÉDURE PRIVÉE GererErreur(sSource est une Chaîne, oRep est une apiRéponse)
	sCode est une Chaîne = oRep.RéponseHTTP.CodeEtat
	sMsg  est une Chaîne = oRep.RéponseHTTP.Contenu + " [" + sSource + "]"
	SI CallbackErreur <> Null ALORS
		CallbackErreur(sCode, sMsg)
	FIN
	oEventBus.PublierErreur(sCode, sMsg)
FIN

// ============================================================
// PROFIL UTILISATEUR
// ============================================================

PROCÉDURE ObtenirProfil() : Variant
	oRep est une apiRéponse = getMe(CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("ObtenirProfil", oRep)
		RETOUR Null
	FIN
	RETOUR oRep.Valeur
FIN

// ============================================================
// FACTURES CLIENTS (ÉMISSION)
// ============================================================

// Importe un Factur-X depuis le chemin du fichier PDF/XML fourni
PROCÉDURE EmettreFacture(cheminFichier est une Chaîne) : CustomerInvoices__Response
	oRep est une apiRéponse = importCustomerInvoices(cheminFichier, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("EmettreFacture", oRep)
		RETOUR Null
	FIN
	oFacture est un CustomerInvoices__Response = oRep.Valeur
	oEventBus.PublierFactureEmise(oFacture)
	SI CallbackFactureEmise <> Null ALORS Exécute(CallbackFactureEmise, oFacture)
	RETOUR oFacture
FIN

PROCÉDURE CreerFactureClient(oFacture est un stFactureClientCreation) : CustomerInvoices__Response
	oRep est une apiRéponse = postCustomerInvoices(oFacture, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 201 ALORS
		GererErreur("CreerFactureClient", oRep)
		RETOUR Null
	FIN
	oResult est un CustomerInvoices__Response = oRep.Valeur
	RETOUR oResult
FIN

PROCÉDURE RecupererFactureClient(id est une Chaîne) : CustomerInvoices__Response
	oRep est une apiRéponse = getCustomerInvoice(id, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("RecupererFactureClient", oRep)
		RETOUR Null
	FIN
	oFacture est un CustomerInvoices__Response = oRep.Valeur
	RETOUR oFacture
FIN

PROCÉDURE FinaliserFacture(id est une Chaîne) : Booléen
	oRep est une apiRéponse = finalizeCustomerInvoice(id, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("FinaliserFacture", oRep)
		RETOUR Faux
	FIN
	RETOUR Vrai
FIN

// Swagger : PUT /customer_invoices/{id}/mark_as_paid — aucun corps requis, retourne 204
PROCÉDURE MarquerFacturePayee(id est une Chaîne) : Booléen
	oRep est une apiRéponse = markAsPaidCustomerInvoice(id, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 204 ALORS
		GererErreur("MarquerFacturePayee", oRep)
		RETOUR Faux
	FIN
	RETOUR Vrai
FIN

// Swagger : POST /customer_invoices/{id}/send_by_email — retourne 204
PROCÉDURE EnvoyerFactureParEmail(id est une Chaîne) : Booléen
	oRep est une apiRéponse = sendByEmailCustomerInvoice(id, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 204 ALORS
		GererErreur("EnvoyerFactureParEmail", oRep)
		RETOUR Faux
	FIN
	RETOUR Vrai
FIN

PROCÉDURE ObtenirLignesFactureClient(id est une Chaîne) : Variant
	oRep est une apiRéponse = getCustomerInvoiceInvoiceLines(id, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("ObtenirLignesFactureClient", oRep)
		RETOUR Null
	FIN
	RETOUR oRep.Valeur
FIN

// Liste toutes les factures client avec pagination automatique par cursor
PROCÉDURE ListerFacturesClient(sCursor est une Chaîne) : Tableau de CustomerInvoices__Response
	tResultat      est un tableau de CustomerInvoices__Response
	sCursorCourant est une Chaîne = sCursor
	vItem          est un Variant
	TANTQUE Vrai
		oReq est une apiRequête = CréerRequête()
		SI sCursorCourant <> "" ALORS oReq.ParamètreURL["cursor"] = sCursorCourant
		oRep est une apiRéponse = getCustomerInvoices(oReq)
		SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
			GererErreur("ListerFacturesClient", oRep)
			RETOUR tResultat
		FIN
		oPage est un Variant = oRep.Valeur
		POUR TOUT vItem DE oPage.customer_invoices
			Ajoute(tResultat, vItem)
		FIN
		SI oPage.meta.next_cursor = "" ALORS SORTIR
		sCursorCourant = oPage.meta.next_cursor
	FIN
	RETOUR tResultat
FIN

// ============================================================
// FACTURES FOURNISSEURS (RÉCEPTION)
// ============================================================

// Importe une facture fournisseur depuis un fichier
PROCÉDURE ImporterFactureFournisseur(cheminFichier est une Chaîne) : SupplierInvoices__Response
	oRep est une apiRéponse = importSupplierInvoice(cheminFichier, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("ImporterFactureFournisseur", oRep)
		RETOUR Null
	FIN
	oFacture est un SupplierInvoices__Response = oRep.Valeur
	oEventBus.PublierFactureRecue(oFacture)
	SI CallbackFactureRecue <> Null ALORS Exécute(CallbackFactureRecue, oFacture)
	RETOUR oFacture
FIN

PROCÉDURE RecupererFactureFournisseur(id est une Chaîne) : SupplierInvoices__Response
	oRep est une apiRéponse = getSupplierInvoice(id, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("RecupererFactureFournisseur", oRep)
		RETOUR Null
	FIN
	oFacture est un SupplierInvoices__Response = oRep.Valeur
	RETOUR oFacture
FIN

PROCÉDURE ObtenirLignesFactureFournisseur(id est une Chaîne) : Variant
	oRep est une apiRéponse = getSupplierInvoiceLines(id, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("ObtenirLignesFactureFournisseur", oRep)
		RETOUR Null
	FIN
	RETOUR oRep.Valeur
FIN

// Liste toutes les factures fournisseur avec pagination automatique par cursor
PROCÉDURE ListerFacturesFournisseur(sCursor est une Chaîne) : Tableau de SupplierInvoices__Response
	tResultat      est un tableau de SupplierInvoices__Response
	sCursorCourant est une Chaîne = sCursor
	vItem          est un Variant
	TANTQUE Vrai
		oReq est une apiRequête = CréerRequête()
		SI sCursorCourant <> "" ALORS oReq.ParamètreURL["cursor"] = sCursorCourant
		oRep est une apiRéponse = getSupplierInvoices(oReq)
		SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
			GererErreur("ListerFacturesFournisseur", oRep)
			RETOUR tResultat
		FIN
		oPage est un Variant = oRep.Valeur
		POUR TOUT vItem DE oPage.supplier_invoices
			Ajoute(tResultat, vItem)
		FIN
		SI oPage.meta.next_cursor = "" ALORS SORTIR
		sCursorCourant = oPage.meta.next_cursor
	FIN
	RETOUR tResultat
FIN

// Conteste une facture fournisseur (statut e-invoice "disputed")
PROCÉDURE ContesterFacture(id est une Chaîne, motif est une Chaîne) : Booléen
	oStatut est un stEInvoiceStatut
	oStatut.status = "disputed"
	oStatut.reason = motif
	oRep est une apiRéponse = putSupplierInvoiceEInvoiceStatus(id, oStatut, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("ContesterFacture", oRep)
		RETOUR Faux
	FIN
	oEventBus.PublierStatutChange(id, "disputed")
	SI CallbackStatutChange <> Null ALORS Exécute(CallbackStatutChange, id, "disputed")
	RETOUR Vrai
FIN

// Refuse une facture fournisseur (statut e-invoice "refused")
PROCÉDURE RefuserFacture(id est une Chaîne, motif est une Chaîne) : Booléen
	oStatut est un stEInvoiceStatut
	oStatut.status = "refused"
	oStatut.reason = motif
	oRep est une apiRéponse = putSupplierInvoiceEInvoiceStatus(id, oStatut, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("RefuserFacture", oRep)
		RETOUR Faux
	FIN
	oEventBus.PublierStatutChange(id, "refused")
	SI CallbackStatutChange <> Null ALORS Exécute(CallbackStatutChange, id, "refused")
	RETOUR Vrai
FIN

// Annule une contestation (statut e-invoice "approved" — sans motif requis)
PROCÉDURE AnnulerContestation(id est une Chaîne) : Booléen
	oStatut est un stEInvoiceStatut
	oStatut.status = "approved"
	oRep est une apiRéponse = putSupplierInvoiceEInvoiceStatus(id, oStatut, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("AnnulerContestation", oRep)
		RETOUR Faux
	FIN
	oEventBus.PublierStatutChange(id, "approved")
	SI CallbackStatutChange <> Null ALORS Exécute(CallbackStatutChange, id, "approved")
	RETOUR Vrai
FIN

// ============================================================
// CLIENTS
// ============================================================

PROCÉDURE RecupererClient(id est une Chaîne) : Customers__Response
	oRep est une apiRéponse = getCustomer(id, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("RecupererClient", oRep)
		RETOUR Null
	FIN
	oClient est un Customers__Response = oRep.Valeur
	RETOUR oClient
FIN

PROCÉDURE ListerClients() : Variant
	oRep est une apiRéponse = getCustomers(CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("ListerClients", oRep)
		RETOUR Null
	FIN
	RETOUR oRep.Valeur
FIN

// Swagger : POST /company_customers — sans paramètre de chemin, apiRequête non générée
// httpRequête direct pour garantir l'envoi du Bearer token
PROCÉDURE CreerClientEntreprise(oClient est un stClientEntrepriseCreation) : Customers__Response
	sJson    est une Chaîne
	Sérialise(oClient, sJson, psdJSON)
	sCodeHTTP est une Chaîne
	sReponse est une Chaîne = EnvoyerPOST("/company_customers", "CreerClientEntreprise", sJson, sCodeHTTP)
	SI sReponse = "" ALORS RETOUR Null
	oResult est un Customers__Response
	Désérialise(sReponse, oResult, psdJSON)
	RETOUR oResult
FIN

// Swagger : POST /individual_customers — sans paramètre de chemin, apiRequête non générée
PROCÉDURE CreerClientParticulier(oClient est un stClientParticulierCreation) : Customers__Response
	sJson    est une Chaîne
	Sérialise(oClient, sJson, psdJSON)
	sCodeHTTP est une Chaîne
	sReponse est une Chaîne = EnvoyerPOST("/individual_customers", "CreerClientParticulier", sJson, sCodeHTTP)
	SI sReponse = "" ALORS RETOUR Null
	oResult est un Customers__Response
	Désérialise(sReponse, oResult, psdJSON)
	RETOUR oResult
FIN

// ============================================================
// FOURNISSEURS
// ============================================================

PROCÉDURE RecupererFournisseur(id est une Chaîne) : Suppliers__Response
	oRep est une apiRéponse = getSupplier(id, CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("RecupererFournisseur", oRep)
		RETOUR Null
	FIN
	oFournisseur est un Suppliers__Response = oRep.Valeur
	RETOUR oFournisseur
FIN

PROCÉDURE ListerFournisseurs() : Variant
	oRep est une apiRéponse = getSuppliers(CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("ListerFournisseurs", oRep)
		RETOUR Null
	FIN
	RETOUR oRep.Valeur
FIN

// Swagger : POST /suppliers — sans paramètre de chemin, apiRequête non générée
PROCÉDURE CreerFournisseur(oFournisseur est un stFournisseurCreation) : Suppliers__Response
	sJson    est une Chaîne
	Sérialise(oFournisseur, sJson, psdJSON)
	sCodeHTTP est une Chaîne
	sReponse est une Chaîne = EnvoyerPOST("/suppliers", "CreerFournisseur", sJson, sCodeHTTP)
	SI sReponse = "" ALORS RETOUR Null
	oResult est un Suppliers__Response
	Désérialise(sReponse, oResult, psdJSON)
	RETOUR oResult
FIN

// ============================================================
// PA REGISTRATIONS
// ============================================================

PROCÉDURE ListerInscriptionsPA() : Tableau de PDPAddresses__Response
	tResultat est un tableau de PDPAddresses__Response
	vItem     est un Variant
	oRep est une apiRéponse = getPaRegistrations(CréerRequête())
	SI oRep.RéponseHTTP.CodeEtat <> 200 ALORS
		GererErreur("ListerInscriptionsPA", oRep)
		RETOUR tResultat
	FIN
	POUR TOUT vItem DE oRep.Valeur
		Ajoute(tResultat, vItem)
	FIN
	RETOUR tResultat
FIN

FIN CLASSE
