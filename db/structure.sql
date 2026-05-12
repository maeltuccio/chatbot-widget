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
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id bigint NOT NULL,
    name character varying,
    plan character varying,
    owner_email character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    name character varying,
    public_token character varying,
    system_prompt text,
    welcome_message text,
    tone character varying,
    primary_goal character varying,
    active boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    widget_title character varying,
    widget_primary_color character varying,
    widget_position character varying,
    widget_send_label character varying,
    widget_placeholder character varying,
    allowed_origins text
);


--
-- Name: agents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agents_id_seq OWNED BY public.agents.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id bigint NOT NULL,
    agent_id bigint NOT NULL,
    public_token character varying NOT NULL,
    visitor_identifier character varying,
    last_message_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    summary text,
    summarized_until_message_id bigint
);


--
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- Name: knowledge_chunks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_chunks (
    id bigint NOT NULL,
    agent_id bigint NOT NULL,
    knowledge_source_id bigint NOT NULL,
    content text NOT NULL,
    "position" integer NOT NULL,
    embedding_model character varying DEFAULT 'text-embedding-3-small'::character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    embedding public.vector(1536)
);


--
-- Name: knowledge_chunks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_chunks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_chunks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_chunks_id_seq OWNED BY public.knowledge_chunks.id;


--
-- Name: knowledge_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_sources (
    id bigint NOT NULL,
    agent_id bigint NOT NULL,
    source_type character varying DEFAULT 'manual'::character varying NOT NULL,
    title character varying NOT NULL,
    url character varying,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    raw_content text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: knowledge_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.knowledge_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knowledge_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.knowledge_sources_id_seq OWNED BY public.knowledge_sources.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    role character varying NOT NULL,
    content text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: webflow_connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webflow_connections (
    id bigint NOT NULL,
    agent_id bigint NOT NULL,
    access_token_ciphertext text NOT NULL,
    scope character varying,
    status character varying DEFAULT 'connected'::character varying NOT NULL,
    site_id character varying,
    site_name character varying,
    collection_id character varying,
    collection_name character varying,
    last_synced_at timestamp(6) without time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: webflow_connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.webflow_connections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webflow_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.webflow_connections_id_seq OWNED BY public.webflow_connections.id;


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: agents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents ALTER COLUMN id SET DEFAULT nextval('public.agents_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- Name: knowledge_chunks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_chunks ALTER COLUMN id SET DEFAULT nextval('public.knowledge_chunksublic.knowledge_sources ALTER COLUMN id SET DEFAULT nextval('public.knowledge_sources_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: webflow_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webflow_connections ALTER COLUMN id SET DEFAULT nextval('public.webflow_connections_id_seq'::regclass);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: knowledge_chunks knowledge_chunks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_chunks
    ADD CONSTRAINT knowledge_chunks_pkey PRIMARY KEY (id);


--
-- Name: knowledge_sources knowledge_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_sources
    ADD CONSTRAINT knowledge_sources_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: webflow_connections webflow_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webflow_connections
    ADD CONSTRAINT webflow_connections_pkey PRIMARY KEY (id);


--
-- Name: index_agents_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agents_on_account_id ON public.agents USING btree (account_id);


--
-- Name: index_conversations_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_agent_id ON public.conversations USING btree (agent_id);


--
-- Name: index_conversations_on_agent_id_and_last_message_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_agent_id_and_last_message_at ON public.conversations USING btree (agent_id, last_message_at);


--
-- Name: index_conversations_on_public_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversations_on_public_token ON public.conversations USING btree (public_token);


--
-- Name: index_conversations_on_summarized_until_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_summarized_until_message_id ON public.conversations USING btree (summarized_until_message_id);


--
-- Name: index_knowledge_chunks_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_knowledge_chunks_on_agent_id ON public.knowledge_chunks USING btree (agent_id);


--
-- Name: index_knowledge_chunks_on_agent_id_and_knowledge_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_knowledge_chunks_on_agent_id_and_knowledge_source_id ON public.knowledge_chunks USING btree (agent_id, knowledge_source_id);


--
-- Name: index_knowledge_chunks_on_embedding; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_knowledge_chunks_on_embedding ON public.knowledge_chunks USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: index_knowledge_chunks_on_knowledge_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_knowledge_chunks_on_knowledge_source_id ON public.knowledge_chunks USING btree (knowledge_source_id);


--
-- Name: index_knowledge_chunks_on_knowledge_source_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_knowledge_chunks_on_knowledge_source_id_and_position ON public.knowledge_chunks USING btree (knowledge_source_id, "position");


--
-- Name: index_knowledge_sources_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_knowledge_sources_on_agent_id ON public.knowledge_sources USING btree (agent_id);


--
-- Name: index_knowledge_sources_on_agent_id_and_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_knowledge_sources_on_agent_id_and_source_type ON public.knowledge_sources USING btree (agent_id, source_type);


--
-- Name: index_knowledge_sources_on_agent_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_knowledge_sources_on_agent_id_and_status ON public.knowledge_sources USING btree (agent_id, status);


--
-- Name: index_messages_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: index_messages_on_conversation_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_conversation_id_and_created_at ON public.messages USING btree (conversation_id, created_at);


--
-- Name: index_webflow_connections_on_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_webflow_connections_on_agent_id ON public.webflow_connections USING btree (agent_id);


--
-- Name: index_webflow_connections_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webflow_connections_on_status ON public.webflow_connections USING btree (status);


--
-- Name: knowledge_chunks fk_rails_1a7d6d9fe8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_chunks
    ADD CONSTRAINT fk_rails_1a7d6d9fe8 FOREIGN KEY (knowledge_source_id) REFERENCES public.knowledge_sources(id);


--
-- Name: knowledge_chunks fk_rails_71c5ee3335; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_chunks
    ADD CONSTRAINT fk_rails_71c5ee3335 FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: messages fk_rails_7f927086d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_7f927086d2 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: conversations fk_rails_b7ef72e2ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_rails_b7ef72e2ea FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: webflow_connections fk_rails_ecba4a60eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webflow_connections
    ADD CONSTRAINT fk_rails_ecba4a60eb FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: agents fk_rails_f6a7a5a81e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT fk_rails_f6a7a5a81e FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: knowledge_sources fk_rails_fbd81959b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_sources
    ADD CONSTRAINT fk_rails_fbd81959b8 FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260512123000'),
('20260512120000'),
('20260511154500'),
('20260511143000'),
('20260510130116'),
('20260510130115'),
('20260510125205'),
('20260510122728'),
('20260510122412'),
('20260510115621'),
('20260510115620'),
('20260510103020'),
('20260510103007');

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260512123000'),
('20260512120000'),
('20260511154500'),
('20260511143000'),
('20260510130116'),
('20260510130115'),
('20260510125205'),
('20260510122728'),
('20260510122412'),
('20260510115621'),
('20260510115620'),
('20260510103020'),
('20260510103007');

