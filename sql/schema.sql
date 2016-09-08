
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

CREATE FUNCTION create_comment(integer, text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
BEGIN 
  INSERT INTO issue_comments(issue_id, body) VALUES ($1, $2 );
  UPDATE issue SET  updated = now() WHERE issue.id = $1; 
END;
$_$;

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

CREATE TABLE accounts (
    password character(35) NOT NULL,
    type character varying(10),
    id integer NOT NULL
);

CREATE TABLE client (
    id integer NOT NULL,
    name character varying(32) NOT NULL
);

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

CREATE TABLE issue (
    id integer NOT NULL,
    issue text NOT NULL,
    client_id integer,
    date timestamp without time zone DEFAULT now() NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    updated timestamp without time zone
);

CREATE TABLE issue_comments (
    id integer NOT NULL,
    author character varying(50) DEFAULT 'incognito'::character varying,
    body text NOT NULL,
    date timestamp without time zone DEFAULT now() NOT NULL,
    issue_id integer NOT NULL
);

ALTER TABLE ONLY accounts ADD CONSTRAINT accounts_id_pk PRIMARY KEY (id);
ALTER TABLE ONLY client ADD CONSTRAINT client_pkey PRIMARY KEY (id);
ALTER TABLE ONLY client_summary ADD CONSTRAINT client_summary_pkey PRIMARY KEY (id);
ALTER TABLE ONLY issue_comments ADD CONSTRAINT issue_comments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY issue ADD CONSTRAINT table_name_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX accounts_id_uindex ON accounts USING btree (id);
CREATE UNIQUE INDEX client_id_uindex ON client USING btree (id);
CREATE UNIQUE INDEX client_name_uindex ON client USING btree (name);
CREATE UNIQUE INDEX client_summary_id_uindex ON client_summary USING btree (id);
CREATE INDEX client_summary_last_update_index ON client_summary USING btree (last_update);
CREATE UNIQUE INDEX issue_comments_id_uindex ON issue_comments USING btree (id);
CREATE UNIQUE INDEX table_name_id_uindex ON issue USING btree (id);

ALTER TABLE ONLY issue  ADD CONSTRAINT client_id FOREIGN KEY (client_id) REFERENCES client(id);
ALTER TABLE ONLY client_summary  ADD CONSTRAINT client_id FOREIGN KEY (client_id) REFERENCES client(id);
ALTER TABLE ONLY issue_comments ADD CONSTRAINT issue_id FOREIGN KEY (issue_id) REFERENCES issue(id);
