INSERT INTO markets (
    external_market_id,
    platform,
    title,
    category,
    subcategory,
    status,
    outcome_type,
    market_url
) VALUES (
    'sample-market-001',
    'polymarket',
    'Will sample event happen?',
    'sports',
    'game-outcome',
    'open',
    'binary',
    'https://example.com/markets/sample-market-001'
)
ON CONFLICT (platform, external_market_id) DO NOTHING;
