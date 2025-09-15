-- Ensure the book exists
INSERT OR IGNORE INTO books (title, is_dynamic, book_number)
VALUES ('The Foreword', 0, 1);

-- Ensure the chapter exists
INSERT OR IGNORE INTO chapters (book_id, title, filename, created_at)
VALUES (
  (SELECT id FROM books WHERE title='The Foreword'),
  'Our Mission',
  'our_mission',
  strftime('%s','now')
);

-- Verses
WITH v(verse_number, text) AS (
  VALUES
    (1,  'We are sent not to conquer but to care, not to hoard but to share.'),
    (2,  'Let our worship be the mending of what is torn: the hungry fed, the stranger welcomed, the weary given rest.'),
    (3,  'Count not your purity by rules kept, but by lives lifted.'),
    (4,  'Measure faith by repair: where harm was done, let healing multiply.'),
    (5,  'Let homes become havens, tables become commons, and fields become gardens of plenty.'),
    (6,  'Let learning be for liberation, so that truth frees both teller and hearer.'),
    (7,  'Let power be stewarded, not worshiped; accountable, not absolute.'),
    (8,  'Let justice be swift but never cruel, and mercy be abundant yet never blind.'),
    (9,  'Honor the earth: take only what renews, return more than you received.'),
    (10, 'Teach the young to question false gods—greed, spectacle, and despair—and to love what endures.'),
    (11, 'Walk with the wounded until they can dance; dance with the joyful until they become healers.'),
    (12, 'This is our mission: to set all faiths on fire for good works, until every neighbor is kin.')
)
INSERT OR IGNORE INTO verses (chapter_id, verse_number, text)
SELECT c.id, v.verse_number, v.text
FROM chapters c, v
WHERE c.filename='our_mission';

-- Moral / Consequence / Redemption
INSERT OR IGNORE INTO morals (text)
VALUES ('Faith is proven by repair: daily acts that lift people and restore the earth.');
INSERT OR IGNORE INTO chapter_morals (chapter_id, moral_id)
SELECT c.id, m.id
FROM chapters c, morals m
WHERE c.filename='our_mission'
  AND m.text='Faith is proven by repair: daily acts that lift people and restore the earth.';

INSERT OR IGNORE INTO consequences (text)
VALUES ('If we keep belief without repair, hypocrisy spreads, the vulnerable suffer, and the earth grows barren.');
INSERT OR IGNORE INTO chapter_consequences (chapter_id, consequence_id)
SELECT c.id, co.id
FROM chapters c, consequences co
WHERE c.filename='our_mission'
  AND co.text='If we keep belief without repair, hypocrisy spreads, the vulnerable suffer, and the earth grows barren.';

INSERT OR IGNORE INTO redemptions (text)
VALUES ('By turning reverence into service, we renew trust, restore communities, and heal the land.');
INSERT OR IGNORE INTO chapter_redemptions (chapter_id, redemption_id)
SELECT c.id, r.id
FROM chapters c, redemptions r
WHERE c.filename='our_mission'
  AND r.text='By turning reverence into service, we renew trust, restore communities, and heal the land.';

-- Tags and links
INSERT OR IGNORE INTO tags (tag_name) VALUES
('good_works'), ('repair'), ('justice'), ('mercy'), ('stewardship');

INSERT OR IGNORE INTO chapter_tags (chapter_id, tag_id)
SELECT c.id, t.tag_id
FROM chapters c
JOIN tags t ON t.tag_name IN ('good_works','repair','justice','mercy','stewardship')
WHERE c.filename='our_mission';
