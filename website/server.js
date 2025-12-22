import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import session from 'express-session';
import connectPgSimple from 'connect-pg-simple';
import passport from 'passport';
import * as client from 'openid-client';
import { Strategy } from 'openid-client/passport';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const PgSession = connectPgSimple(session);

app.set('trust proxy', 1);
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));

const sessionTtl = 7 * 24 * 60 * 60 * 1000;
app.use(session({
  store: new PgSession({ 
    pool, 
    tableName: 'sessions',
    createTableIfMissing: false
  }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { 
    httpOnly: true,
    secure: true,
    maxAge: sessionTtl
  }
}));

app.use(passport.initialize());
app.use(passport.session());

app.get('/healthz', (req, res) => {
  res.status(200).send('OK');
});

let oidcConfig = null;
const registeredStrategies = new Set();

async function getOidcConfig() {
  if (!oidcConfig) {
    oidcConfig = await client.discovery(
      new URL(process.env.ISSUER_URL || 'https://replit.com/oidc'),
      process.env.REPL_ID
    );
  }
  return oidcConfig;
}

async function upsertUser(claims) {
  await pool.query(`
    INSERT INTO users (id, email, first_name, last_name, profile_image_url, updated_at)
    VALUES ($1, $2, $3, $4, $5, NOW())
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      first_name = EXCLUDED.first_name,
      last_name = EXCLUDED.last_name,
      profile_image_url = EXCLUDED.profile_image_url,
      updated_at = NOW()
  `, [claims.sub, claims.email, claims.first_name, claims.last_name, claims.profile_image_url]);
}

async function setupAuth() {
  const config = await getOidcConfig();
  
  const verify = async (tokens, done) => {
    try {
      const claims = tokens.claims();
      const user = {
        claims,
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        expires_at: claims.exp
      };
      await upsertUser(claims);
      done(null, user);
    } catch (err) {
      done(err);
    }
  };

  const ensureStrategy = (domain) => {
    const strategyName = `replitauth:${domain}`;
    if (!registeredStrategies.has(strategyName)) {
      const strategy = new Strategy({
        name: strategyName,
        config,
        scope: 'openid email profile offline_access',
        callbackURL: `https://${domain}/api/callback`
      }, verify);
      passport.use(strategy);
      registeredStrategies.add(strategyName);
    }
    return strategyName;
  };

  passport.serializeUser((user, done) => done(null, user));
  passport.deserializeUser((user, done) => done(null, user));

  app.get('/api/login', (req, res, next) => {
    const strategyName = ensureStrategy(req.hostname);
    passport.authenticate(strategyName, {
      prompt: 'login consent',
      scope: ['openid', 'email', 'profile', 'offline_access']
    })(req, res, next);
  });

  app.get('/api/callback', (req, res, next) => {
    const strategyName = ensureStrategy(req.hostname);
    passport.authenticate(strategyName, {
      successReturnToOrRedirect: '/',
      failureRedirect: '/'
    })(req, res, next);
  });

  app.get('/api/logout', async (req, res) => {
    const config = await getOidcConfig();
    req.logout(() => {
      const endSessionUrl = client.buildEndSessionUrl(config, {
        client_id: process.env.REPL_ID,
        post_logout_redirect_uri: `https://${req.hostname}`
      });
      res.redirect(endSessionUrl.href);
    });
  });
}

setupAuth().catch(err => console.error('Auth setup failed:', err));

app.use((req, res, next) => {
  if (req.user?.claims) {
    res.locals.user = {
      id: req.user.claims.sub,
      email: req.user.claims.email,
      firstName: req.user.claims.first_name,
      lastName: req.user.claims.last_name,
      profileImage: req.user.claims.profile_image_url
    };
  } else {
    res.locals.user = null;
  }
  next();
});

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

app.get('/submit', (req, res) => {
  res.render('submit', { success: false });
});

app.post('/submit', async (req, res) => {
  if (!req.user?.claims?.sub) {
    return res.redirect('/api/login');
  }

  const { submission_type, book_title, chapter_title, content, notes } = req.body;
  
  try {
    await pool.query(`
      INSERT INTO submissions (user_id, submission_type, book_title, chapter_title, content, notes)
      VALUES ($1, $2, $3, $4, $5, $6)
    `, [req.user.claims.sub, submission_type, book_title || null, chapter_title || null, content, notes || null]);

    res.render('submit', { success: true });
  } catch (err) {
    console.error('Submission error:', err);
    res.status(500).send('Error saving submission');
  }
});

const MODERATORS = (process.env.MODERATOR_IDS || '').split(',').filter(Boolean);

function isModerator(userId) {
  return MODERATORS.length === 0 || MODERATORS.includes(userId);
}

app.get('/moderate', async (req, res) => {
  if (!req.user?.claims?.sub) {
    return res.redirect('/api/login');
  }
  
  if (!isModerator(req.user.claims.sub)) {
    return res.status(403).send('Access denied');
  }

  try {
    const result = await pool.query(`
      SELECT s.*, u.first_name, u.email 
      FROM submissions s 
      LEFT JOIN users u ON s.user_id = u.id 
      WHERE s.status = 'pending' 
      ORDER BY s.created_at ASC
    `);
    res.render('moderate', { submissions: result.rows });
  } catch (err) {
    console.error('Moderation error:', err);
    res.status(500).send('Server error');
  }
});

app.post('/moderate/:id/approve', async (req, res) => {
  if (!req.user?.claims?.sub) {
    return res.redirect('/api/login');
  }
  
  if (!isModerator(req.user.claims.sub)) {
    return res.status(403).send('Access denied');
  }

  try {
    await pool.query(`
      UPDATE submissions 
      SET status = 'approved', reviewed_at = NOW(), reviewed_by = $1 
      WHERE id = $2
    `, [req.user.claims.sub, req.params.id]);
    res.redirect('/moderate');
  } catch (err) {
    console.error('Approval error:', err);
    res.status(500).send('Server error');
  }
});

app.post('/moderate/:id/reject', async (req, res) => {
  if (!req.user?.claims?.sub) {
    return res.redirect('/api/login');
  }
  
  if (!isModerator(req.user.claims.sub)) {
    return res.status(403).send('Access denied');
  }

  try {
    await pool.query(`
      UPDATE submissions 
      SET status = 'rejected', reviewed_at = NOW(), reviewed_by = $1 
      WHERE id = $2
    `, [req.user.claims.sub, req.params.id]);
    res.redirect('/moderate');
  } catch (err) {
    console.error('Rejection error:', err);
    res.status(500).send('Server error');
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => console.log(`Server running at http://0.0.0.0:${PORT}`));
