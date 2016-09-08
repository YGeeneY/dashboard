--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: client_insert_safe(character varying); Type: FUNCTION; Schema: public; Owner: gofraud
--

CREATE FUNCTION client_insert_safe(_name character varying) RETURNS TABLE(client_id integer)
    LANGUAGE plpgsql
    AS $$
  DECLARE client_id INTEGER;
BEGIN
  SELECT id FROM client WHERE client.name = _name INTO client_id;
  IF NOT exists(SELECT id FROM client WHERE client.name = _name)
  THEN
  INSERT INTO client(name) VALUES (_name) RETURNING id INTO client_id;
END IF;
RETURN QUERY SELECT client_id;
END;
$$;


ALTER FUNCTION public.client_insert_safe(_name character varying) OWNER TO gofraud;

--
-- Name: client_insert_safe_array(text); Type: FUNCTION; Schema: public; Owner: gofraud
--

CREATE FUNCTION client_insert_safe_array(text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
  DECLARE
  clients VARCHAR [];
  client  VARCHAR;
BEGIN
  SELECT string_to_array($1, ',')
  INTO clients;
  FOREACH client IN ARRAY clients
  LOOP
    PERFORM client_insert_safe(client);
  END LOOP;
END;
$_$;


ALTER FUNCTION public.client_insert_safe_array(text) OWNER TO gofraud;

--
-- Name: create_comment(integer, text); Type: FUNCTION; Schema: public; Owner: gofraud
--

CREATE FUNCTION create_comment(integer, text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
BEGIN 
  INSERT INTO issue_comments(issue_id, body) VALUES ($1, $2 );
  UPDATE issue SET  updated = now() WHERE issue.id = $1; 
END;
$_$;


ALTER FUNCTION public.create_comment(integer, text) OWNER TO gofraud;

--
-- Name: create_task(character varying, text); Type: FUNCTION; Schema: public; Owner: gofraud
--

CREATE FUNCTION create_task(client character varying, task text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
 DECLARE ret_client_id INTEGER;
BEGIN
   SELECT * FROM client_insert_safe(client) INTO ret_client_id;
   INSERT INTO issue(client_id, issue) VALUES (ret_client_id, task);
   RETURN TRUE;
END;
$$;


ALTER FUNCTION public.create_task(client character varying, task text) OWNER TO gofraud;

--
-- Name: insert_summary(character varying, integer, integer, interval, double precision, double precision, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: gofraud
--

CREATE FUNCTION insert_summary(_client_name character varying, _calls_long_last integer, _calls_last integer, _duration_last interval, _acd_last double precision, _asr_last double precision, _last_update timestamp without time zone) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
  _client_id INT;
  last_updated TIMESTAMP;  
  BEGIN 
    SELECT client_id FROM client_insert_safe(_client_name) INTO _client_id;
    SELECT max(client_summary.last_update) FROM client_summary WHERE client_summary.client_id = _client_id INTO last_updated;
      IF  last_updated IS NULL OR _last_update > last_updated
      THEN
        INSERT INTO client_summary(client_id, calls_long_last, calls_last, duration_last, acd_last, asr_last, last_update)
        VALUES (_client_id, _calls_long_last, _calls_last, _duration_last, _acd_last, _asr_last, _last_update);
      END IF;
  END;
$$;


ALTER FUNCTION public.insert_summary(_client_name character varying, _calls_long_last integer, _calls_last integer, _duration_last interval, _acd_last double precision, _asr_last double precision, _last_update timestamp without time zone) OWNER TO gofraud;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE TABLE accounts (
    password character(35) NOT NULL,
    type character varying(10),
    id integer NOT NULL
);


ALTER TABLE public.accounts OWNER TO gofraud;

--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: gofraud
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_id_seq OWNER TO gofraud;

--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gofraud
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: client; Type: TABLE; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE TABLE client (
    id integer NOT NULL,
    name character varying(32) NOT NULL
);


ALTER TABLE public.client OWNER TO gofraud;

--
-- Name: client_id_seq; Type: SEQUENCE; Schema: public; Owner: gofraud
--

CREATE SEQUENCE client_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_id_seq OWNER TO gofraud;

--
-- Name: client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gofraud
--

ALTER SEQUENCE client_id_seq OWNED BY client.id;


--
-- Name: client_summary; Type: TABLE; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE TABLE client_summary (
    id integer NOT NULL,
    calls_long_last integer,
    calls_last integer,
    duration_last interval,
    acd_last double precision,
    asr_last double precision,
    last_update timestamp without time zone NOT NULL,
    client_id integer NOT NULL
);


ALTER TABLE public.client_summary OWNER TO gofraud;

--
-- Name: client_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: gofraud
--

CREATE SEQUENCE client_summary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_summary_id_seq OWNER TO gofraud;

--
-- Name: client_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gofraud
--

ALTER SEQUENCE client_summary_id_seq OWNED BY client_summary.id;


--
-- Name: issue; Type: TABLE; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE TABLE issue (
    id integer NOT NULL,
    issue text NOT NULL,
    client_id integer,
    date timestamp without time zone DEFAULT now() NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    updated timestamp without time zone
);


ALTER TABLE public.issue OWNER TO gofraud;

--
-- Name: issue_comments; Type: TABLE; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE TABLE issue_comments (
    id integer NOT NULL,
    author character varying(50) DEFAULT 'incognito'::character varying,
    body text NOT NULL,
    date timestamp without time zone DEFAULT now() NOT NULL,
    issue_id integer NOT NULL
);


ALTER TABLE public.issue_comments OWNER TO gofraud;

--
-- Name: issue_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: gofraud
--

CREATE SEQUENCE issue_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.issue_comments_id_seq OWNER TO gofraud;

--
-- Name: issue_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gofraud
--

ALTER SEQUENCE issue_comments_id_seq OWNED BY issue_comments.id;


--
-- Name: issue_id_seq; Type: SEQUENCE; Schema: public; Owner: gofraud
--

CREATE SEQUENCE issue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.issue_id_seq OWNER TO gofraud;

--
-- Name: issue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gofraud
--

ALTER SEQUENCE issue_id_seq OWNED BY issue.id;


--
-- Name: table_name_id_seq; Type: SEQUENCE; Schema: public; Owner: gofraud
--

CREATE SEQUENCE table_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.table_name_id_seq OWNER TO gofraud;

--
-- Name: table_name_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gofraud
--

ALTER SEQUENCE table_name_id_seq OWNED BY issue.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: gofraud
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: gofraud
--

ALTER TABLE ONLY client ALTER COLUMN id SET DEFAULT nextval('client_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: gofraud
--

ALTER TABLE ONLY client_summary ALTER COLUMN id SET DEFAULT nextval('client_summary_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: gofraud
--

ALTER TABLE ONLY issue ALTER COLUMN id SET DEFAULT nextval('issue_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: gofraud
--

ALTER TABLE ONLY issue_comments ALTER COLUMN id SET DEFAULT nextval('issue_comments_id_seq'::regclass);


--
-- Name: issue_comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gofraud
--

SELECT pg_catalog.setval('issue_comments_id_seq', 4, true);


--
-- Name: issue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gofraud
--

SELECT pg_catalog.setval('issue_id_seq', 39, true);


--
-- Name: table_name_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gofraud
--

SELECT pg_catalog.setval('table_name_id_seq', 1, false);


--
-- Name: accounts_id_pk; Type: CONSTRAINT; Schema: public; Owner: gofraud; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_id_pk PRIMARY KEY (id);


--
-- Name: client_pkey; Type: CONSTRAINT; Schema: public; Owner: gofraud; Tablespace: 
--

ALTER TABLE ONLY client
    ADD CONSTRAINT client_pkey PRIMARY KEY (id);


--
-- Name: client_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: gofraud; Tablespace: 
--

ALTER TABLE ONLY client_summary
    ADD CONSTRAINT client_summary_pkey PRIMARY KEY (id);


--
-- Name: issue_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: gofraud; Tablespace: 
--

ALTER TABLE ONLY issue_comments
    ADD CONSTRAINT issue_comments_pkey PRIMARY KEY (id);


--
-- Name: table_name_pkey; Type: CONSTRAINT; Schema: public; Owner: gofraud; Tablespace: 
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT table_name_pkey PRIMARY KEY (id);


--
-- Name: accounts_id_uindex; Type: INDEX; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE UNIQUE INDEX accounts_id_uindex ON accounts USING btree (id);


--
-- Name: client_id_uindex; Type: INDEX; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE UNIQUE INDEX client_id_uindex ON client USING btree (id);


--
-- Name: client_name_uindex; Type: INDEX; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE UNIQUE INDEX client_name_uindex ON client USING btree (name);


--
-- Name: client_summary_id_uindex; Type: INDEX; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE UNIQUE INDEX client_summary_id_uindex ON client_summary USING btree (id);


--
-- Name: client_summary_last_update_index; Type: INDEX; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE INDEX client_summary_last_update_index ON client_summary USING btree (last_update);


--
-- Name: issue_comments_id_uindex; Type: INDEX; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE UNIQUE INDEX issue_comments_id_uindex ON issue_comments USING btree (id);


--
-- Name: table_name_id_uindex; Type: INDEX; Schema: public; Owner: gofraud; Tablespace: 
--

CREATE UNIQUE INDEX table_name_id_uindex ON issue USING btree (id);


--
-- Name: client_id; Type: FK CONSTRAINT; Schema: public; Owner: gofraud
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT client_id FOREIGN KEY (client_id) REFERENCES client(id);


--
-- Name: client_id; Type: FK CONSTRAINT; Schema: public; Owner: gofraud
--

ALTER TABLE ONLY client_summary
    ADD CONSTRAINT client_id FOREIGN KEY (client_id) REFERENCES client(id);


--
-- Name: issue_id; Type: FK CONSTRAINT; Schema: public; Owner: gofraud
--

ALTER TABLE ONLY issue_comments
    ADD CONSTRAINT issue_id FOREIGN KEY (issue_id) REFERENCES issue(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--
