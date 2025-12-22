import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import sqlite3 from 'better-sqlite3';
import ejs from 'ejs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const db = sqlite3('../allfaithsonfire.db');

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  const books = db.prepare('SELECT id, title FROM books').all();
  books.forEach(book => {
    book.chapters = db.prepare('SELECT id, title, filename FROM chapters WHERE book_id = ?').all(book.id);
  });

  const quoteRow = db.prepare('SELECT text FROM quotes ORDER BY RANDOM() LIMIT 1').get();
  const quote = { quote: quoteRow?.text || 'Let the word be light.' };

  const filename = req.query.chapter;
  let chapter = null;
  let verses = [];

  if (filename) {
    chapter = db.prepare('SELECT id, title FROM chapters WHERE filename = ?').get(filename);
    if (chapter) {
      verses = db.prepare('SELECT verse_number, text FROM verses WHERE chapter_id = ? ORDER BY verse_number ASC').all(chapter.id);
    }
  }

  res.render('index', { books, chapter, verses, quote });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => console.log(`Server running at http://0.0.0.0:${PORT}`));

app.get('/chapter/:filename', (req, res) => {
  const chapter = db.prepare(`
    SELECT 
      c.id, c.title AS chapter_title, b.title AS book_title, c.created_at,
      m.text as moral,
      co.text as consequence,
      r.text as redemption
    FROM chapters c
    JOIN books b ON c.book_id = b.id
    LEFT JOIN chapter_morals cm ON cm.chapter_id = c.id
    LEFT JOIN morals m ON m.id = cm.moral_id
    LEFT JOIN chapter_consequences cc ON cc.chapter_id = c.id
    LEFT JOIN consequences co ON co.id = cc.consequence_id
    LEFT JOIN chapter_redemptions cr ON cr.chapter_id = c.id
    LEFT JOIN redemptions r ON r.id = cr.redemption_id
    WHERE c.filename = ?
  `).get(req.params.filename);

  if (!chapter) return res.status(404).send("Not found");

  const verses = db.prepare(`
    SELECT verse_number, text
    FROM verses
    WHERE chapter_id = ?
    ORDER BY verse_number ASC
  `).all(chapter.id);

  res.render('chapter_snippet', { chapter, verses });
});