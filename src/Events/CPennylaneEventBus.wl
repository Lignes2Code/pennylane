// ============================================================
// Classe : CPennylaneEventBus
// Rôle   : Dispatch des événements vers tous les IObserver enregistrés.
// Pattern: Observer / Event Bus
// ============================================================
CLASSE CPennylaneEventBus

// Liste des abonnés indexée par identifiant unique
Observateurs est un tableau associatif de IObserver

// ============================================================
// MÉTHODES PUBLIQUES — Gestion des abonnements
// ============================================================

// Retourne l'identifiant d'abonnement à conserver pour pouvoir se désabonner
PROCÉDURE Abonner(obs est un IObserver) : Chaîne
	sID est une Chaîne = UUID()
	Observateurs[sID] = obs
	RETOUR sID
FIN

PROCÉDURE Desabonner(sID est une Chaîne)
	Supprime(Observateurs, sID)
FIN

// ============================================================
// MÉTHODES PUBLIQUES — Publication d'événements
// ============================================================

PROCÉDURE PublierTokenRefraichi(oToken est un CPennylaneToken)
	POUR TOUT obs DE Observateurs
		obs.SurTokenRefraichi(oToken)
	FIN
FIN

PROCÉDURE PublierFactureEmise(oFacture est un CustomerInvoices__Response)
	POUR TOUT obs DE Observateurs
		obs.SurFactureEmise(oFacture)
	FIN
FIN

PROCÉDURE PublierFactureRecue(oFacture est un SupplierInvoices__Response)
	POUR TOUT obs DE Observateurs
		obs.SurFactureRecue(oFacture)
	FIN
FIN

PROCÉDURE PublierStatutChange(id est une Chaîne, statut est une Chaîne)
	POUR TOUT obs DE Observateurs
		obs.SurStatutChange(id, statut)
	FIN
FIN

PROCÉDURE PublierErreur(code est une Chaîne, sMessage est une Chaîne)
	POUR TOUT obs DE Observateurs
		obs.SurErreur(code, sMessage)
	FIN
FIN

FIN CLASSE
