-- ============================================
-- Migration: 20261128150000_add_operations_user_id_levy_date_index
-- Description: Index of the operations by user and levy date.
--              The application loads the operations of a user by periods
--              of a few months (GET /operations?start_date=...&end_date=...)
--              and asks for the levy date of the oldest one
--              (GET /operations/oldest-date). Without this index, each of
--              these reads goes through the operations of every user.
-- Author: Floris Robart
-- ============================================



-- migrate:up

CREATE INDEX operations_user_id_levy_date_idx ON operations (user_id, levy_date);



-- migrate:down

DROP INDEX operations_user_id_levy_date_idx;
