// ============================================================
// Interface : IObserver
// Rôle      : Contrat du Pattern Observer pour les événements Pennylane.
//             L'application maître implémente cette interface pour être notifiée.
// Pattern   : Observer
// ============================================================
INTERFACE IObserver

	PROCÉDURE SurTokenRefraichi(oToken est un CPennylaneToken)
	PROCÉDURE SurFactureEmise(oFacture est un CustomerInvoices__Response)
	PROCÉDURE SurFactureRecue(oFacture est un SupplierInvoices__Response)
	PROCÉDURE SurStatutChange(id est une Chaîne, statut est une Chaîne)
	PROCÉDURE SurErreur(code est une Chaîne, sMessage est une Chaîne)

FIN INTERFACE
