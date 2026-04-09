# Data Model

## Core domains

### Markets
- markets
- market_outcomes
- market_snapshots
- market_snapshot_outcomes

### Entities and linking
- entities
- market_entities
- source_document_entities
- market_source_links

### Evidence and research
- source_documents
- research_runs
- agent_runs
- extracted_claims
- claim_evidence

### Features and signals
- feature_runs
- feature_values
- signal_runs
- candidate_signals
- signal_decisions

### Simulation and evaluation
- paper_positions
- paper_position_events
- simulation_runs
- simulation_results
- evaluation_runs
- evaluation_metrics

### Operations and audit
- ingestion_runs
- automation_events
- audit_log

## Design rules
- Stable attributes go in columns
- Variable payloads go in JSONB
- Every important process gets a run table
- Every generated object should be traceable to its inputs
- Separate market state, evidence, features, signals, and simulations
