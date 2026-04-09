BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS markets (
    id BIGSERIAL PRIMARY KEY,
    external_market_id TEXT NOT NULL,
    platform TEXT NOT NULL,
    title TEXT NOT NULL,
    slug TEXT,
    description TEXT,
    category TEXT,
    subcategory TEXT,
    market_type TEXT,
    status TEXT NOT NULL DEFAULT 'unknown',
    resolution_source TEXT,
    resolution_criteria TEXT,
    currency_code TEXT,
    event_start_at TIMESTAMPTZ,
    event_end_at TIMESTAMPTZ,
    resolution_at TIMESTAMPTZ,
    outcome_type TEXT,
    market_url TEXT,
    metadata_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (platform, external_market_id)
);

CREATE INDEX IF NOT EXISTS idx_markets_platform_status
ON markets (platform, status);

CREATE INDEX IF NOT EXISTS idx_markets_category
ON markets (category, subcategory);

CREATE TABLE IF NOT EXISTS market_outcomes (
    id BIGSERIAL PRIMARY KEY,
    market_id BIGINT NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    outcome_code TEXT NOT NULL,
    outcome_label TEXT NOT NULL,
    sort_order INT,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (market_id, outcome_code)
);

CREATE TABLE IF NOT EXISTS market_snapshots (
    id BIGSERIAL PRIMARY KEY,
    market_id BIGINT NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    snapshot_at TIMESTAMPTZ NOT NULL,
    last_price NUMERIC(18,8),
    mid_price NUMERIC(18,8),
    yes_price NUMERIC(18,8),
    no_price NUMERIC(18,8),
    implied_probability NUMERIC(18,8),
    volume NUMERIC(24,8),
    liquidity NUMERIC(24,8),
    spread NUMERIC(18,8),
    best_bid NUMERIC(18,8),
    best_ask NUMERIC(18,8),
    orderbook_depth NUMERIC(24,8),
    orderbook_json JSONB,
    raw_payload_path TEXT,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_market_snapshots_market_time
ON market_snapshots (market_id, snapshot_at DESC);

CREATE TABLE IF NOT EXISTS market_snapshot_outcomes (
    id BIGSERIAL PRIMARY KEY,
    market_snapshot_id BIGINT NOT NULL REFERENCES market_snapshots(id) ON DELETE CASCADE,
    market_outcome_id BIGINT NOT NULL REFERENCES market_outcomes(id) ON DELETE CASCADE,
    price NUMERIC(18,8),
    implied_probability NUMERIC(18,8),
    best_bid NUMERIC(18,8),
    best_ask NUMERIC(18,8),
    volume NUMERIC(24,8),
    liquidity NUMERIC(24,8),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (market_snapshot_id, market_outcome_id)
);

CREATE TABLE IF NOT EXISTS entities (
    id BIGSERIAL PRIMARY KEY,
    entity_type TEXT NOT NULL,
    canonical_name TEXT NOT NULL,
    normalized_name TEXT,
    external_ids_json JSONB,
    metadata_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (entity_type, canonical_name)
);

CREATE INDEX IF NOT EXISTS idx_entities_type_name
ON entities (entity_type, canonical_name);

CREATE TABLE IF NOT EXISTS market_entities (
    id BIGSERIAL PRIMARY KEY,
    market_id BIGINT NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    entity_id BIGINT NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    role_type TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (market_id, entity_id, role_type)
);

CREATE TABLE IF NOT EXISTS source_documents (
    id BIGSERIAL PRIMARY KEY,
    source_type TEXT NOT NULL,
    source_name TEXT,
    source_url TEXT,
    canonical_url TEXT,
    title TEXT,
    subtitle TEXT,
    author_name TEXT,
    publisher_name TEXT,
    published_at TIMESTAMPTZ,
    fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    language_code TEXT,
    content_text TEXT,
    content_hash TEXT,
    source_topic TEXT,
    reliability_score NUMERIC(8,4),
    raw_payload_path TEXT,
    metadata_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_source_documents_published
ON source_documents (published_at DESC);

CREATE INDEX IF NOT EXISTS idx_source_documents_hash
ON source_documents (content_hash);

CREATE TABLE IF NOT EXISTS source_document_entities (
    id BIGSERIAL PRIMARY KEY,
    source_document_id BIGINT NOT NULL REFERENCES source_documents(id) ON DELETE CASCADE,
    entity_id BIGINT NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    mention_count INT,
    sentiment_label TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (source_document_id, entity_id)
);

CREATE TABLE IF NOT EXISTS market_source_links (
    id BIGSERIAL PRIMARY KEY,
    market_id BIGINT NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    source_document_id BIGINT NOT NULL REFERENCES source_documents(id) ON DELETE CASCADE,
    link_method TEXT NOT NULL,
    relevance_score NUMERIC(8,4),
    justification TEXT,
    linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (market_id, source_document_id)
);

CREATE INDEX IF NOT EXISTS idx_market_source_links_market
ON market_source_links (market_id, linked_at DESC);

CREATE TABLE IF NOT EXISTS research_runs (
    id BIGSERIAL PRIMARY KEY,
    run_type TEXT NOT NULL,
    topic_key TEXT,
    market_id BIGINT REFERENCES markets(id) ON DELETE SET NULL,
    trigger_type TEXT,
    status TEXT NOT NULL,
    input_parameters_json JSONB,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    failure_reason TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agent_runs (
    id BIGSERIAL PRIMARY KEY,
    research_run_id BIGINT REFERENCES research_runs(id) ON DELETE SET NULL,
    market_id BIGINT REFERENCES markets(id) ON DELETE SET NULL,
    agent_name TEXT NOT NULL,
    agent_version TEXT,
    model_provider TEXT,
    model_name TEXT,
    prompt_template_name TEXT,
    prompt_version TEXT,
    input_payload JSONB,
    output_payload JSONB,
    token_usage_input INT,
    token_usage_output INT,
    status TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_runs_market
ON agent_runs (market_id, started_at DESC);

CREATE TABLE IF NOT EXISTS extracted_claims (
    id BIGSERIAL PRIMARY KEY,
    research_run_id BIGINT REFERENCES research_runs(id) ON DELETE SET NULL,
    agent_run_id BIGINT REFERENCES agent_runs(id) ON DELETE SET NULL,
    source_document_id BIGINT REFERENCES source_documents(id) ON DELETE SET NULL,
    market_id BIGINT REFERENCES markets(id) ON DELETE SET NULL,
    entity_id BIGINT REFERENCES entities(id) ON DELETE SET NULL,
    claim_type TEXT NOT NULL,
    claim_text TEXT NOT NULL,
    claim_label TEXT,
    polarity TEXT,
    structured_value JSONB,
    confidence_score NUMERIC(8,4),
    uncertainty_note TEXT,
    evidence_span TEXT,
    event_time TIMESTAMPTZ,
    extracted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_extracted_claims_market
ON extracted_claims (market_id, extracted_at DESC);

CREATE INDEX IF NOT EXISTS idx_extracted_claims_source
ON extracted_claims (source_document_id);

CREATE TABLE IF NOT EXISTS claim_evidence (
    id BIGSERIAL PRIMARY KEY,
    extracted_claim_id BIGINT NOT NULL REFERENCES extracted_claims(id) ON DELETE CASCADE,
    source_document_id BIGINT NOT NULL REFERENCES source_documents(id) ON DELETE CASCADE,
    evidence_type TEXT,
    evidence_text TEXT,
    evidence_url TEXT,
    relevance_score NUMERIC(8,4),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feature_runs (
    id BIGSERIAL PRIMARY KEY,
    market_id BIGINT REFERENCES markets(id) ON DELETE SET NULL,
    snapshot_at TIMESTAMPTZ,
    feature_set_name TEXT NOT NULL,
    feature_set_version TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS feature_values (
    id BIGSERIAL PRIMARY KEY,
    feature_run_id BIGINT NOT NULL REFERENCES feature_runs(id) ON DELETE CASCADE,
    feature_name TEXT NOT NULL,
    feature_group TEXT,
    numeric_value NUMERIC(24,10),
    text_value TEXT,
    boolean_value BOOLEAN,
    json_value JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (feature_run_id, feature_name)
);

CREATE INDEX IF NOT EXISTS idx_feature_values_feature_run
ON feature_values (feature_run_id);

CREATE TABLE IF NOT EXISTS signal_runs (
    id BIGSERIAL PRIMARY KEY,
    market_id BIGINT REFERENCES markets(id) ON DELETE SET NULL,
    feature_run_id BIGINT REFERENCES feature_runs(id) ON DELETE SET NULL,
    rule_engine_name TEXT NOT NULL,
    rule_engine_version TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS candidate_signals (
    id BIGSERIAL PRIMARY KEY,
    signal_run_id BIGINT REFERENCES signal_runs(id) ON DELETE SET NULL,
    market_id BIGINT NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    signal_type TEXT NOT NULL,
    signal_subtype TEXT,
    signal_status TEXT NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    score NUMERIC(8,4),
    confidence_score NUMERIC(8,4),
    rationale_text TEXT,
    evidence_summary TEXT,
    rule_version TEXT,
    source_claim_ids JSONB,
    feature_snapshot JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_candidate_signals_market_time
ON candidate_signals (market_id, generated_at DESC);

CREATE TABLE IF NOT EXISTS signal_decisions (
    id BIGSERIAL PRIMARY KEY,
    candidate_signal_id BIGINT NOT NULL REFERENCES candidate_signals(id) ON DELETE CASCADE,
    decision_type TEXT NOT NULL,
    decision_status TEXT NOT NULL,
    reviewer_type TEXT NOT NULL,
    reviewer_name TEXT,
    decision_reason TEXT,
    decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS paper_positions (
    id BIGSERIAL PRIMARY KEY,
    candidate_signal_id BIGINT REFERENCES candidate_signals(id) ON DELETE SET NULL,
    market_id BIGINT NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    position_side TEXT,
    position_label TEXT,
    entry_time TIMESTAMPTZ NOT NULL,
    entry_price NUMERIC(18,8),
    size_units NUMERIC(24,8),
    notional_amount NUMERIC(24,8),
    status TEXT NOT NULL,
    exit_time TIMESTAMPTZ,
    exit_price NUMERIC(18,8),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_paper_positions_market
ON paper_positions (market_id, entry_time DESC);

CREATE TABLE IF NOT EXISTS paper_position_events (
    id BIGSERIAL PRIMARY KEY,
    paper_position_id BIGINT NOT NULL REFERENCES paper_positions(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    event_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    price NUMERIC(18,8),
    quantity NUMERIC(24,8),
    event_payload JSONB
);

CREATE TABLE IF NOT EXISTS simulation_runs (
    id BIGSERIAL PRIMARY KEY,
    run_name TEXT NOT NULL,
    run_type TEXT NOT NULL,
    strategy_name TEXT,
    strategy_version TEXT,
    market_scope_json JSONB,
    assumptions_json JSONB,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    status TEXT NOT NULL,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS simulation_results (
    id BIGSERIAL PRIMARY KEY,
    simulation_run_id BIGINT REFERENCES simulation_runs(id) ON DELETE CASCADE,
    paper_position_id BIGINT REFERENCES paper_positions(id) ON DELETE CASCADE,
    pnl_absolute NUMERIC(24,8),
    pnl_percent NUMERIC(18,8),
    fees_estimated NUMERIC(24,8),
    slippage_estimated NUMERIC(24,8),
    max_drawdown NUMERIC(18,8),
    assumptions_json JSONB,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS evaluation_runs (
    id BIGSERIAL PRIMARY KEY,
    run_name TEXT NOT NULL,
    evaluation_type TEXT NOT NULL,
    dataset_scope_json JSONB,
    metric_set_name TEXT,
    status TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS evaluation_metrics (
    id BIGSERIAL PRIMARY KEY,
    evaluation_run_id BIGINT NOT NULL REFERENCES evaluation_runs(id) ON DELETE CASCADE,
    metric_name TEXT NOT NULL,
    metric_group TEXT,
    metric_value NUMERIC(24,10),
    metric_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (evaluation_run_id, metric_name)
);

CREATE TABLE IF NOT EXISTS ingestion_runs (
    id BIGSERIAL PRIMARY KEY,
    source_name TEXT NOT NULL,
    source_type TEXT NOT NULL,
    run_type TEXT NOT NULL,
    status TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    records_seen INT,
    records_inserted INT,
    records_updated INT,
    error_message TEXT
);

CREATE TABLE IF NOT EXISTS automation_events (
    id BIGSERIAL PRIMARY KEY,
    event_type TEXT NOT NULL,
    component_name TEXT NOT NULL,
    related_record_type TEXT,
    related_record_id BIGINT,
    event_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    actor_type TEXT NOT NULL,
    actor_name TEXT,
    action_type TEXT NOT NULL,
    target_table TEXT,
    target_id BIGINT,
    action_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMIT;
