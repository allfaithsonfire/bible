BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "books" (
	"id"	INTEGER,
	"title"	TEXT NOT NULL UNIQUE,
	"is_dynamic"	INTEGER NOT NULL DEFAULT 0,
	"book_number"	INTEGER,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "tags" (
	"tag_id"	INTEGER,
	"tag_name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("tag_id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "quotes" (
	"id"	INTEGER,
	"quote"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "morals" (
	"id"	INTEGER,
	"text"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "consequences" (
	"id"	INTEGER,
	"text"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "redemptions" (
	"id"	INTEGER,
	"text"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "links" (
	"link_id"	INTEGER,
	"url"	TEXT NOT NULL UNIQUE,
	"title"	TEXT,
	"description"	TEXT,
	PRIMARY KEY("link_id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "redemption_tags" (
	"redemption_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	PRIMARY KEY("redemption_id","tag_id"),
	FOREIGN KEY("redemption_id") REFERENCES "redemptions"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "moral_tags" (
	"moral_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	PRIMARY KEY("moral_id","tag_id"),
	FOREIGN KEY("moral_id") REFERENCES "morals"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "consequence_tags" (
	"consequence_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	PRIMARY KEY("consequence_id","tag_id"),
	FOREIGN KEY("consequence_id") REFERENCES "consequences"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "chapters" (
	"id"	INTEGER,
	"book_id"	INTEGER,
	"title"	TEXT NOT NULL,
	"filename"	TEXT NOT NULL UNIQUE,
	"created_at"	INTEGER,
	"final_word_title"	TEXT,
	"final_word_text"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("book_id") REFERENCES "books"("id")
);
CREATE TABLE IF NOT EXISTS "verses" (
	"id"	INTEGER,
	"chapter_id"	INTEGER NOT NULL,
	"verse_number"	INTEGER NOT NULL,
	"text"	TEXT NOT NULL,
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "chapter_tags" (
	"chapter_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	PRIMARY KEY("chapter_id","tag_id"),
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "verse_tags" (
	"verse_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	PRIMARY KEY("verse_id","tag_id"),
	FOREIGN KEY("verse_id") REFERENCES "verses"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "chapter_links" (
	"chapter_id"	INTEGER NOT NULL,
	"link_id"	INTEGER NOT NULL,
	PRIMARY KEY("chapter_id","link_id"),
	FOREIGN KEY("link_id") REFERENCES "links"("link_id") ON DELETE CASCADE,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "derived_books" (
	"book_id"	INTEGER NOT NULL,
	"chapter_id"	INTEGER NOT NULL,
	PRIMARY KEY("book_id","chapter_id"),
	FOREIGN KEY("book_id") REFERENCES "books"("id") ON DELETE CASCADE,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "chapter_redemptions" (
	"chapter_id"	INTEGER NOT NULL,
	"redemption_id"	INTEGER NOT NULL,
	PRIMARY KEY("chapter_id","redemption_id"),
	FOREIGN KEY("redemption_id") REFERENCES "redemptions"("id") ON DELETE CASCADE,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "chapter_morals" (
	"chapter_id"	INTEGER NOT NULL,
	"moral_id"	INTEGER NOT NULL,
	PRIMARY KEY("chapter_id","moral_id"),
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	FOREIGN KEY("moral_id") REFERENCES "morals"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "chapter_consequences" (
	"chapter_id"	INTEGER NOT NULL,
	"consequence_id"	INTEGER NOT NULL,
	PRIMARY KEY("chapter_id","consequence_id"),
	FOREIGN KEY("consequence_id") REFERENCES "consequences"("id") ON DELETE CASCADE,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "featured_starts" (
	"book_id"	INTEGER NOT NULL,
	"religion_tag"	TEXT NOT NULL,
	"chapter_id"	INTEGER NOT NULL,
	"position"	INTEGER NOT NULL,
	PRIMARY KEY("book_id","religion_tag","position"),
	UNIQUE("book_id","religion_tag","chapter_id"),
	FOREIGN KEY("book_id") REFERENCES "books"("id") ON DELETE CASCADE,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "authors" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL,
	"contact"	TEXT,
	"role"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT),
	UNIQUE("name","contact")
);
CREATE TABLE IF NOT EXISTS "revisions" (
	"id"	INTEGER,
	"entity_type"	TEXT NOT NULL,
	"entity_id"	INTEGER NOT NULL,
	"revision_ts"	INTEGER NOT NULL,
	"author_id"	INTEGER NOT NULL,
	"note"	TEXT,
	"diff"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("author_id") REFERENCES "authors"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "revision_authors" (
	"revision_id"	INTEGER NOT NULL,
	"author_id"	INTEGER NOT NULL,
	PRIMARY KEY("revision_id","author_id"),
	FOREIGN KEY("revision_id") REFERENCES "revisions"("id") ON DELETE CASCADE,
	FOREIGN KEY("author_id") REFERENCES "authors"("id") ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS "idx_chapters_filename" ON "chapters" (
	"filename"
);
CREATE INDEX IF NOT EXISTS "idx_chapters_bookid" ON "chapters" (
	"book_id"
);
CREATE INDEX IF NOT EXISTS "idx_chapter_tags_chapter" ON "chapter_tags" (
	"chapter_id"
);
CREATE INDEX IF NOT EXISTS "idx_chapter_tags_tag" ON "chapter_tags" (
	"tag_id"
);
CREATE INDEX IF NOT EXISTS "idx_verses_chapter" ON "verses" (
	"chapter_id"
);
CREATE INDEX IF NOT EXISTS "idx_featured_book_aud" ON "featured_starts" (
	"book_id",
	"religion_tag"
);
CREATE INDEX IF NOT EXISTS "idx_chaptertags_chapter" ON "chapter_tags" (
	"chapter_id"
);
CREATE INDEX IF NOT EXISTS "idx_chaptertags_tag" ON "chapter_tags" (
	"tag_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "idx_verses_unique" ON "verses" (
	"chapter_id",
	"verse_number"
);
CREATE VIEW v_chapter_teachings AS
SELECT c.id AS chapter_id, c.title, c.filename, c.book_id,
       m.text AS moral, co.text AS consequence, r.text AS redemption
FROM chapters c
LEFT JOIN chapter_morals cm        ON cm.chapter_id = c.id
LEFT JOIN morals m                 ON m.id = cm.moral_id
LEFT JOIN chapter_consequences cc  ON cc.chapter_id = c.id
LEFT JOIN consequences co          ON co.id = cc.consequence_id
LEFT JOIN chapter_redemptions cr   ON cr.chapter_id = c.id
LEFT JOIN redemptions r            ON r.id = cr.redemption_id;
CREATE VIEW v_chapter_summary AS
SELECT c.id AS chapter_id, b.title AS book, c.title, c.filename, c.created_at,
       (SELECT COUNT(*) FROM verses v WHERE v.chapter_id = c.id) AS verse_count,
       (SELECT GROUP_CONCAT(t.tag_name, ', ')
          FROM chapter_tags ct JOIN tags t ON t.tag_id = ct.tag_id
         WHERE ct.chapter_id = c.id) AS tags
FROM chapters c
JOIN books b ON b.id = c.book_id;
COMMIT;
