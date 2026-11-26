-- ============================================
-- Migration: 20261125100000_link_operations_and_subscriptions_to_categories
-- Description: Links every operation and every subscription to a category of
--              the categories table, with a new category_id column.
--              The category_id of the existing rows comes from their old
--              category label, through the legacy_category_labels table.
--              A label without equivalent goes to the "other" category.
--
--              First step of a change in two steps (see README.md):
--              - the old "category" column is kept, untouched: the clients
--                not yet updated still read and send it;
--              - legacy_category_labels is kept too: the API uses it to find
--                the category of an old label sent by these clients.
--              A later migration drops both, once every client sends category_id.
-- Author: Floris Robart
-- ============================================



-- migrate:up

-- ------------------------------------------
-- Table: legacy_category_labels
-- ------------------------------------------

-- Equivalence between the labels of the old categories, once free text, and the new categories
CREATE TABLE legacy_category_labels (
    label VARCHAR(255) PRIMARY KEY,
    category_id INTEGER NOT NULL,

    CONSTRAINT legacy_category_labels_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Every label offered by the application, past versions included. An old label without
-- sub-category of its own goes to the main category that covers it.
INSERT INTO legacy_category_labels (label, category_id)
SELECT legacy_label.label, category.id
FROM (VALUES
    ('Salaire', 'income_salary'),
    ('Primes et bonus', 'income_bonus'),
    ('Aides et subventions', 'income_benefits'),
    ('Bourses', 'income_benefits'),
    ('Indemnités', 'income_allowances'),
    ('Remboursements', 'income_refunds'),
    ('Dividendes', 'income_investment'),

    ('Logement', 'housing'),
    ('Loyer', 'housing_rent'),
    ('Prêt immobilier', 'housing_mortgage'),
    ('Eau, Electricité, Gaz', 'housing'),
    ('Travaux', 'housing_works'),
    ('Meubles', 'housing_furniture'),
    ('Electroménager', 'housing_appliances'),

    ('Alimentation', 'food'),
    ('Courses', 'food_groceries'),
    ('Restaurants', 'food_restaurants'),

    ('Transport', 'transport'),
    ('Transports en commun', 'transport_public'),
    ('Voiture', 'transport'),
    ('Moto', 'transport'),
    ('Carburant', 'transport_fuel'),
    ('Parking', 'transport_parking'),
    ('Péage', 'transport_tolls'),
    ('Entretien véhicule', 'transport_maintenance'),

    ('Santé', 'health'),
    ('Sante', 'health'),

    ('Vêtements', 'shopping_clothes'),
    ('Montres', 'shopping_jewelry_watches'),
    ('Bijoux', 'shopping_jewelry_watches'),

    ('Internet, téléphone', 'high_tech'),
    ('Ordinateur', 'high_tech_computers'),
    ('Téléphone', 'high_tech_phones'),
    ('Accessoires high-tech', 'high_tech_accessories'),

    ('Loisirs', 'leisure'),
    ('Sports', 'leisure_sport'),
    ('Cinémas et culture', 'leisure_cinema'),
    ('Bars', 'leisure_bars'),
    ('Multimédia', 'leisure_streaming'),

    ('Vacances', 'travel'),

    ('Enfants', 'family'),

    ('Animaux', 'pets'),

    ('Prêts étudiants', 'education_student_loan'),
    ('Formations', 'education_training'),
    ('Matériel scolaire', 'education_supplies'),

    ('Dépenses professionnelles', 'work_expenses'),

    ('Esthétique', 'beauty_aesthetics'),

    ('Frais bancaires', 'bank_fees'),
    ('Prêts et crédits', 'bank_loans'),

    ('Impôts', 'taxes'),
    ('Taxes', 'taxes'),
    ('Amendes', 'taxes_fines'),

    ('Epargne', 'savings'),

    ('Investissements', 'investment'),
    ('Bourse et actions', 'investment_stocks'),
    ('Cryptomonnaies', 'investment_crypto'),

    ('Cadeaux', 'gifts_presents'),

    ('Abonnements', 'other'),
    ('Autre', 'other'),
    ('Autres', 'other')
) AS legacy_label (label, category_code)
JOIN categories AS category ON category.code = legacy_label.category_code;



-- ------------------------------------------
-- Column: operations.category_id
-- ------------------------------------------

ALTER TABLE operations ADD COLUMN category_id INTEGER;

UPDATE operations SET category_id = COALESCE(
    (SELECT legacy_label.category_id FROM legacy_category_labels AS legacy_label WHERE legacy_label.label = operations.category),
    (SELECT category.id FROM categories AS category WHERE category.code = 'other')
);

ALTER TABLE operations
    ALTER COLUMN category_id SET NOT NULL,
    ADD CONSTRAINT operations_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);



-- ------------------------------------------
-- Column: subscriptions.category_id
-- ------------------------------------------

ALTER TABLE subscriptions ADD COLUMN category_id INTEGER;

UPDATE subscriptions SET category_id = COALESCE(
    (SELECT legacy_label.category_id FROM legacy_category_labels AS legacy_label WHERE legacy_label.label = subscriptions.category),
    (SELECT category.id FROM categories AS category WHERE category.code = 'other')
);

ALTER TABLE subscriptions
    ALTER COLUMN category_id SET NOT NULL,
    ADD CONSTRAINT subscriptions_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);



-- migrate:down

-- The old "category" column was never changed: nothing is lost
ALTER TABLE subscriptions DROP COLUMN category_id;
ALTER TABLE operations DROP COLUMN category_id;

DROP TABLE IF EXISTS legacy_category_labels;
