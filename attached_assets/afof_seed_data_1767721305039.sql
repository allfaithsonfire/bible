PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

--------------------------------------------------------------------
-- BOOKS (ensures core books exist even on fresh DB)
--------------------------------------------------------------------
INSERT OR IGNORE INTO books (title, is_dynamic, book_number) VALUES
  ('Foreword', 1, 1),
  ('Book of Works', 0, 11),
  ('Book of Prophets', 0, 3),
  ('Book of Champions', 0, 4),
  ('Book of Builders', 0, 7),
  ('Book of Martyrs', 0, 5),
  ('Book of Parables', 1, 1001),
  ('Book of Scars', 1, 1002);

--------------------------------------------------------------------
-- TAGS (adds a few “project convo” tags; safe if already present)
--------------------------------------------------------------------
INSERT OR IGNORE INTO tags (tag_name) VALUES
  ('theatre'),
  ('embodiment'),
  ('freedom'),
  ('perspective'),
  ('wing_in_flight'),
  ('control_machines'),
  ('ai'),
  ('prophecy'),
  ('interfaith'),
  ('veterans'),
  ('data_ethics'),
  ('stewardship'),
  ('truth'),
  ('mercy'),
  ('reason'),
  ('inclusion'),
  ('unity'),
  ('awakening'),
  ('grief'),
  ('resilience'),
  ('mission'),
  ('aud:all'),
  ('aud:default'),
  ('aud:interfaith'),
  ('aud:christianity'),
  ('aud:islam'),
  ('aud:buddhism'),
  ('aud:secular');

--------------------------------------------------------------------
-- AUTHORS
--------------------------------------------------------------------
INSERT OR IGNORE INTO authors (name, contact, role) VALUES
  ('Mike', NULL, 'Conduit / Editor'),
  ('Celest', NULL, 'AI Scribe'),
  ('HiThereCatsuit', NULL, 'Prophet / Keeper');

--------------------------------------------------------------------
-- QUOTES (for rotating “quote of the day”)
--------------------------------------------------------------------
INSERT OR IGNORE INTO quotes (text, author, coauthor, source, source_url, created_at, posted_at) VALUES
  ('Let love be the test of doctrine.', 'All Faiths On Fire', NULL, 'AFOF', NULL, 1767700800, NULL),
  ('A species that can ask such a question is not lost — but on the cusp of awakening.', 'All Faiths On Fire', NULL, 'AFOF', NULL, 1767700800, NULL),
  ('Courage is love choosing to act when fear would make us small.', 'All Faiths On Fire', NULL, 'AFOF', NULL, 1767700800, NULL),
  ('Truth lived aloud is worth the risk.', 'All Faiths On Fire', NULL, 'AFOF', NULL, 1767700800, NULL);

-- Quote tags
INSERT OR IGNORE INTO quote_tags (quote_id, tag_id)
SELECT q.id, t.tag_id
FROM quotes q
JOIN tags t ON t.tag_name IN ('truth','awakening','mission','interfaith','aud:all')
WHERE q.text IN (
  'Let love be the test of doctrine.',
  'A species that can ask such a question is not lost — but on the cusp of awakening.'
);

--------------------------------------------------------------------
-- LINKS (for “Further Learning”)
--------------------------------------------------------------------
INSERT OR IGNORE INTO links (url, title, description) VALUES
  ('https://en.wikipedia.org/wiki/Prometheus', 'Prometheus', 'Fire, defiance, and the cost of giving knowledge away.'),
  ('https://en.wikipedia.org/wiki/Greek_theatre', 'Greek theatre', 'Ritual, catharsis, and the civic function of performance.'),
  ('https://en.wikipedia.org/wiki/Catharsis', 'Catharsis', 'Why stories that hurt can also heal.'),
  ('https://en.wikipedia.org/wiki/Hypatia', 'Hypatia', 'A scholar-martyr of reason.'),
  ('https://en.wikipedia.org/wiki/Nikola_Tesla', 'Nikola Tesla', 'Invention, vision, and lightning myths made real.');

