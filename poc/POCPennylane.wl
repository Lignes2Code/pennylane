// ============================================================
// POC Pennylane — Fichier de test autonome
// Ajouter ce fichier au projet WinDev, puis appeler
// POC_LancerTous() depuis un bouton de fenêtre de test.
//
// Prérequis :
//   1. Copier poc\config_poc.json dans un dossier accessible
//   2. Renseigner "ClientSecret" avec votre token développeur
//      (Pennylane sandbox → Paramètres → API → Créer un token)
//   3. Ajuster la constante POC_CHEMIN_CONFIG ci-dessous
// ============================================================

CONSTANTE
	POC_CHEMIN_CONFIG = "C:\Mes Projets\pennylane\poc\config_poc.json"
FIN

// ============================================================
// Procédure principale — lance tous les tests en séquence
// ============================================================
PROCÉDURE POC_LancerTous()
	oFacade est un CPennylaneFacade

	// ----- Initialisation avec token dev -----
	Trace("=== POC Pennylane — démarrage ===")

	SI PAS oFacade.InitialiserAvecTokenDev(POC_CHEMIN_CONFIG, "") ALORS
		Trace("ERREUR : Impossible de charger la config : " + POC_CHEMIN_CONFIG)
		Erreur("Impossible de charger la config." + RC + "Vérifiez POC_CHEMIN_CONFIG et le fichier config_poc.json.")
		RETOUR
	FIN
	Trace("OK : Initialisation réussie")

	// ----- Branchement erreur -----
	oFacade.CallbackErreur = PROCÉDURE INTERNE(sCode est une Chaîne, sMsg est une Chaîne)
		Trace("ERREUR API [" + sCode + "] " + sMsg)
	FIN PROCÉDURE INTERNE

	// ----- Test 1 : Profil utilisateur -----
	POC_TestProfil(oFacade)

	// ----- Test 2 : Lister les clients -----
	POC_TestListerClients(oFacade)

	// ----- Test 3 : Lister les factures client -----
	POC_TestListerFacturesClient(oFacade)

	// ----- Test 4 : Lister les fournisseurs -----
	POC_TestListerFournisseurs(oFacade)

	// ----- Test 5 : Lister les factures fournisseur -----
	POC_TestListerFacturesFournisseur(oFacade)

	// ----- Test 6 : Création client entreprise -----
	POC_TestCreerClientEntreprise(oFacade)

	// ----- Test 7 : Création fournisseur -----
	POC_TestCreerFournisseur(oFacade)

	Trace("=== POC terminé — voir fenêtre de trace ===")
	Info("POC terminé." + RC + "Consultez la fenêtre de trace (Ctrl+F8) pour les résultats.")
FIN

// ============================================================
// Test 1 — Profil utilisateur (GET /me)
// ============================================================
PROCÉDURE POC_TestProfil(oFacade est un CPennylaneFacade)
	Trace("--- Test 1 : ObtenirProfil ---")
	oProfil est un Variant = oFacade.ObtenirProfil()
	SI oProfil = Null ALORS
		Trace("ÉCHEC : ObtenirProfil a retourné Null")
		RETOUR
	FIN
	Trace("OK : company_name = " + oProfil.company_name)
	Trace("OK : email        = " + oProfil.email)
FIN

// ============================================================
// Test 2 — Lister les clients (GET /customers)
// ============================================================
PROCÉDURE POC_TestListerClients(oFacade est un CPennylaneFacade)
	Trace("--- Test 2 : ListerClients ---")
	oResultat est un Variant = oFacade.ListerClients()
	SI oResultat = Null ALORS
		Trace("ÉCHEC : ListerClients a retourné Null")
		RETOUR
	FIN
	Trace("OK : premier appel reçu")
FIN

// ============================================================
// Test 3 — Lister les factures client avec pagination
// ============================================================
PROCÉDURE POC_TestListerFacturesClient(oFacade est un CPennylaneFacade)
	Trace("--- Test 3 : ListerFacturesClient ---")
	tFactures est un Tableau de CustomerInvoices__Response
	tFactures = oFacade.ListerFacturesClient("")
	Trace("OK : " + Taille(tFactures) + " facture(s) client récupérée(s)")
	SI Taille(tFactures) > 0 ALORS
		Trace("     Première facture : id=" + tFactures[1].id + ", statut=" + tFactures[1].status)
	FIN
