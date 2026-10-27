\restrict dbmate

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: subscription_interval_unit; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_interval_unit AS ENUM (
    'days',
    'weeks',
    'months'
);


--
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: loans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loans (
    id integer NOT NULL,
    loan_date date DEFAULT CURRENT_DATE,
    amount numeric(12,2) NOT NULL,
    refunded_amount numeric(12,2) DEFAULT 0.0,
    borrower character varying(255) NOT NULL,
    reason character varying(255),
    user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: loans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.loans ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.loans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operations (
    id integer NOT NULL,
    levy_date date DEFAULT CURRENT_DATE,
    label character varying(255) NOT NULL,
    amount numeric(12,2) NOT NULL,
    category character varying(255) NOT NULL,
    source character varying(255),
    destination character varying(255),
    costs numeric(12,2) DEFAULT 0.0,
    is_validate boolean DEFAULT false,
    user_id integer NOT NULL,
    subscription_id integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: operations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.operations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.operations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id integer NOT NULL,
    label character varying(255) NOT NULL,
    amount numeric(12,2) NOT NULL,
    category character varying(255) NOT NULL,
    source character varying(255),
    destination character varying(255),
    costs numeric(12,2) DEFAULT 0.0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    interval_value integer DEFAULT 1 NOT NULL,
    interval_unit public.subscription_interval_unit DEFAULT 'months'::public.subscription_interval_unit NOT NULL,
    start_date date NOT NULL,
    end_date date,
    day_of_month integer DEFAULT 1,
    last_generated_at date,
    user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_sub_dates_valid CHECK (((end_date IS NULL) OR (end_date >= start_date))),
    CONSTRAINT check_sub_day_of_month_range CHECK (((day_of_month IS NULL) OR (day_of_month = 0) OR ((day_of_month >= 1) AND (day_of_month <= 31)))),
    CONSTRAINT check_sub_day_required_for_months CHECK ((((interval_unit = 'months'::public.subscription_interval_unit) AND (day_of_month IS NOT NULL)) OR (interval_unit <> 'months'::public.subscription_interval_unit))),
    CONSTRAINT check_sub_interval_value_positive CHECK ((interval_value > 0))
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: work_hours; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_hours (
    id integer NOT NULL,
    work_date date NOT NULL,
    start_time time without time zone,
    end_time time without time zone,
    hours_number numeric(4,2) GENERATED ALWAYS AS ((EXTRACT(epoch FROM (end_time - start_time)) / (3600)::numeric)) STORED,
    hourly_rate numeric(10,2) NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: work_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.work_hours ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.work_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: loans loans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (id);


--
-- Name: operations operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations
    ADD CONSTRAINT operations_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: work_hours work_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_hours
    ADD CONSTRAINT work_hours_pkey PRIMARY KEY (id);


--
-- Name: loans update_loans_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON public.loans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: operations update_operations_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_operations_updated_at BEFORE UPDATE ON public.operations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: subscriptions update_subscriptions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: work_hours update_work_hours_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_work_hours_updated_at BEFORE UPDATE ON public.work_hours FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: operations subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations
    ADD CONSTRAINT subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict dbmate


--
-- Dbmate schema migrations
--

INSERT INTO public.schema_migrations (version) VALUES
    ('20261025120000');
