import sqlite3 from 'better-sqlite3';
import pg from 'pg';

const { Pool } = pg;

const sqliteDb = sqlite3('./allfaithsonfire.db');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function createSchema() {
  const client = await pool.connect();
  try {
    await client.query(`
      DROP TABLE IF EXISTS revision_authors CASCADE;
      DROP TABLE IF EXISTS revisions CASCADE;
      DROP TABLE IF EXISTS authors CASCADE;
      DROP TABLE IF EXISTS featured_starts CASCADE;
      DROP TABLE IF EXISTS chapter_consequences CASCADE;
      DROP TABLE IF EXISTS chapter_morals CASCADE;
      DROP TABLE IF EXISTS chapter_redemptions CASCADE;
      DROP TABLE IF EXISTS derived_books CASCADE;
      DROP TABLE IF EXISTS chapter_links CASCADE;
      DROP TABLE IF EXISTS verse_tags CASCADE;
      DROP TABLE IF EXISTS chapter_tags CASCADE;
      DROP TABLE IF EXISTS verses CASCADE;
      DROP TABLE IF EXISTS chapters CASCADE;
      DROP TABLE IF EXISTS consequence_tags CASCADE;
      DROP TABLE IF EXISTS moral_tags CASCADE;
      DROP TABLE IF EXISTS redemption_tags CASCADE;
      DROP TABLE IF EXISTS links CASCADE;
      DROP TABLE IF EXISTS redemptions CASCADE;
      DROP TABLE IF EXISTS consequences CASCADE;
      DROP TABLE IF EXISTS morals CASCADE;
      DROP TABLE IF EXISTS quotes CASCADE;
      DROP TABLE IF EXISTS tags CASCADE;
      DROP TABLE IF EXISTS books CASCADE;
    `);

    await client.query(`
      CREATE TABLE books (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL UNIQUE,
        is_dynamic INTEGER NOT NULL DEFAULT 0,
        book_number INTEGER
      );

      CREATE TABLE tags (
        tag_id SERIAL PRIMARY KEY,
        tag_name TEXT NOT NULL UNIQUE
      );

      CREATE TABLE quotes (
        id SERIAL PRIMARY KEY,
        text TEXT NOT NULL UNIQUE,
        author TEXT,
        coauthor TEXT,
        source TEXT,
        source_url TEXT,
        created_at INTEGER,
        posted_at INTEGER
      );

      CREATE TABLE morals (
        id SERIAL PRIMARY KEY,
        text TEXT NOT NULL UNIQUE
      );

      CREATE TABLE consequences (
        id SERIAL PRIMARY KEY,
        text TEXT NOT NULL UNIQUE
      );

      CREATE TABLE redemptions (
        id SERIAL PRIMARY KEY,
        text TEXT NOT NULL UNIQUE
      );

      CREATE TABLE links (
        link_id SERIAL PRIMARY KEY,
        url TEXT NOT NULL UNIQUE,
        title TEXT,
        description TEXT
      );

      CREATE TABLE redemption_tags (
        redemption_id INTEGER NOT NULL REFERENCES redemptions(id) ON DELETE CASCADE,
        tag_id INTEGER NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
        PRIMARY KEY (redemption_id, tag_id)
      );

      CREATE TABLE moral_tags (
        moral_id INTEGER NOT NULL REFERENCES morals(id) ON DELETE CASCADE,
        tag_id INTEGER NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
        PRIMARY KEY (moral_id, tag_id)
      );

      CREATE TABLE consequence_tags (
        consequence_id INTEGER NOT NULL REFERENCES consequences(id) ON DELETE CASCADE,
        tag_id INTEGER NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
        PRIMARY KEY (consequence_id, tag_id)
      );

      CREATE TABLE chapters (
        id SERIAL PRIMARY KEY,
        book_id INTEGER REFERENCES books(id),
        title TEXT NOT NULL,
        filename TEXT NOT NULL UNIQUE,
        created_at INTEGER,
        final_word_title TEXT,
        final_word_text TEXT
      );

      CREATE TABLE verses (
        id SERIAL PRIMARY KEY,
        chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
        verse_number INTEGER NOT NULL,
        text TEXT NOT NULL,
        UNIQUE (chapter_id, verse_number)
      );

      CREATE TABLE chapter_tags (
        chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
        tag_id INTEGER NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
        PRIMARY KEY (chapter_id, tag_id)
      );

      CREATE TABLE verse_tags (
        verse_id INTEGER NOT NULL REFERENCES verses(id) ON DELETE CASCADE,
        tag_id INTEGER NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
        PRIMARY KEY (verse_id, tag_id)
      );

      CREATE TABLE chapter_links (
        chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
        link_id INTEGER NOT NULL REFERENCES links(link_id) ON DELETE CASCADE,
        PRIMARY KEY (chapter_id, link_id)
      );

      CREATE TABLE derived_books (
        book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
        chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
        PRIMARY KEY (book_id, chapter_id)
      );

      CREATE TABLE chapter_redemptions (
        chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
        redemption_id INTEGER NOT NULL REFERENCES redemptions(id) ON DELETE CASCADE,
        PRIMARY KEY (chapter_id, redemption_id)
      );

      CREATE TABLE chapter_morals (
        chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
        moral_id INTEGER NOT NULL REFERENCES morals(id) ON DELETE CASCADE,
        PRIMARY KEY (chapter_id, moral_id)
      );

      CREATE TABLE chapter_consequences (
        chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
        consequence_id INTEGER NOT NULL REFERENCES consequences(id) ON DELETE CASCADE,
        PRIMARY KEY (chapter_id, consequence_id)
      );

      CREATE TABLE featured_starts (
        book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
        religion_tag TEXT NOT NULL,
        chapter_id INTEGER NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
        position INTEGER NOT NULL,
        PRIMARY KEY (book_id, religion_tag, position),
        UNIQUE (book_id, religion_tag, chapter_id)
      );

      CREATE TABLE authors (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        contact TEXT,
        role TEXT,
        UNIQUE (name, contact)
      );

      CREATE TABLE revisions (
        id SERIAL PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        revision_ts INTEGER NOT NULL,
        author_id INTEGER NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
        note TEXT,
        diff TEXT
      );

      CREATE TABLE revision_authors (
        revision_id INTEGER NOT NULL REFERENCES revisions(id) ON DELETE CASCADE,
        author_id INTEGER NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
        PRIMARY KEY (revision_id, author_id)
      );

      CREATE INDEX idx_chapters_filename ON chapters(filename);
      CREATE INDEX idx_chapters_bookid ON chapters(book_id);
      CREATE INDEX idx_chapter_tags_chapter ON chapter_tags(chapter_id);
      CREATE INDEX idx_chapter_tags_tag ON chapter_tags(tag_id);
      CREATE INDEX idx_verses_chapter ON verses(chapter_id);
      CREATE INDEX idx_featured_book_aud ON featured_starts(book_id, religion_tag);
    `);

    console.log('Schema created successfully');
  } finally {
    client.release();
  }
}