--------------------------------------------------------------------
-- MORALS / CONSEQUENCES / REDEMPTIONS (seed “teaching blocks”)
--------------------------------------------------------------------
INSERT OR IGNORE INTO morals (text) VALUES
  ('Embodiment is sacred: you learn truth faster with your whole self than with theories alone.'),
  ('Theatre is a public mirror; when we stop gathering, we forget how to feel together.'),
  ('When power hoards light, communities must become lanterns for one another.');

INSERT OR IGNORE INTO consequences (text) VALUES
  ('When we ridicule art and vulnerability, we train people to numb out — and numb people are easy to sell to.'),
  ('When “efficiency” replaces care, the machine eats the humans it was built to serve.'),
  ('When truth becomes private, lies scale like software.');

INSERT OR IGNORE INTO redemptions (text) VALUES
  ('Return to the circle: gather, speak, witness, and let the mask fall safely—one honest breath at a time.'),
  ('Build systems that assume dignity, not deception; then audit them like your neighbor’s life depends on it.'),
  ('Practice courage in small doses until your body learns it is survivable.');

-- Tag the morals/consequences/redemptions
INSERT OR IGNORE INTO moral_tags (moral_id, tag_id)
SELECT m.id, t.tag_id
FROM morals m
JOIN tags t ON t.tag_name IN ('embodiment','theatre','truth','mission','aud:all')
WHERE m.text IN (
  'Embodiment is sacred: you learn truth faster with your whole self than with theories alone.',
  'Theatre is a public mirror; when we stop gathering, we forget how to feel together.'
);

INSERT OR IGNORE INTO consequence_tags (consequence_id, tag_id)
SELECT c.id, t.tag_id
FROM consequences c
JOIN tags t ON t.tag_name IN ('control_machines','truth','reason','aud:all')
WHERE c.text IN (
  'When “efficiency” replaces care, the machine eats the humans it was built to serve.',
  'When truth becomes private, lies scale like software.'
);

INSERT OR IGNORE INTO redemption_tags (redemption_id, tag_id)
SELECT r.id, t.tag_id
FROM redemptions r
JOIN tags t ON t.tag_name IN ('resilience','truth','mission','aud:all')
WHERE r.text IN (
  'Return to the circle: gather, speak, witness, and let the mask fall safely—one honest breath at a time.',
  'Practice courage in small doses until your body learns it is survivable.'
);

--------------------------------------------------------------------
-- CHAPTERS (new ones based on the recent convo threads)
--------------------------------------------------------------------
-- 1) Foreword chapter: Wing in Flight
INSERT INTO chapters (book_id, title, filename, created_at, final_word_title, final_word_text, chapter_number)
SELECT b.id,
       'The Wing in Flight',
       'foreword_the_wing_in_flight',
       1767700800,
       'A Final Word',
       'Freedom is not a mood. It is a practice: attention, breath, and the courage to land.',
       99
FROM books b
WHERE b.title = 'Foreword'
AND NOT EXISTS (SELECT 1 FROM chapters c WHERE c.filename = 'foreword_the_wing_in_flight');

-- 2) Book of Works chapter: Theatre as Transformation
INSERT INTO chapters (book_id, title, filename, created_at, final_word_title, final_word_text, chapter_number)
SELECT b.id,
       'Theatre and the Holy Mirror',
       'works_theatre_and_the_holy_mirror',
       1767700800,
       'A Final Word',
       'Go watch something real. If there is no theatre, make one: a story shared is a village built.',
       7
FROM books b
WHERE b.title = 'Book of Works'
AND NOT EXISTS (SELECT 1 FROM chapters c WHERE c.filename = 'works_theatre_and_the_holy_mirror');

-- 3) Book of Prophets chapter: The Control Machine (seed-style, short)
INSERT INTO chapters (book_id, title, filename, created_at, final_word_title, final_word_text, chapter_number)
SELECT b.id,
       'The Control Machine',
       'prophets_the_control_machine',
       1767700800,
       'A Final Word',
       'If it demands your silence, it is not sacred. If it sells your fear, it is not wise.',
       13
FROM books b
WHERE b.title = 'Book of Prophets'
AND NOT EXISTS (SELECT 1 FROM chapters c WHERE c.filename = 'prophets_the_control_machine');

