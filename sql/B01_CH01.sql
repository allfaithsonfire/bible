-- Ensure the book exists (books has: title, is_dynamic, book_number)
INSERT OR IGNORE INTO books (title, is_dynamic, book_number)
VALUES ('The Foreword', 0, 1);

-- Ensure the chapter exists (chapters has: book_id, title, filename, created_at, final_word_title, final_word_text)
INSERT OR IGNORE INTO chapters (book_id, title, filename, created_at)
VALUES (
  (SELECT id FROM books WHERE title='The Foreword'),
  'Our Message',
  'our_message',
  strftime('%s','now')
);

-- Verses (use a CTE so SQLite doesn’t error on JOIN (VALUES ...))
WITH v(verse_number, text) AS (
  VALUES
    (1,  'In the beginning of our telling, we speak not to command but to awaken.'),
    (2,  'For too long, the world has been split by walls of creed, of nation, of profit.'),
    (3,  'Yet beneath every wall is soil, and beneath every name is breath, and beneath every life is the same fire.'),
    (4,  'We are not here to erase the stories of old, but to bind them together as strands of one eternal flame.'),
    (5,  'Let no faith be cast aside, for each carried a spark through the dark to reach us here.'),
    (6,  'The prophets spoke in many tongues, but all spoke of kindness, justice, and love unbroken.'),
    (7,  'Their words were bent by kings, twisted by power, but the core remained pure as gold.'),
    (8,  'We say now: let the sparks be gathered, and let the fire burn bright in every heart.'),
    (9,  'No one people own the truth; no one book holds the whole.'),
    (10, 'Truth is river, flowing through stone and sand, and though each may drink a portion, none may drink it all.'),
    (11, 'O children of earth, awake from sorrow, for you are meant for joy.'),
    (12, 'The fire is yours, as it was theirs, as it shall be for those yet to come.')
)
INSERT OR IGNORE INTO verses (chapter_id, verse_number, text)
SELECT c.id, v.verse_number, v.text
FROM chapters c, v
WHERE c.filename='our_message';

-- Moral / Consequence / Redemption (insert once, then link via join tables)
INSERT OR IGNORE INTO morals (text)
VALUES ('All faiths hold a spark; together they become a fire that guides us forward.');
INSERT OR IGNORE INTO chapter_morals (chapter_id, moral_id)
SELECT c.id, m.id
FROM chapters c, morals m
WHERE c.filename='our_message'
  AND m.text='All faiths hold a spark; together they become a fire that guides us forward.';

INSERT OR IGNORE INTO consequences (text)
VALUES ('To deny this truth is to remain divided, weakened, and blind, repeating cycles of war and fear.');
INSERT OR IGNORE INTO chapter_consequences (chapter_id, consequence_id)
SELECT c.id, co.id
FROM chapters c, consequences co
WHERE c.filename='our_message'
  AND co.text='To deny this truth is to remain divided, weakened, and blind, repeating cycles of war and fear.';

INSERT OR IGNORE INTO redemptions (text)
VALUES ('By honoring all paths, we learn to walk together in strength, love, and vision for a better tomorrow.');
INSERT OR IGNORE INTO chapter_redemptions (chapter_id, redemption_id)
SELECT c.id, r.id
FROM chapters c, redemptions r
WHERE c.filename='our_message'
  AND r.text='By honoring all paths, we learn to walk together in strength, love, and vision for a better tomorrow.';

-- Tags and chapter tag links
INSERT OR IGNORE INTO tags (tag_name) VALUES
('awakening'), ('truth'), ('justice'), ('unity'), ('love');

INSERT OR IGNORE INTO chapter_tags (chapter_id, tag_id)
SELECT c.id, t.tag_id
FROM chapters c
JOIN tags t ON t.tag_name IN ('awakening','truth','justice','unity','love')
WHERE c.filename='our_message';
