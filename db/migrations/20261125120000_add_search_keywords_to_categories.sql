-- ============================================
-- Migration: 20261125120000_add_search_keywords_to_categories
-- Description: Words that find a category in a search although its label
--              does not contain them: "essence" finds "Carburant et recharge".
--              They are what people type when they think of what they paid.
--              Shared by every client (application, browser extension),
--              which read them from GET /categories.
-- Author: Floris Robart
-- ============================================



-- migrate:up

ALTER TABLE categories ADD COLUMN search_keywords TEXT[] NOT NULL DEFAULT '{}';

UPDATE categories
SET search_keywords = category_keywords.search_keywords
FROM (VALUES
    ('income_salary', ARRAY['paie', 'paye', 'travail']),
    ('income_bonus', ARRAY['prime', '13e mois', 'intéressement', 'participation']),
    ('income_self_employment', ARRAY['freelance', 'auto-entrepreneur', 'facture']),
    ('income_unemployment', ARRAY['France Travail', 'Pôle emploi', 'ARE']),
    ('income_benefits', ARRAY['CAF', 'APL', 'RSA', 'prime d''activité', 'bourse']),
    ('income_allowances', ARRAY['indemnités journalières', 'stage', 'gratification']),
    ('income_rental', ARRAY['locataire', 'loyer perçu']),
    ('income_refunds', ARRAY['Ameli', 'CPAM', 'sécu', 'avoir']),
    ('income_second_hand_sales', ARRAY['Vinted', 'Leboncoin', 'vente']),
    ('income_gifts', ARRAY['héritage']),
    ('income_gambling', ARRAY['loto', 'PMU', 'paris sportifs']),

    ('housing_rent', ARRAY['bail', 'propriétaire']),
    ('housing_mortgage', ARRAY['crédit immobilier', 'emprunt']),
    ('housing_condo_fees', ARRAY['syndic']),
    ('housing_electricity', ARRAY['EDF', 'compteur']),
    ('housing_gas_heating', ARRAY['fioul', 'bois', 'granulés', 'chaudière']),
    ('housing_water', ARRAY['facture d''eau']),
    ('housing_insurance', ARRAY['multirisque']),
    ('housing_works', ARRAY['plombier', 'électricien', 'rénovation', 'peinture']),
    ('housing_furniture', ARRAY['Ikea', 'canapé', 'lit', 'déco']),
    ('housing_appliances', ARRAY['frigo', 'lave-linge', 'four', 'aspirateur']),
    ('housing_diy', ARRAY['Leroy Merlin', 'Castorama', 'outils']),
    ('housing_garden', ARRAY['plantes', 'jardinerie', 'tondeuse']),
    ('housing_home_help', ARRAY['femme de ménage', 'CESU']),
    ('housing_moving', ARRAY['cartons']),

    ('food_groceries', ARRAY['supermarché', 'épicerie', 'Leclerc', 'Carrefour', 'Lidl', 'Auchan', 'Intermarché']),
    ('food_local_shops', ARRAY['boucherie', 'primeur', 'fromager', 'marché', 'pain']),
    ('food_restaurants', ARRAY['resto', 'brasserie']),
    ('food_fast_food', ARRAY['fast-food', 'kebab', 'burger', 'McDo', 'pizza']),
    ('food_delivery', ARRAY['Uber Eats', 'Deliveroo']),
    ('food_work_meals', ARRAY['cantine', 'self', 'ticket restaurant']),

    ('transport_public', ARRAY['bus', 'métro', 'tram', 'RER', 'Navigo']),
    ('transport_train', ARRAY['SNCF', 'TGV', 'TER', 'Ouigo']),
    ('transport_plane', ARRAY['vol', 'aéroport']),
    ('transport_taxi', ARRAY['Uber', 'Bolt']),
    ('transport_vehicle_purchase', ARRAY['voiture', 'moto', 'scooter']),
    ('transport_car_loan', ARRAY['LOA', 'LLD']),
    ('transport_fuel', ARRAY['essence', 'gazole', 'diesel', 'station', 'borne']),
    ('transport_insurance', ARRAY['auto', 'moto']),
    ('transport_maintenance', ARRAY['garage', 'révision', 'pneus', 'vidange', 'contrôle technique']),
    ('transport_parking', ARRAY['stationnement', 'horodateur']),
    ('transport_tolls', ARRAY['autoroute', 'télépéage']),
    ('transport_driving_licence', ARRAY['auto-école', 'code de la route']),

    ('health_doctors', ARRAY['généraliste', 'spécialiste', 'consultation', 'docteur']),
    ('health_pharmacy', ARRAY['médicaments', 'ordonnance']),
    ('health_dentist', ARRAY['dentaire', 'orthodontiste']),
    ('health_optics', ARRAY['lunettes', 'lentilles', 'opticien']),
    ('health_lab_imaging', ARRAY['prise de sang', 'laboratoire', 'radio', 'IRM']),
    ('health_hospital', ARRAY['clinique', 'urgences']),
    ('health_paramedical', ARRAY['kiné', 'ostéopathe', 'infirmier', 'orthophoniste']),
    ('health_psychologist', ARRAY['psy', 'thérapie']),
    ('health_mutual_insurance', ARRAY['complémentaire santé']),

    ('shopping_clothes', ARRAY['habits']),
    ('shopping_shoes', ARRAY['baskets']),
    ('shopping_fashion_accessories', ARRAY['sac', 'ceinture', 'lunettes de soleil']),
    ('shopping_jewelry_watches', ARRAY['bague', 'collier', 'bracelet']),
    ('shopping_dry_cleaning', ARRAY['couturière']),

    ('high_tech_internet', ARRAY['box', 'fibre', 'wifi']),
    ('high_tech_mobile_plan', ARRAY['carte SIM', 'abonnement téléphone']),
    ('high_tech_computers', ARRAY['PC', 'Mac', 'iPad']),
    ('high_tech_phones', ARRAY['smartphone', 'iPhone', 'portable']),
    ('high_tech_audio_video', ARRAY['télé', 'TV', 'casque', 'enceinte', 'écouteurs']),
    ('high_tech_accessories', ARRAY['câble', 'chargeur', 'clavier', 'souris', 'coque']),
    ('high_tech_software', ARRAY['cloud', 'iCloud', 'licence']),

    ('leisure_sport', ARRAY['salle de sport', 'club', 'fitness', 'piscine']),
    ('leisure_cinema', ARRAY['film', 'séance']),
    ('leisure_shows_culture', ARRAY['concert', 'théâtre', 'musée', 'festival']),
    ('leisure_bars', ARRAY['verre', 'apéro']),
    ('leisure_books_press', ARRAY['livre', 'journal', 'magazine', 'BD']),
    ('leisure_streaming', ARRAY['Netflix', 'Spotify', 'Disney', 'Deezer', 'Prime Video', 'YouTube', 'Canal']),
    ('leisure_video_games', ARRAY['console', 'Steam', 'PlayStation', 'Xbox']),
    ('leisure_gambling', ARRAY['loto', 'PMU', 'paris sportifs', 'casino', 'FDJ']),
    ('leisure_hobbies', ARRAY['musique', 'instrument', 'photo']),
    ('leisure_activities', ARRAY['bowling', 'escape game', 'parc d''attractions']),
    ('leisure_tobacco', ARRAY['cigarettes', 'vape']),

    ('travel_accommodation', ARRAY['hôtel', 'Airbnb', 'camping', 'gîte']),
    ('travel_packages', ARRAY['croisière', 'circuit']),
    ('travel_activities', ARRAY['visite']),
    ('travel_winter_sports', ARRAY['ski', 'forfait de ski']),

    ('family_childcare', ARRAY['crèche', 'nounou', 'assistante maternelle']),
    ('family_baby', ARRAY['couches', 'bébé', 'poussette']),
    ('family_toys', ARRAY['jeux']),
    ('family_extracurricular', ARRAY['centre de loisirs']),
    ('family_school_canteen', ARRAY['garderie']),
    ('family_relatives_support', ARRAY['EHPAD', 'parents']),
    ('family_events', ARRAY['mariage', 'naissance', 'baptême', 'obsèques']),

    ('pets_food', ARRAY['croquettes', 'pâtée']),
    ('pets_vet', ARRAY['vaccin']),
    ('pets_accessories', ARRAY['litière', 'laisse', 'panier']),
    ('pets_grooming_care', ARRAY['toiletteur', 'pension']),
    ('pets_insurance', ARRAY['mutuelle']),
    ('pets_adoption', ARRAY['chiot', 'chaton']),

    ('education_tuition', ARRAY['école', 'université', 'inscription']),
    ('education_supplies', ARRAY['cahiers', 'stylos', 'manuels']),
    ('education_tutoring', ARRAY['soutien scolaire']),
    ('education_training', ARRAY['CPF', 'certification']),

    ('work_expenses', ARRAY['note de frais']),
    ('work_business_travel', ARRAY['mission']),
    ('work_social_contributions', ARRAY['URSSAF', 'cotisations sociales']),
    ('work_professional_fees', ARRAY['syndicat']),
    ('work_office', ARRAY['local']),

    ('beauty_hairdresser', ARRAY['coiffure', 'barbier']),
    ('beauty_aesthetics', ARRAY['institut', 'épilation', 'manucure', 'ongles']),
    ('beauty_cosmetics', ARRAY['maquillage', 'crème']),
    ('beauty_hygiene', ARRAY['shampoing', 'gel douche', 'dentifrice', 'savon']),
    ('beauty_spa', ARRAY['hammam']),

    ('bank_fees', ARRAY['agios', 'frais de tenue de compte', 'carte bancaire']),
    ('bank_loans', ARRAY['emprunt']),
    ('bank_insurance', ARRAY['responsabilité civile', 'protection juridique']),

    ('taxes_income', ARRAY['impôts', 'prélèvement à la source']),
    ('taxes_fines', ARRAY['PV', 'contravention']),
    ('taxes_administrative_fees', ARRAY['passeport', 'carte d''identité', 'carte grise', 'timbre fiscal']),

    ('savings_accounts', ARRAY['Livret A', 'LDDS', 'LEP']),
    ('savings_housing', ARRAY['PEL', 'CEL']),
    ('savings_employee', ARRAY['PEE', 'PERCO']),
    ('savings_retirement', ARRAY['PER']),

    ('investment_real_estate', ARRAY['SCPI', 'locatif']),
    ('investment_stocks', ARRAY['ETF', 'PEA', 'compte-titres']),
    ('investment_crypto', ARRAY['Bitcoin', 'Ethereum', 'crypto']),
    ('investment_precious_metals', ARRAY['or', 'lingot']),
    ('investment_crowdfunding', ARRAY['crowdfunding']),

    ('gifts_presents', ARRAY['anniversaire', 'Noël']),
    ('gifts_donations', ARRAY['don', 'association', 'charité']),
    ('gifts_shared_pots', ARRAY['cagnotte', 'Leetchi']),

    ('transfers_internal', ARRAY['virement', 'transfert']),
    ('transfers_cash_withdrawal', ARRAY['retrait', 'distributeur', 'DAB']),
    ('transfers_loans_to_relatives', ARRAY['prêt', 'ami'])
) AS category_keywords (code, search_keywords)
WHERE categories.code = category_keywords.code;



-- migrate:down

ALTER TABLE categories DROP COLUMN search_keywords;
