-- ============================================
-- Migration: 20261124234000_create_categories_table
-- Description: Table of the categories of the operations and the subscriptions.
--              The categories form a tree: a main category has no parent,
--              a sub-category points to its main category with parent_id.
--              Any category of the tree can be chosen, so a user who does not
--              want to go into detail can pick a main category.
--              The categories are shared by every user: they are reference
--              data, written by the migrations only.
-- Author: Floris Robart
-- ============================================



-- migrate:up

CREATE TABLE categories (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Stable identifier, used by the clients in their logic: unlike the label, it never changes
    code VARCHAR(100) NOT NULL,
    label VARCHAR(255) NOT NULL,

    -- NULL for a main category
    parent_id INTEGER DEFAULT NULL,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT categories_code_unique UNIQUE (code),

    -- Two main categories, or two sub-categories of the same main category, cannot share a label
    CONSTRAINT categories_label_unique_per_parent UNIQUE NULLS NOT DISTINCT (parent_id, label),

    -- Forbids deleting a main category that still has sub-categories
    CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES categories(id),
    CONSTRAINT check_category_not_its_own_parent CHECK (parent_id <> id)
);

CREATE TRIGGER update_categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();



-- migrate:down

-- Dropping the table also drops its trigger
DROP TABLE IF EXISTS categories;