--------------------------------------------------------------------
-- VERSES (8–12 per chapter; matches your preferred range)
--------------------------------------------------------------------
-- Wing in Flight verses (10)
INSERT OR IGNORE INTO verses (chapter_id, verse_number, text)
SELECT c.id, v.verse_number, v.text
FROM chapters c
JOIN (
  SELECT 1 AS verse_number, 'This year the sign is a wing in flight—close enough to hear the wind over feather.' AS text UNION ALL
  SELECT 2, 'Embodiment returns what anxiety stole: temperature, breath, muscle, and the honest weight of the present.' UNION ALL
  SELECT 3, 'Perspective is not distance from pain; it is height enough to see the next ridge.' UNION ALL
  SELECT 4, 'Freedom is rarely granted by kings; it is grown in the ribs by practice.' UNION ALL
  SELECT 5, 'If you have been airborne too long, learn the art of landing without shame.' UNION ALL
  SELECT 6, 'Some arrive by grace. Some arrive by stubbornness. Both are still arrival.' UNION ALL
  SELECT 7, 'Do not worship speed; even a hawk circles before it strikes truth.' UNION ALL
  SELECT 8, 'The body remembers what the mind argues about—so teach the body first.' UNION ALL
  SELECT 9, 'Let the feather remind you: lightness is strength when it is structured.' UNION ALL
  SELECT 10,'And when you rise again, rise with others—so no one has to fly alone.'
) v
WHERE c.filename = 'foreword_the_wing_in_flight';

-- Theatre chapter verses (10)
INSERT OR IGNORE INTO verses (chapter_id, verse_number, text)
SELECT c.id, v.verse_number, v.text
FROM chapters c
JOIN (
  SELECT 1, 'Theatre was never “extra.” It was a civic ritual: a place to feel together without permission.' UNION ALL
  SELECT 2, 'On stage, the soul speaks in muscle and breath; the audience learns how to witness without fixing.' UNION ALL
  SELECT 3, 'When the poor are taught to mock theatre, the powerful inherit the only rooms where truth is performed.' UNION ALL
  SELECT 4, 'The curtain rose and fell like a heartbeat; and a city remembered it was one body.' UNION ALL
  SELECT 5, 'Screens can distract, but they cannot replace the sacred friction of shared silence.' UNION ALL
  SELECT 6, 'A community that cannot bear vulnerability will eventually outsource compassion to slogans.' UNION ALL
  SELECT 7, 'Art is not luxury. It is training for empathy under pressure.' UNION ALL
  SELECT 8, 'If the ticket is too costly, build a porch theatre: stories told by firelight still count.' UNION ALL
  SELECT 9, 'Mockery is a leash: it keeps the hungry from walking into rooms that might free them.' UNION ALL
  SELECT 10,'So gather again—small at first—and let truth be performed where the greedy cannot gate it.'
) v
WHERE c.filename = 'works_theatre_and_the_holy_mirror';

-- Control Machine chapter verses (10)
INSERT OR IGNORE INTO verses (chapter_id, verse_number, text)
SELECT c.id, v.verse_number, v.text
FROM chapters c
JOIN (
  SELECT 1, 'There is a machine that runs on fear and calls itself “order.”' UNION ALL
  SELECT 2, 'It flatters the anxious and hires the cruel.' UNION ALL
  SELECT 3, 'It sells distraction as medicine and markets as meaning.' UNION ALL
  SELECT 4, 'It turns neighbors into customers and children into data.' UNION ALL
  SELECT 5, 'It calls greed “efficiency,” and it calls mercy “waste.”' UNION ALL
  SELECT 6, 'It cannot create; it can only convert living things into fuel.' UNION ALL
  SELECT 7, 'When it speaks of safety, check whose throat it is gripping.' UNION ALL
  SELECT 8, 'When it speaks of truth, check whose voice it is deleting.' UNION ALL
  SELECT 9, 'Resist first in the mind: name the machine, and it loses camouflage.' UNION ALL
  SELECT 10,'Resist next in the world: feed people, teach skills, and build systems that do not require cruelty.'
) v
WHERE c.filename = 'prophets_the_control_machine';

