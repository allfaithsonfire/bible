import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', async (req, res) => {
  try {
    const booksResult = await pool.query('SELECT id, title FROM books ORDER BY book_number');
    const books = booksResult.rows;
    
    for (const book of books) {
      const chaptersResult = await pool.query(
        'SELECT id, title, filename FROM chapters WHERE book_id = $1',
        [book.id]
      );
      book.chapters = chaptersResult.rows;
    }

    const quoteResult = await pool.query('SELECT text FROM quotes ORDER BY RANDOM() LIMIT 1');
    const quote = { quote: quoteResult.rows[0]?.text || 'Let the word be light.' };

    const filename = req.query.chapter;
    let chapter = null;
    let verses = [];

    if (filename) {
      const chapterResult = await pool.query(
        'SELECT id, title FROM chapters WHERE filename = $1',
        [filename]
      );
      chapter = chapterResult.rows[0] || null;
      if (chapter) {
        const versesResult = await pool.query(
          'SELECT verse_number, text FROM verses WHERE chapter_id = $1 ORDER BY verse_number ASC',
          [chapter.id]
        );
        verses = versesResult.rows;
      }
    }

    res.render('index', { books, chapter, verses, quote });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).send('Server error');
  }
});

app.get('/chapter/:filename', async (req, res) => {
  try {
    const chapterResult = await pool.query(`
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
      WHERE c.filename = $1
    `, [req.params.filename]);

    const chapter = chapterResult.rows[0];
    if (!chapter) return res.status(404).send("Not found");

    const versesResult = await pool.query(`
      SELECT verse_number, text
      FROM verses
      WHERE chapter_id = $1
      ORDER BY verse_number ASC
    `, [chapter.id]);

    res.render('chapter_snippet', { chapter, verses: versesResult.rows });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).send('Server error');
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => console.log(`Server running at http://0.0.0.0:${PORT}`));