FIN

// ============================================================
// Test 4 — Lister les fournisseurs (GET /suppliers)
// ============================================================
PROCÉDURE POC_TestListerFournisseurs(oFacade est un CPennylaneFacade)
	Trace("--- Test 4 : ListerFournisseurs ---")
	oResultat est un Variant = oFacade.ListerFournisseurs()
	SI oResultat = Null ALORS
		Trace("ÉCHEC : ListerFournisseurs a retourné Null")
		RETOUR
	FIN
	Trace("OK : premier appel reçu")
FIN

// ============================================================
// Test 5 — Lister les factures fournisseur avec pagination
// ============================================================
PROCÉDURE POC_TestListerFacturesFournisseur(oFacade est un CPennylaneFacade)
	Trace("--- Test 5 : ListerFacturesFournisseur ---")
	tFactures est un Tableau de SupplierInvoices__Response
	tFactures = oFacade.ListerFacturesFournisseur("")
	Trace("OK : " + Taille(tFactures) + " facture(s) fournisseur récupérée(s)")
	SI Taille(tFactures) > 0 ALORS
		Trace("     Première facture : id=" + tFactures[1].id + ", statut=" + tFactures[1].status)
	FIN
FIN

// ============================================================
// Test 6 — Création d'un client entreprise (POST /company_customers)
// Désactivé par défaut (crée réellement un enregistrement sandbox)
// Décommenter pour tester
// ============================================================
PROCÉDURE POC_TestCreerClientEntreprise(oFacade est un CPennylaneFacade)
	Trace("--- Test 6 : CreerClientEntreprise (DÉSACTIVÉ — décommenter pour tester) ---")
	RETOUR // <-- Supprimer cette ligne pour activer le test

	/*
	oAdresse est un stPennylaneAdresse
	oAdresse.address        = "8 rue de la Paix"
	oAdresse.postal_code    = "75002"
	oAdresse.city           = "Paris"
	oAdresse.country_alpha2 = "FR"

	oClient est un stClientEntrepriseCreation
	oClient.name            = "POC Test SARL"
	oClient.vat_number      = "FR00000000000"
	oClient.reg_no          = "000000000"
	oClient.phone           = "+33100000000"
	oClient.billing_address = oAdresse

	oResultat est un Customers__Response = oFacade.CreerClientEntreprise(oClient)
	SI oResultat = Null ALORS
		Trace("ÉCHEC : CreerClientEntreprise a retourné Null")
		RETOUR
	FIN
	Trace("OK : client créé, id=" + oResultat.id)
	*/
FIN

// ============================================================
// Test 7 — Création d'un fournisseur (POST /suppliers)
// Désactivé par défaut (crée réellement un enregistrement sandbox)
// Décommenter pour tester
// ============================================================
PROCÉDURE POC_TestCreerFournisseur(oFacade est un CPennylaneFacade)
	Trace("--- Test 7 : CreerFournisseur (DÉSACTIVÉ — décommenter pour tester) ---")
	RETOUR // <-- Supprimer cette ligne pour activer le test

	/*
	oAdresse est un stPennylaneAdresse
	oAdresse.address        = "1 avenue de l'Opéra"
	oAdresse.postal_code    = "75001"
	oAdresse.city           = "Paris"
	oAdresse.country_alpha2 = "FR"

	oFourn est un stFournisseurCreation
	oFourn.name             = "Fournisseur POC"
	oFourn.establishment_no = "82762938500014"
	oFourn.reg_no           = "827629385"
	oFourn.phone            = "+33100000000"
	oFourn.billing_address  = oAdresse

	oResultat est un Suppliers__Response = oFacade.CreerFournisseur(oFourn)
	SI oResultat = Null ALORS
		Trace("ÉCHEC : CreerFournisseur a retourné Null")
		RETOUR
	FIN
	Trace("OK : fournisseur créé, id=" + oResultat.id)
	*/
FIN