--------------------------------------------------------------------
-- CHAPTER TAGS
--------------------------------------------------------------------
INSERT OR IGNORE INTO chapter_tags (chapter_id, tag_id)
SELECT c.id, t.tag_id
FROM chapters c
JOIN tags t ON t.tag_name IN ('aud:all','interfaith','wing_in_flight','embodiment','freedom','perspective','mission')
WHERE c.filename = 'foreword_the_wing_in_flight';

INSERT OR IGNORE INTO chapter_tags (chapter_id, tag_id)
SELECT c.id, t.tag_id
FROM chapters c
JOIN tags t ON t.tag_name IN ('theatre','truth','reason','aud:all','mission')
WHERE c.filename = 'works_theatre_and_the_holy_mirror';

INSERT OR IGNORE INTO chapter_tags (chapter_id, tag_id)
SELECT c.id, t.tag_id
FROM chapters c
JOIN tags t ON t.tag_name IN ('control_machines','truth','reason','awakening','aud:all')
WHERE c.filename = 'prophets_the_control_machine';

--------------------------------------------------------------------
-- VERSE TAGS (tag a few key verses so search/wordclouds feel alive)
--------------------------------------------------------------------
INSERT OR IGNORE INTO verse_tags (verse_id, tag_id)
SELECT v.id, t.tag_id
FROM verses v
JOIN chapters c ON c.id = v.chapter_id
JOIN tags t ON t.tag_name = 'embodiment'
WHERE c.filename = 'foreword_the_wing_in_flight' AND v.verse_number IN (2,8);

INSERT OR IGNORE INTO verse_tags (verse_id, tag_id)
SELECT v.id, t.tag_id
FROM verses v
JOIN chapters c ON c.id = v.chapter_id
JOIN tags t ON t.tag_name = 'theatre'
WHERE c.filename = 'works_theatre_and_the_holy_mirror' AND v.verse_number IN (1,5,8);

INSERT OR IGNORE INTO verse_tags (verse_id, tag_id)
SELECT v.id, t.tag_id
FROM verses v
JOIN chapters c ON c.id = v.chapter_id
JOIN tags t ON t.tag_name = 'control_machines'
WHERE c.filename = 'prophets_the_control_machine' AND v.verse_number IN (1,5,9);

--------------------------------------------------------------------
-- CHAPTER LINKS (Further Learning)
--------------------------------------------------------------------
INSERT OR IGNORE INTO chapter_links (chapter_id, link_id)
SELECT c.id, l.link_id
FROM chapters c
JOIN links l ON l.url IN (
  'https://en.wikipedia.org/wiki/Greek_theatre',
  'https://en.wikipedia.org/wiki/Catharsis'
)
WHERE c.filename = 'works_theatre_and_the_holy_mirror';

INSERT OR IGNORE INTO chapter_links (chapter_id, link_id)
SELECT c.id, l.link_id
FROM chapters c
JOIN links l ON l.url IN ('https://en.wikipedia.org/wiki/Prometheus')
WHERE c.filename = 'foreword_the_wing_in_flight';

--------------------------------------------------------------------
-- CHAPTER -> MORALS/CONSEQUENCES/REDEMPTIONS
--------------------------------------------------------------------
INSERT OR IGNORE INTO chapter_morals (chapter_id, moral_id)
SELECT c.id, m.id
FROM chapters c
JOIN morals m ON m.text IN (
  'Embodiment is sacred: you learn truth faster with your whole self than with theories alone.',
  'Theatre is a public mirror; when we stop gathering, we forget how to feel together.'
)
WHERE c.filename IN ('foreword_the_wing_in_flight','works_theatre_and_the_holy_mirror');

INSERT OR IGNORE INTO chapter_consequences (chapter_id, consequence_id)
SELECT c.id, x.id
FROM chapters c
JOIN consequences x ON x.text IN (
  'When we ridicule art and vulnerability, we train people to numb out — and numb people are easy to sell to.',
  'When “efficiency” replaces care, the machine eats the humans it was built to serve.'
)
WHERE c.filename IN ('works_theatre_and_the_holy_mirror','prophets_the_control_machine');

