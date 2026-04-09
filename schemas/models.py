from datetime import datetime
from typing import Any, Optional
from pydantic import BaseModel, HttpUrl


class MarketCreate(BaseModel):
    external_market_id: str
    platform: str
    title: str
    slug: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None
    market_type: Optional[str] = None
    status: str = "unknown"
    resolution_source: Optional[str] = None
    resolution_criteria: Optional[str] = None
    currency_code: Optional[str] = None
    event_start_at: Optional[datetime] = None
    event_end_at: Optional[datetime] = None
    resolution_at: Optional[datetime] = None
    outcome_type: Optional[str] = None
    market_url: Optional[str] = None
    metadata_json: Optional[Any] = None


class MarketOutcomeCreate(BaseModel):
    market_id: int
    outcome_code: str
    outcome_label: str
    sort_order: Optional[int] = None
    is_primary: bool = False


class MarketSnapshotCreate(BaseModel):
    market_id: int
    snapshot_at: datetime
    last_price: Optional[float] = None
    mid_price: Optional[float] = None
    yes_price: Optional[float] = None
    no_price: Optional[float] = None
    implied_probability: Optional[float] = None
    volume: Optional[float] = None
    liquidity: Optional[float] = None
    spread: Optional[float] = None
    best_bid: Optional[float] = None
    best_ask: Optional[float] = None
    orderbook_depth: Optional[float] = None
    orderbook_json: Optional[Any] = None
    raw_payload_path: Optional[str] = None


class EntityCreate(BaseModel):
    entity_type: str
    canonical_name: str
    normalized_name: Optional[str] = None
    external_ids_json: Optional[Any] = None
    metadata_json: Optional[Any] = None


class SourceDocumentCreate(BaseModel):
    source_type: str
    source_name: Optional[str] = None
    source_url: Optional[str] = None
    canonical_url: Optional[str] = None
    title: Optional[str] = None
    subtitle: Optional[str] = None
    author_name: Optional[str] = None
    publisher_name: Optional[str] = None
    published_at: Optional[datetime] = None
    language_code: Optional[str] = None
    content_text: Optional[str] = None
    content_hash: Optional[str] = None
    source_topic: Optional[str] = None
    reliability_score: Optional[float] = None
    raw_payload_path: Optional[str] = None
    metadata_json: Optional[Any] = None


class ResearchRunCreate(BaseModel):
    run_type: str
    topic_key: Optional[str] = None
    market_id: Optional[int] = None
    trigger_type: Optional[str] = None
    status: str
    input_parameters_json: Optional[Any] = None
    notes: Optional[str] = None


class AgentRunCreate(BaseModel):
    research_run_id: Optional[int] = None
    market_id: Optional[int] = None
    agent_name: str
    agent_version: Optional[str] = None
    model_provider: Optional[str] = None
    model_name: Optional[str] = None
    prompt_template_name: Optional[str] = None
    prompt_version: Optional[str] = None
    input_payload: Optional[Any] = None
    output_payload: Optional[Any] = None
    token_usage_input: Optional[int] = None
    token_usage_output: Optional[int] = None
    status: str


class ExtractedClaimCreate(BaseModel):
    research_run_id: Optional[int] = None
    agent_run_id: Optional[int] = None
    source_document_id: Optional[int] = None
    market_id: Optional[int] = None
    entity_id: Optional[int] = None
    claim_type: str
    claim_text: str
    claim_label: Optional[str] = None
    polarity: Optional[str] = None
    structured_value: Optional[Any] = None
    confidence_score: Optional[float] = None
    uncertainty_note: Optional[str] = None
    evidence_span: Optional[str] = None
    event_time: Optional[datetime] = None


class FeatureRunCreate(BaseModel):
    market_id: Optional[int] = None
    snapshot_at: Optional[datetime] = None
    feature_set_name: str
    feature_set_version: str
    status: str
    notes: Optional[str] = None


class FeatureValueCreate(BaseModel):
    feature_run_id: int
    feature_name: str
    feature_group: Optional[str] = None
    numeric_value: Optional[float] = None
    text_value: Optional[str] = None
    boolean_value: Optional[bool] = None
    json_value: Optional[Any] = None


class SignalRunCreate(BaseModel):
    market_id: Optional[int] = None
    feature_run_id: Optional[int] = None
    rule_engine_name: str
    rule_engine_version: str
    status: str
    notes: Optional[str] = None


class CandidateSignalCreate(BaseModel):
    signal_run_id: Optional[int] = None
    market_id: int
    signal_type: str
    signal_subtype: Optional[str] = None
    signal_status: str
    score: Optional[float] = None
    confidence_score: Optional[float] = None
    rationale_text: Optional[str] = None
    evidence_summary: Optional[str] = None
    rule_version: Optional[str] = None
    source_claim_ids: Optional[Any] = None
    feature_snapshot: Optional[Any] = None


class PaperPositionCreate(BaseModel):
    candidate_signal_id: Optional[int] = None
    market_id: int
    position_side: Optional[str] = None
    position_label: Optional[str] = None
    entry_time: datetime
    entry_price: Optional[float] = None
    size_units: Optional[float] = None
    notional_amount: Optional[float] = None
    status: str


class SimulationRunCreate(BaseModel):
    run_name: str
    run_type: str
    strategy_name: Optional[str] = None
    strategy_version: Optional[str] = None
    market_scope_json: Optional[Any] = None
    assumptions_json: Optional[Any] = None
    status: str
    notes: Optional[str] = None


class EvaluationRunCreate(BaseModel):
    run_name: str
    evaluation_type: str
    dataset_scope_json: Optional[Any] = None
    metric_set_name: Optional[str] = None
    status: str
    notes: Optional[str] = None
