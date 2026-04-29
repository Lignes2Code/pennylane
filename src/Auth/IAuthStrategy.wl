// ============================================================
// Interface : IAuthStrategy
// Rôle      : Contrat commun des deux méthodes d'authentification.
// Pattern   : Strategy
// ============================================================
INTERFACE IAuthStrategy

	// Retourne le header Authorization : "Bearer <token>"
	PROCÉDURE ObtenirHeader() : Chaîne

	// Vrai si le token courant est encore valide
	PROCÉDURE EstValide() : Booléen

	// Renouvelle le token si possible — retourne Vrai si succès
	PROCÉDURE Rafraichir() : Booléen

	// Lance l'authentification complète (flow complet ou chargement token)
	PROCÉDURE Authentifier() : Booléen

FIN INTERFACE
