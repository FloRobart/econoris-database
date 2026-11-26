-- ============================================
-- Migration: 20261124234100_insert_default_categories
-- Description: Default tree of categories: 21 main categories and their
--              sub-categories, covering every aspect of daily life.
--              The labels are in French, as shown to the users.
--              The codes are in English and never change: a main category
--              code is a single word, and a sub-category code starts with
--              the code of its main category.
-- Author: Floris Robart
-- ============================================



-- migrate:up

-- ------------------------------------------
-- Main categories
-- ------------------------------------------

INSERT INTO categories (code, label) VALUES
    ('income', 'Revenus'),
    ('housing', 'Logement'),
    ('food', 'Alimentation'),
    ('transport', 'Transports'),
    ('health', 'Santé'),
    ('shopping', 'Shopping'),
    ('high_tech', 'High-tech et télécoms'),
    ('leisure', 'Loisirs et sorties'),
    ('travel', 'Voyages et vacances'),
    ('family', 'Famille et enfants'),
    ('pets', 'Animaux'),
    ('education', 'Éducation et formation'),
    ('work', 'Travail'),
    ('beauty', 'Beauté et bien-être'),
    ('bank', 'Banque et assurances'),
    ('taxes', 'Impôts et taxes'),
    ('savings', 'Épargne'),
    ('investment', 'Investissement'),
    ('gifts', 'Cadeaux et dons'),
    ('transfers', 'Virements et retraits'),
    ('other', 'Autres');



-- ------------------------------------------
-- Sub-categories
-- ------------------------------------------

