-- Insert a new quote with tags
WITH ins AS (
    INSERT OR IGNORE INTO quotes (text, author, coauthor, source, created_at)
    VALUES (
        'Blessed are the wanderers, for they remember that no roof is higher than the sky.',
        'All Faiths On Fire — Human Co-author',
        'ChatGPT (GPT-5 Thinking AI) Co-author',
        'draft',
        STRFTIME('%s','now')
    )
    RETURNING id
)
INSERT INTO quote_tags (quote_id, tag_id)
SELECT ins.id, t.id
FROM ins
JOIN tags t ON t.tag_name IN ('wanderers','nomadism','freedom');
