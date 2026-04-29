// ============================================================
// Fichier   : CPennylaneTypes.wl
// Rôle      : Structures de requêtes typées basées sur le Swagger
//             Pennylane API v2 (https://app.pennylane.com/api/external/v2)
// Usage     : Paramètres des méthodes de CPennylaneFacade
// ============================================================

// -----------------------------------------------------------
// Adresse (utilisée dans les adresses de facturation/livraison)
// Swagger : propriétés "billing_address" / "delivery_address"
// -----------------------------------------------------------
stPennylaneAdresse est une Structure
	address        est une Chaîne        // Rue et numéro
	postal_code    est une Chaîne        // Code postal
	city           est une Chaîne        // Ville
	country_alpha2 est une Chaîne = "FR" // Code pays ISO 3166-1 alpha-2
FIN

// -----------------------------------------------------------
// Ligne de facture client
// Swagger : "line_items_attributes[]" dans postCustomerInvoices
// -----------------------------------------------------------
stLigneFactureClient est une Structure
	label        est une Chaîne    // Description de la ligne
	quantity     est un Réel       // Quantité
	unit_amount  est un Réel       // Montant HT unitaire (en euros)
	vat_rate     est une Chaîne    // Ex. : "FR_200" (TVA 20 %)
	product_id   est un Entier     // Identifiant produit Pennylane (optionnel)
FIN

// -----------------------------------------------------------
// Création d'une facture client
// Swagger : POST /customer_invoices  (operationId : postCustomerInvoices)
// Corps    : anyOf [DraftCustomerInvoice | FinalizedCustomerInvoice]
// -----------------------------------------------------------
stFactureClientCreation est une Structure
	date                  est une Chaîne                       // Date facture  (YYYY-MM-DD)
	deadline              est une Chaîne                       // Date échéance (YYYY-MM-DD)
	customer_id           est un Entier                        // Identifiant client Pennylane
	line_items_attributes est un Tableau de stLigneFactureClient
FIN

// -----------------------------------------------------------
// Création d'un client entreprise
// Swagger : POST /company_customers  (operationId : postCompanyCustomer)
// -----------------------------------------------------------
stClientEntrepriseCreation est une Structure
	name             est une Chaîne           // Raison sociale
	vat_number       est une Chaîne           // N° TVA intracommunautaire
	reg_no           est une Chaîne           // N° SIREN / enregistrement
	phone            est une Chaîne           // Téléphone
	billing_address  est un stPennylaneAdresse
	delivery_address est un stPennylaneAdresse
FIN

// -----------------------------------------------------------
// Création d'un client particulier
// Swagger : POST /individual_customers  (operationId : postIndividualCustomer)
// -----------------------------------------------------------
stClientParticulierCreation est une Structure
	first_name       est une Chaîne
	last_name        est une Chaîne
	phone            est une Chaîne
	billing_address  est un stPennylaneAdresse
	delivery_address est un stPennylaneAdresse
FIN

// -----------------------------------------------------------
// Création d'un fournisseur
// Swagger : POST /suppliers  (operationId : postSupplier)
// -----------------------------------------------------------
stFournisseurCreation est une Structure
	name             est une Chaîne           // Raison sociale
	establishment_no est une Chaîne           // SIRET 14 chiffres (France)
	reg_no           est une Chaîne           // SIREN 9 chiffres (France)
	phone            est une Chaîne
	billing_address  est un stPennylaneAdresse
FIN

// -----------------------------------------------------------
// Statut e-invoice fournisseur
// Swagger : PUT /supplier_invoices/{id}/e_invoice_status
//           (operationId : putSupplierInvoiceEInvoiceStatus)
// Valeurs status  : "disputed" | "refused" | "approved"
// Valeurs reason  : requis pour "disputed" et "refused"
//   "incorrect_vat_rate" | "incorrect_unit_prices" | "incorrect_billed_quantity"
//   "incorrect_billed_item" | "defective_delivered_item" | "delivery_issue"
//   "bank_details_error"  | "incorrect_payment_terms"  | "missing_legal_notice"
//   "missing_contractual_reference" | "recipient_error"
//   "contract_completed"  | "duplicate_invoice"        | "non_compliant_invoice"
//   "incorrect_prices"
// -----------------------------------------------------------
stEInvoiceStatut est une Structure
	status est une Chaîne   // "disputed" | "refused" | "approved"
	reason est une Chaîne   // Requis si disputed ou refused
FIN