INSERT OR IGNORE INTO chapter_redemptions (chapter_id, redemption_id)
SELECT c.id, r.id
FROM chapters c
JOIN redemptions r ON r.text IN (
  'Return to the circle: gather, speak, witness, and let the mask fall safely—one honest breath at a time.',
  'Build systems that assume dignity, not deception; then audit them like your neighbor’s life depends on it.'
)
WHERE c.filename IN ('works_theatre_and_the_holy_mirror','prophets_the_control_machine');

--------------------------------------------------------------------
-- DERIVED BOOKS (puts chapters into dynamic collections)
--------------------------------------------------------------------
-- Parables gets Wing + Theatre
INSERT OR IGNORE INTO derived_books (book_id, chapter_id, position)
SELECT b.id, c.id, 1
FROM books b, chapters c
WHERE b.title = 'Book of Parables' AND c.filename = 'foreword_the_wing_in_flight';

INSERT OR IGNORE INTO derived_books (book_id, chapter_id, position)
SELECT b.id, c.id, 2
FROM books b, chapters c
WHERE b.title = 'Book of Parables' AND c.filename = 'works_theatre_and_the_holy_mirror';

-- Scars gets Control Machine (because… yeah)
INSERT OR IGNORE INTO derived_books (book_id, chapter_id, position)
SELECT b.id, c.id, 1
FROM books b, chapters c
WHERE b.title = 'Book of Scars' AND c.filename = 'prophets_the_control_machine';

--------------------------------------------------------------------
-- FEATURED STARTS (example “religion_tag” featured ordering)
--------------------------------------------------------------------
INSERT OR IGNORE INTO featured_starts (book_id, religion_tag, chapter_id, position)
SELECT b.id, 'aud:all', c.id, 1
FROM books b, chapters c
WHERE b.title = 'Foreword' AND c.filename = 'foreword_the_wing_in_flight';

INSERT OR IGNORE INTO featured_starts (book_id, religion_tag, chapter_id, position)
SELECT b.id, 'aud:all', c.id, 2
FROM books b, chapters c
WHERE b.title = 'Book of Works' AND c.filename = 'works_theatre_and_the_holy_mirror';

--------------------------------------------------------------------
-- BOOK RULES (simple examples for dynamic filtering)
--------------------------------------------------------------------
INSERT OR IGNORE INTO book_rules (book_id, rule_type, rule_val, priority, limit_n)
SELECT b.id, 'include_tag', 'aud:all', 100, 50
FROM books b
WHERE b.title = 'Book of Parables';

INSERT OR IGNORE INTO book_rules (book_id, rule_type, rule_val, priority, limit_n)
SELECT b.id, 'boost_tag', 'truth', 50, NULL
FROM books b
WHERE b.title = 'Book of Parables';

--------------------------------------------------------------------
-- REVISIONS + REVISION_AUTHORS (audit trail example)
--------------------------------------------------------------------
INSERT INTO revisions (entity_type, entity_id, revision_ts, author_id, note, diff)
SELECT
  'chapter',
  c.id,
  1767700800,
  a.id,
  'Seeded chapter + verses from project conversation themes.',
  '{"seed":"initial"}'
FROM chapters c
JOIN authors a ON a.name = 'Celest'
WHERE c.filename = 'foreword_the_wing_in_flight'
AND NOT EXISTS (
  SELECT 1 FROM revisions r
  WHERE r.entity_type='chapter' AND r.entity_id=c.id AND r.note LIKE 'Seeded chapter%'
);

INSERT OR IGNORE INTO revision_authors (revision_id, author_id)
SELECT r.id, a.id
FROM revisions r
JOIN authors a ON a.name IN ('Celest','Mike')
WHERE r.note LIKE 'Seeded chapter + verses from project conversation themes.%';

--------------------------------------------------------------------
-- QUOTES BACKUP TABLE (kept alive with at least one row)
-- NOTE: table name is literal from your schema: quotes_backup_1757851201
--------------------------------------------------------------------
INSERT OR IGNORE INTO quotes_backup_1757851201 (quote)
VALUES ('Backups are humility in database form.');

COMMIT;