-- Each sub-category finds the id of its main category through the code of this main category
INSERT INTO categories (code, label, parent_id)
SELECT sub_category.code, sub_category.label, main_category.id
FROM (VALUES
    ('income', 'income_salary', 'Salaire'),
    ('income', 'income_bonus', 'Primes et bonus'),
    ('income', 'income_self_employment', 'Revenus d''indépendant'),
    ('income', 'income_unemployment', 'Allocations chômage'),
    ('income', 'income_benefits', 'Aides et allocations'),
    ('income', 'income_retirement', 'Retraite et pensions'),
    ('income', 'income_allowances', 'Indemnités'),
    ('income', 'income_rental', 'Revenus locatifs'),
    ('income', 'income_investment', 'Dividendes et intérêts'),
    ('income', 'income_refunds', 'Remboursements'),
    ('income', 'income_second_hand_sales', 'Ventes d''occasion'),
    ('income', 'income_gifts', 'Cadeaux et dons reçus'),
    ('income', 'income_gambling', 'Gains aux jeux'),

    ('housing', 'housing_rent', 'Loyer'),
    ('housing', 'housing_mortgage', 'Prêt immobilier'),
    ('housing', 'housing_condo_fees', 'Charges de copropriété'),
    ('housing', 'housing_electricity', 'Électricité'),
    ('housing', 'housing_gas_heating', 'Gaz et chauffage'),
    ('housing', 'housing_water', 'Eau'),
    ('housing', 'housing_insurance', 'Assurance habitation'),
    ('housing', 'housing_works', 'Travaux et réparations'),
    ('housing', 'housing_furniture', 'Meubles et décoration'),
    ('housing', 'housing_appliances', 'Électroménager'),
    ('housing', 'housing_diy', 'Bricolage'),
    ('housing', 'housing_garden', 'Jardinage'),
    ('housing', 'housing_home_help', 'Ménage et aide à domicile'),
    ('housing', 'housing_moving', 'Déménagement'),

    ('food', 'food_groceries', 'Courses'),
    ('food', 'food_local_shops', 'Boulangerie et commerces de bouche'),
    ('food', 'food_restaurants', 'Restaurants'),
    ('food', 'food_fast_food', 'Restauration rapide'),
    ('food', 'food_delivery', 'Livraison de repas'),
    ('food', 'food_work_meals', 'Repas au travail'),

    ('transport', 'transport_public', 'Transports en commun'),
    ('transport', 'transport_train', 'Train'),
    ('transport', 'transport_plane', 'Avion'),
    ('transport', 'transport_taxi', 'Taxi et VTC'),
    ('transport', 'transport_bike_scooter', 'Vélo et trottinette'),
    ('transport', 'transport_vehicle_purchase', 'Achat de véhicule'),
    ('transport', 'transport_car_loan', 'Crédit auto'),
    ('transport', 'transport_vehicle_rental', 'Location de véhicule'),
    ('transport', 'transport_fuel', 'Carburant et recharge'),
    ('transport', 'transport_maintenance', 'Entretien du véhicule'),
    ('transport', 'transport_insurance', 'Assurance véhicule'),
    ('transport', 'transport_parking', 'Parking'),
    ('transport', 'transport_tolls', 'Péage'),
    ('transport', 'transport_driving_licence', 'Permis de conduire'),

    ('health', 'health_doctors', 'Médecins'),
    ('health', 'health_pharmacy', 'Pharmacie'),
    ('health', 'health_dentist', 'Dentiste'),
    ('health', 'health_optics', 'Optique'),
    ('health', 'health_lab_imaging', 'Analyses et imagerie'),
    ('health', 'health_hospital', 'Hôpital'),
    ('health', 'health_paramedical', 'Paramédical'),
    ('health', 'health_psychologist', 'Psychologue'),
    ('health', 'health_mutual_insurance', 'Mutuelle'),

    ('shopping', 'shopping_clothes', 'Vêtements'),
    ('shopping', 'shopping_shoes', 'Chaussures'),
    ('shopping', 'shopping_fashion_accessories', 'Accessoires de mode'),
    ('shopping', 'shopping_jewelry_watches', 'Bijoux et montres'),
    ('shopping', 'shopping_dry_cleaning', 'Pressing et retouches'),

    ('high_tech', 'high_tech_internet', 'Box internet'),
    ('high_tech', 'high_tech_mobile_plan', 'Forfait mobile'),
    ('high_tech', 'high_tech_computers', 'Ordinateurs et tablettes'),
    ('high_tech', 'high_tech_phones', 'Téléphones'),
    ('high_tech', 'high_tech_audio_video', 'Image et son'),
    ('high_tech', 'high_tech_accessories', 'Accessoires high-tech'),
    ('high_tech', 'high_tech_software', 'Logiciels et applications'),

    ('leisure', 'leisure_sport', 'Sport'),
    ('leisure', 'leisure_cinema', 'Cinéma'),
    ('leisure', 'leisure_shows_culture', 'Spectacles et culture'),
    ('leisure', 'leisure_bars', 'Bars et cafés'),
    ('leisure', 'leisure_books_press', 'Livres et presse'),
    ('leisure', 'leisure_streaming', 'Streaming'),
    ('leisure', 'leisure_video_games', 'Jeux vidéo'),
    ('leisure', 'leisure_gambling', 'Jeux d''argent'),
    ('leisure', 'leisure_hobbies', 'Hobbies et loisirs créatifs'),
    ('leisure', 'leisure_activities', 'Parcs et activités'),
    ('leisure', 'leisure_tobacco', 'Tabac et vapotage'),

    ('travel', 'travel_accommodation', 'Hébergement'),
    ('travel', 'travel_packages', 'Séjours organisés'),
    ('travel', 'travel_activities', 'Activités et excursions'),
    ('travel', 'travel_winter_sports', 'Sports d''hiver'),

    ('family', 'family_childcare', 'Garde d''enfants'),
    ('family', 'family_baby', 'Puériculture'),
    ('family', 'family_toys', 'Jouets'),
    ('family', 'family_extracurricular', 'Activités extrascolaires'),
    ('family', 'family_school_canteen', 'Cantine et périscolaire'),
    ('family', 'family_pocket_money', 'Argent de poche'),
    ('family', 'family_alimony', 'Pension alimentaire'),
    ('family', 'family_relatives_support', 'Aide aux proches'),
    ('family', 'family_events', 'Événements familiaux'),

    ('pets', 'pets_food', 'Nourriture pour animaux'),
    ('pets', 'pets_vet', 'Vétérinaire'),
    ('pets', 'pets_accessories', 'Accessoires pour animaux'),
    ('pets', 'pets_grooming_care', 'Toilettage et garde'),
    ('pets', 'pets_insurance', 'Assurance animaux'),
    ('pets', 'pets_adoption', 'Achat et adoption'),

    ('education', 'education_tuition', 'Frais de scolarité'),
    ('education', 'education_supplies', 'Fournitures scolaires'),
    ('education', 'education_tutoring', 'Cours particuliers'),
    ('education', 'education_training', 'Formations'),
    ('education', 'education_student_loan', 'Prêt étudiant'),

    ('work', 'work_expenses', 'Frais professionnels'),
    ('work', 'work_equipment', 'Matériel professionnel'),
    ('work', 'work_business_travel', 'Déplacements professionnels'),
    ('work', 'work_social_contributions', 'Charges sociales'),
    ('work', 'work_professional_fees', 'Cotisations professionnelles'),
    ('work', 'work_office', 'Bureau et coworking'),

    ('beauty', 'beauty_hairdresser', 'Coiffeur'),
    ('beauty', 'beauty_aesthetics', 'Esthétique'),
    ('beauty', 'beauty_cosmetics', 'Cosmétiques et parfums'),
    ('beauty', 'beauty_hygiene', 'Produits d''hygiène'),
    ('beauty', 'beauty_spa', 'Spa et massages'),

    ('bank', 'bank_fees', 'Frais bancaires'),
    ('bank', 'bank_loans', 'Prêts et crédits'),
    ('bank', 'bank_insurance', 'Prévoyance et assurances diverses'),

    ('taxes', 'taxes_income', 'Impôt sur le revenu'),
    ('taxes', 'taxes_property', 'Taxe foncière'),
    ('taxes', 'taxes_housing', 'Taxe d''habitation'),
    ('taxes', 'taxes_fines', 'Amendes'),
    ('taxes', 'taxes_administrative_fees', 'Frais administratifs'),

    ('savings', 'savings_accounts', 'Livrets d''épargne'),
    ('savings', 'savings_housing', 'Épargne logement'),
    ('savings', 'savings_employee', 'Épargne salariale'),
    ('savings', 'savings_retirement', 'Épargne retraite'),

    ('investment', 'investment_real_estate', 'Immobilier'),
    ('investment', 'investment_stocks', 'Bourse et actions'),
    ('investment', 'investment_crypto', 'Cryptomonnaies'),
    ('investment', 'investment_collectibles', 'Objets de collection'),
    ('investment', 'investment_life_insurance', 'Assurance vie'),
    ('investment', 'investment_precious_metals', 'Métaux précieux'),
    ('investment', 'investment_crowdfunding', 'Financement participatif'),

    ('gifts', 'gifts_presents', 'Cadeaux'),
    ('gifts', 'gifts_donations', 'Dons aux associations'),
    ('gifts', 'gifts_shared_pots', 'Cagnottes'),

    ('transfers', 'transfers_internal', 'Virements internes'),
    ('transfers', 'transfers_cash_withdrawal', 'Retraits d''espèces'),
    ('transfers', 'transfers_cash_deposit', 'Dépôts d''espèces'),
    ('transfers', 'transfers_loans_to_relatives', 'Prêts à des proches')
) AS sub_category (parent_code, code, label)
JOIN categories AS main_category ON main_category.code = sub_category.parent_code;



-- migrate:down

-- The sub-categories first: a main category cannot be deleted while it still has sub-categories
DELETE FROM categories WHERE parent_id IS NOT NULL;
DELETE FROM categories;
