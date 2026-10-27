-- ============================================
-- Migration: 20261025120000_baseline
-- Description: Initial schema of the Econoris database
--              (tables, enum, updated_at function and triggers).
--              On an existing production database, this migration
--              must be marked as applied instead of being executed
--              (see README.md, "Switching an existing database").
-- Author: Floris Robart
-- ============================================



-- migrate:up

-- ------------------------------------------
-- Functions
-- ------------------------------------------

-- Function to update the updated_at field
-- This function will be called by a trigger before each update
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- ------------------------------------------
-- Table: subscriptions
-- ------------------------------------------

-- Create an enum type for subscription interval units
CREATE TYPE subscription_interval_unit AS ENUM ('days', 'weeks', 'months');

-- Create the subscriptions table to manage user subscriptions
CREATE TABLE subscriptions (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    label VARCHAR(255) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    category VARCHAR(255) NOT NULL,
    source VARCHAR(255),
    destination VARCHAR(255),
    costs NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    active BOOLEAN NOT NULL DEFAULT TRUE,

    interval_value INTEGER NOT NULL DEFAULT 1,
    interval_unit subscription_interval_unit NOT NULL DEFAULT 'months',
    start_date DATE NOT NULL,
    end_date DATE,
    day_of_month INTEGER DEFAULT 1,
    last_generated_at DATE DEFAULT NULL,

    user_id INTEGER NOT NULL,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,


    -- validations
    CONSTRAINT check_sub_interval_value_positive CHECK (interval_value > 0),
    CONSTRAINT check_sub_day_of_month_range CHECK (
        day_of_month IS NULL OR day_of_month = 0 OR (day_of_month BETWEEN 1 AND 31)
    ),

    -- day_of_month is required only when interval_unit = 'months'
    CONSTRAINT check_sub_day_required_for_months CHECK (
        (interval_unit = 'months' AND day_of_month IS NOT NULL)
        OR (interval_unit <> 'months')
    ),

    -- date constraints
    CONSTRAINT check_sub_dates_valid CHECK (end_date IS NULL OR end_date >= start_date)
);



-- ------------------------------------------
-- Table: operations
-- ------------------------------------------

-- Create the operations table to log financial operations for users
CREATE TABLE operations (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    levy_date DATE DEFAULT CURRENT_DATE,
    label VARCHAR(255) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    category VARCHAR(255) NOT NULL,

    source VARCHAR(255),
    destination VARCHAR(255),
    costs NUMERIC(12, 2) DEFAULT 0.0,
    is_validate BOOLEAN DEFAULT FALSE,

    user_id INTEGER NOT NULL,
    subscription_id INTEGER DEFAULT NULL,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL
);



-- ------------------------------------------
-- Table: work_hours
-- ------------------------------------------

-- Create the work_hours table to log work hours for users
CREATE TABLE work_hours (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    work_date DATE NOT NULL,

    start_time TIME,
    end_time TIME,
    hours_number NUMERIC(4, 2) GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (end_time - start_time)) / 3600
    ) STORED,

    hourly_rate NUMERIC(10, 2) NOT NULL,

    user_id INTEGER NOT NULL,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);



-- ------------------------------------------
-- Table: loans
-- ------------------------------------------

-- Create the loans table to manage user loans
CREATE TABLE loans (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    loan_date DATE DEFAULT CURRENT_DATE,
    amount NUMERIC(12, 2) NOT NULL,
    refunded_amount NUMERIC(12, 2) DEFAULT 0.0,

    borrower VARCHAR(255) NOT NULL,
    reason VARCHAR(255),

    user_id INTEGER NOT NULL,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);



-- ------------------------------------------
-- Triggers: keep updated_at up to date
-- ------------------------------------------

CREATE TRIGGER update_subscriptions_updated_at
BEFORE UPDATE ON subscriptions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_operations_updated_at
BEFORE UPDATE ON operations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_work_hours_updated_at
BEFORE UPDATE ON work_hours
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_loans_updated_at
BEFORE UPDATE ON loans
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();



-- migrate:down

-- Dropping a table also drops its triggers
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS work_hours;
DROP TABLE IF EXISTS operations;
DROP TABLE IF EXISTS subscriptions;

DROP TYPE IF EXISTS subscription_interval_unit;

DROP FUNCTION IF EXISTS update_updated_at();