async function migrateTable(tableName, columns, idColumn = 'id') {
  const client = await pool.connect();
  try {
    const rows = sqliteDb.prepare(`SELECT * FROM ${tableName}`).all();
    if (rows.length === 0) {
      console.log(`No data in ${tableName}`);
      return;
    }
    
    for (const row of rows) {
      const cols = columns.filter(c => row[c] !== undefined);
      const vals = cols.map(c => row[c]);
      const placeholders = cols.map((_, i) => `$${i + 1}`).join(', ');
      
      await client.query(
        `INSERT INTO ${tableName} (${cols.join(', ')}) VALUES (${placeholders}) ON CONFLICT DO NOTHING`,
        vals
      );
    }
    
    if (idColumn) {
      const maxId = sqliteDb.prepare(`SELECT MAX(${idColumn}) as max_id FROM ${tableName}`).get();
      if (maxId?.max_id) {
        const seqName = `${tableName}_${idColumn}_seq`;
        await client.query(`SELECT setval('${seqName}', $1, true)`, [maxId.max_id]);
      }
    }
    
    console.log(`Migrated ${rows.length} rows from ${tableName}`);
  } finally {
    client.release();
  }
}

async function migrate() {
  try {
    await createSchema();
    
    await migrateTable('books', ['id', 'title', 'is_dynamic', 'book_number']);
    await migrateTable('tags', ['tag_id', 'tag_name'], 'tag_id');
    await migrateTable('quotes', ['id', 'text', 'author', 'coauthor', 'source', 'source_url', 'created_at', 'posted_at']);
    await migrateTable('morals', ['id', 'text']);
    await migrateTable('consequences', ['id', 'text']);
    await migrateTable('redemptions', ['id', 'text']);
    await migrateTable('links', ['link_id', 'url', 'title', 'description'], 'link_id');
    await migrateTable('chapters', ['id', 'book_id', 'title', 'filename', 'created_at', 'final_word_title', 'final_word_text']);
    await migrateTable('verses', ['id', 'chapter_id', 'verse_number', 'text']);
    await migrateTable('authors', ['id', 'name', 'contact', 'role']);
    
    await migrateTable('redemption_tags', ['redemption_id', 'tag_id'], null);
    await migrateTable('moral_tags', ['moral_id', 'tag_id'], null);
    await migrateTable('consequence_tags', ['consequence_id', 'tag_id'], null);
    await migrateTable('chapter_tags', ['chapter_id', 'tag_id'], null);
    await migrateTable('verse_tags', ['verse_id', 'tag_id'], null);
    await migrateTable('chapter_links', ['chapter_id', 'link_id'], null);
    await migrateTable('derived_books', ['book_id', 'chapter_id'], null);
    await migrateTable('chapter_redemptions', ['chapter_id', 'redemption_id'], null);
    await migrateTable('chapter_morals', ['chapter_id', 'moral_id'], null);
    await migrateTable('chapter_consequences', ['chapter_id', 'consequence_id'], null);
    await migrateTable('featured_starts', ['book_id', 'religion_tag', 'chapter_id', 'position'], null);
    await migrateTable('revisions', ['id', 'entity_type', 'entity_id', 'revision_ts', 'author_id', 'note', 'diff']);
    await migrateTable('revision_authors', ['revision_id', 'author_id'], null);
    
    console.log('Migration completed successfully!');
  } catch (err) {
    console.error('Migration failed:', err);
  } finally {
    await pool.end();
    sqliteDb.close();
  }
}

migrate();
