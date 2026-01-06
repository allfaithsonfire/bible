import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import session from 'express-session';
import connectPgSimple from 'connect-pg-simple';
import passport from 'passport';
import * as client from 'openid-client';
import { Strategy as OidcStrategy } from 'openid-client/passport';
import { Strategy as DiscordStrategy } from 'passport-discord-auth';

const isProduction = process.env.NODE_ENV === 'production';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const PgSession = connectPgSimple(session);

// Health check endpoint - BEFORE any middleware to ensure quick response
app.get('/healthz', (req, res) => {
  res.status(200).send('OK');
});

// Simple test endpoint - no database needed
app.get('/ping', (req, res) => {
  res.send('pong - server is running on port ' + (process.env.PORT || 5000));
});

app.set('trust proxy', 1);
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));

// Debug logging
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

const sessionTtl = 7 * 24 * 60 * 60 * 1000;
app.use(session({
  store: new PgSession({ 
    pool, 
    tableName: 'sessions',
    createTableIfMissing: false
  }),
  secret: process.env.SESSION_SECRET || 'dev-secret-change-in-production',
  resave: false,
  saveUninitialized: false,
  cookie: { 
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    maxAge: sessionTtl
  }
}));

app.use(passport.initialize());
app.use(passport.session());

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

async function getUserRoles(userId) {
  const result = await pool.query(
    'SELECT is_admin, is_moderator FROM users WHERE id = $1',
    [userId]
  );
  if (result.rows.length > 0) {
    return {
      isAdmin: result.rows[0].is_admin || false,
      isModerator: result.rows[0].is_moderator || false
    };
  }
  return { isAdmin: false, isModerator: false };
}

async function findOrCreateUserWithIdentity(provider, providerUserId, email, displayName, avatarUrl) {
  const identityResult = await pool.query(
    'SELECT user_id FROM user_identities WHERE provider = $1 AND provider_user_id = $2',
    [provider, providerUserId]
  );
  
  if (identityResult.rows.length > 0) {
    const userId = identityResult.rows[0].user_id;
    await pool.query(
      'UPDATE user_identities SET last_login_at = NOW(), display_name = $1, avatar_url = $2 WHERE provider = $3 AND provider_user_id = $4',
      [displayName, avatarUrl, provider, providerUserId]
    );
    await pool.query('UPDATE users SET updated_at = NOW() WHERE id = $1', [userId]);
    console.log(`[Auth] Found existing identity for ${provider}:${providerUserId} -> user ${userId}`);
    return userId;
  }
  
  let userId = null;
  if (email) {
    const emailResult = await pool.query(
      'SELECT id FROM users WHERE LOWER(email) = LOWER($1)',
      [email]
    );
    if (emailResult.rows.length > 0) {
      userId = emailResult.rows[0].id;
      console.log(`[Auth] Linking ${provider} identity to existing user ${userId} via email ${email}`);
    }
  }
  
  if (!userId) {
    userId = `${provider}:${providerUserId}`;
    await pool.query(`
      INSERT INTO users (id, email, first_name, profile_image_url, updated_at)
      VALUES ($1, $2, $3, $4, NOW())
      ON CONFLICT (id) DO UPDATE SET
        email = COALESCE(EXCLUDED.email, users.email),
        first_name = COALESCE(EXCLUDED.first_name, users.first_name),
        profile_image_url = COALESCE(EXCLUDED.profile_image_url, users.profile_image_url),
        updated_at = NOW()
    `, [userId, email, displayName, avatarUrl]);
    console.log(`[Auth] Created new user ${userId} for ${provider}`);
  }
  
  await pool.query(`
    INSERT INTO user_identities (user_id, provider, provider_user_id, email, display_name, avatar_url, last_login_at)
    VALUES ($1, $2, $3, $4, $5, $6, NOW())
    ON CONFLICT (provider, provider_user_id) DO UPDATE SET
      last_login_at = NOW(),
      display_name = EXCLUDED.display_name,
      avatar_url = EXCLUDED.avatar_url
  `, [userId, provider, providerUserId, email, displayName, avatarUrl]);
  
  return userId;
}

async function upsertUser(claims) {
  return findOrCreateUserWithIdentity(
    'replit',
    claims.sub,
    claims.email,
    `${claims.first_name || ''} ${claims.last_name || ''}`.trim() || claims.email,
    claims.profile_image_url
  );
}

async function upsertDiscordUser(profile) {
  const avatarUrl = profile.avatar 
    ? `https://cdn.discordapp.com/avatars/${profile.id}/${profile.avatar}.png`
    : null;
  
  return findOrCreateUserWithIdentity(
    'discord',
    profile.id,
    profile.email,
    profile.global_name || profile.username,
    avatarUrl
  );
}

async function setupAuth() {
  console.log('[Auth] Setting up authentication...');
  
  passport.serializeUser((user, done) => done(null, user));
  passport.deserializeUser((user, done) => done(null, user));

  if (isProduction) {
    console.log('[Auth] Production mode - Discord OAuth only');
    
    if (!process.env.DISCORD_CLIENT_ID || !process.env.DISCORD_CLIENT_SECRET) {
      console.error('[Auth] WARNING: Discord OAuth credentials not set!');
    }
    
    passport.use(new DiscordStrategy({
      clientId: process.env.DISCORD_CLIENT_ID,
      clientSecret: process.env.DISCORD_CLIENT_SECRET,
      callbackUrl: 'https://allfaithsonfire.org/auth/discord/callback',
      scope: ['identify', 'email']
    }, async (accessToken, refreshToken, profile, done) => {
      try {
        const discordId = await upsertDiscordUser(profile);
        const user = {
          provider: 'discord',
          id: discordId,
          discordId: profile.id,
          username: profile.username,
          globalName: profile.global_name,
          email: profile.email,
          avatar: profile.avatar
        };
        done(null, user);
      } catch (err) {
        done(err);
      }
    }));

    app.get('/api/login', passport.authenticate('discord'));
    
    app.get('/auth/discord/callback', 
      passport.authenticate('discord', { failureRedirect: '/' }),
      (req, res) => res.redirect('/')
    );

    app.get('/api/logout', (req, res) => {
      req.logout(() => {
        res.redirect('/');
      });
    });

  } else {
    console.log('[Auth] Development mode - Replit OAuth');
    
    const config = await getOidcConfig();
    console.log('[Auth] OIDC config loaded');
    
    const verify = async (tokens, done) => {
      try {
        const claims = tokens.claims();
        const userId = await upsertUser(claims);
        const user = {
          provider: 'replit',
          id: userId,
          claims,
          access_token: tokens.access_token,
          refresh_token: tokens.refresh_token,
          expires_at: claims.exp
        };
        done(null, user);
      } catch (err) {
        done(err);
      }
    };

    const ensureStrategy = (domain) => {
      const strategyName = `replitauth:${domain}`;
      if (!registeredStrategies.has(strategyName)) {
        const strategy = new OidcStrategy({
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
      const oidcConfig = await getOidcConfig();
      req.logout(() => {
        const endSessionUrl = client.buildEndSessionUrl(oidcConfig, {
          client_id: process.env.REPL_ID,
          post_logout_redirect_uri: `https://${req.hostname}`
        });
        res.redirect(endSessionUrl.href);
      });
    });
  }
}

app.use(async (req, res, next) => {
  try {
    if (req.user) {
      const userId = req.user.id || req.user.claims?.sub;
      let roles = { isAdmin: false, isModerator: false };
      try {
        roles = await getUserRoles(userId);
      } catch (dbErr) {
        console.error('[Auth] Failed to fetch user roles:', dbErr.message);
      }
      
      if (req.user.provider === 'discord') {
        const avatarUrl = req.user.avatar 
          ? `https://cdn.discordapp.com/avatars/${req.user.discordId}/${req.user.avatar}.png`
          : null;
        res.locals.user = {
          id: req.user.id,
          email: req.user.email,
          firstName: req.user.globalName || req.user.username,
          lastName: null,
          profileImage: avatarUrl,
          isAdmin: roles.isAdmin,
          isModerator: roles.isModerator
        };
      } else if (req.user.claims) {
        res.locals.user = {
          id: req.user.id,
          email: req.user.claims.email,
          firstName: req.user.claims.first_name,
          lastName: req.user.claims.last_name,
          profileImage: req.user.claims.profile_image_url,
          isAdmin: roles.isAdmin,
          isModerator: roles.isModerator
        };
      } else {
        res.locals.user = { id: req.user.id, isAdmin: roles.isAdmin, isModerator: roles.isModerator };
      }
    } else {
      res.locals.user = null;
    }
    res.locals.isProduction = isProduction;
    next();
  } catch (err) {
    console.error('[Auth] Middleware error:', err.message);
    next(err);
  }
});

function requireAuth(req, res, next) {
  if (!req.user) {
    return res.redirect('/api/login');
  }
  next();
}

function requireRole(roles) {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.redirect('/api/login');
      }
      const userId = req.user.id || req.user.claims?.sub;
      let userRoles = { isAdmin: false, isModerator: false };
      try {
        userRoles = await getUserRoles(userId);
      } catch (dbErr) {
        console.error('[Auth] Failed to fetch roles for access check:', dbErr.message);
        return res.status(500).render('error', {
          title: 'Server Error',
          message: 'Unable to verify permissions. Please try again.'
        });
      }
      
      const hasRole = roles.some(role => {
        if (role === 'admin') return userRoles.isAdmin;
        if (role === 'moderator') return userRoles.isModerator;
        return false;
      });
      
      if (!hasRole) {
        return res.status(403).render('error', { 
          title: 'Access Denied',
          message: 'You do not have permission to access this page.'
        });
      }
      next();
    } catch (err) {
      console.error('[Auth] requireRole error:', err.message);
      next(err);
    }
  };
}

app.get('/', async (req, res) => {
  console.log('[/] Home route hit');
  try {
    console.log('[/] Querying books...');
    const booksResult = await pool.query('SELECT id, title FROM books ORDER BY book_number');
    const books = booksResult.rows;
    console.log(`[/] Found ${books.length} books`);
    
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
          'SELECT id, verse_number, text FROM verses WHERE chapter_id = $1 ORDER BY verse_number ASC',
          [chapter.id]
        );
        verses = versesResult.rows;
      }
    }

    console.log('[/] Rendering index...');
    res.render('index', { books, chapter, verses, quote });
  } catch (err) {
    console.error('[/] Error in home route:', err);
    res.status(500).send('Server error: ' + err.message);
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
      SELECT id, verse_number, text
      FROM verses
      WHERE chapter_id = $1
      ORDER BY verse_number ASC
    `, [chapter.id]);

    res.render('chapter_snippet', { chapter, verses: versesResult.rows, user: res.locals.user });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).send('Server error');
  }
});

app.get('/content/about', (req, res) => {
  res.render('content/about');
});

app.get('/content/creed', (req, res) => {
  res.render('content/creed');
});

app.get('/api/books/search', async (req, res) => {
  try {
    const q = (req.query.q || '').trim();
    let result;
    if (q) {
      result = await pool.query(
        `SELECT id, title FROM books WHERE LOWER(title) LIKE LOWER($1) ORDER BY title LIMIT 10`,
        [`%${q}%`]
      );
    } else {
      result = await pool.query('SELECT id, title FROM books ORDER BY title LIMIT 10');
    }
    res.json(result.rows);
  } catch (err) {
    console.error('Book search error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/api/chapters/search', async (req, res) => {
  try {
    const q = (req.query.q || '').trim();
    const bookId = req.query.bookId;
    let query, params;
    
    if (bookId && q) {
      query = `SELECT c.id, c.title, b.title as book_title FROM chapters c JOIN books b ON c.book_id = b.id WHERE c.book_id = $1 AND LOWER(c.title) LIKE LOWER($2) ORDER BY c.title LIMIT 10`;
      params = [bookId, `%${q}%`];
    } else if (bookId) {
      query = `SELECT c.id, c.title, b.title as book_title FROM chapters c JOIN books b ON c.book_id = b.id WHERE c.book_id = $1 ORDER BY c.title LIMIT 10`;
      params = [bookId];
    } else if (q) {
      query = `SELECT c.id, c.title, b.title as book_title FROM chapters c JOIN books b ON c.book_id = b.id WHERE LOWER(c.title) LIKE LOWER($1) ORDER BY c.title LIMIT 10`;
      params = [`%${q}%`];
    } else {
      query = `SELECT c.id, c.title, b.title as book_title FROM chapters c JOIN books b ON c.book_id = b.id ORDER BY c.title LIMIT 10`;
      params = [];
    }
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error('Chapter search error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/submit', (req, res) => {
  res.render('submit', { success: false });
});

app.post('/submit', async (req, res) => {
  const userId = req.user?.id || req.user?.claims?.sub;
  if (!userId) {
    return res.redirect('/api/login');
  }

  const { submission_type, book_title, chapter_title, book_id, chapter_id, content, notes } = req.body;
  
  try {
    await pool.query(`
      INSERT INTO submissions (user_id, submission_type, book_title, chapter_title, book_id, chapter_id, content, notes)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    `, [
      userId, 
      submission_type, 
      book_title || null, 
      chapter_title || null, 
      book_id || null,
      chapter_id || null,
      content, 
      notes || null
    ]);

    res.render('submit', { success: true });
  } catch (err) {
    console.error('Submission error:', err);
    res.status(500).send('Error saving submission');
  }
});

app.get('/mod', requireRole(['admin', 'moderator']), async (req, res) => {
  try {
    const pendingCount = await pool.query("SELECT COUNT(*) FROM submissions WHERE status = 'pending'");
    const approvedCount = await pool.query("SELECT COUNT(*) FROM submissions WHERE status = 'approved'");
    const publishedCount = await pool.query("SELECT COUNT(*) FROM submissions WHERE status = 'published'");
    const rejectedCount = await pool.query("SELECT COUNT(*) FROM submissions WHERE status = 'rejected'");
    const recentSubmissions = await pool.query(`
      SELECT s.*, u.first_name, u.email 
      FROM submissions s 
      LEFT JOIN users u ON s.user_id = u.id 
      ORDER BY s.created_at DESC 
      LIMIT 10
    `);
    
    res.render('mod', {
      stats: {
        pending: parseInt(pendingCount.rows[0].count),
        approved: parseInt(approvedCount.rows[0].count),
        published: parseInt(publishedCount.rows[0].count),
        rejected: parseInt(rejectedCount.rows[0].count)
      },
      recentSubmissions: recentSubmissions.rows
    });
  } catch (err) {
    console.error('Mod panel error:', err);
    res.status(500).send('Server error');
  }
});

app.get('/moderate', requireRole(['admin', 'moderator']), async (req, res) => {
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

app.post('/moderate/:id/approve', requireRole(['admin', 'moderator']), async (req, res) => {
  const reviewerId = req.user?.id || req.user?.claims?.sub;
  const submissionId = parseInt(req.params.id, 10);
  
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // 1. Get full submission data
    const subResult = await client.query(`
      SELECT s.*, u.first_name, ui.display_name as discord_username
      FROM submissions s
      LEFT JOIN users u ON s.user_id = u.id
      LEFT JOIN user_identities ui ON s.user_id = ui.user_id AND ui.provider = 'discord'
      WHERE s.id = $1
    `, [submissionId]);
    
    if (subResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).send('Submission not found');
    }
    
    const submission = subResult.rows[0];
    const { submission_type, book_title, book_id, chapter_title, chapter_id, verse_number, content, notes, user_id } = submission;
    
    // Determine author name from submission
    const authorName = submission.discord_username || submission.first_name || 'Anonymous';
    
    let entityType = null;
    let entityId = null;
    
    // 2. Handle based on submission_type
    if (submission_type === 'verse') {
      // For verse: find or create book/chapter, then insert verse
      let finalBookId = book_id;
      let finalChapterId = chapter_id;
      
      // Find or create book if needed
      if (!finalBookId && book_title) {
        const existingBook = await client.query('SELECT id FROM books WHERE LOWER(title) = LOWER($1)', [book_title]);
        if (existingBook.rows.length > 0) {
          finalBookId = existingBook.rows[0].id;
        } else {
          const maxBookNum = await client.query('SELECT COALESCE(MAX(book_number), 0) + 1 as next_num FROM books');
          const newBook = await client.query(
            'INSERT INTO books (title, is_dynamic, book_number) VALUES ($1, 0, $2) RETURNING id',
            [book_title, maxBookNum.rows[0].next_num]
          );
          finalBookId = newBook.rows[0].id;
        }
      }
      
      // Find or create chapter if needed
      if (!finalChapterId && chapter_title && finalBookId) {
        const existingChapter = await client.query(
          'SELECT id FROM chapters WHERE book_id = $1 AND LOWER(title) = LOWER($2)',
          [finalBookId, chapter_title]
        );
        if (existingChapter.rows.length > 0) {
          finalChapterId = existingChapter.rows[0].id;
        } else {
          const slugBase = chapter_title.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '') || 'chapter';
          const filename = slugBase + '_' + Date.now();
          const maxChapNum = await client.query('SELECT COALESCE(MAX(chapter_number), 0) + 1 as next_num FROM chapters WHERE book_id = $1', [finalBookId]);
          const newChapter = await client.query(
            'INSERT INTO chapters (book_id, title, filename, created_at, chapter_number) VALUES ($1, $2, $3, $4, $5) RETURNING id',
            [finalBookId, chapter_title, filename, Math.floor(Date.now() / 1000), maxChapNum.rows[0].next_num]
          );
          finalChapterId = newChapter.rows[0].id;
        }
      }
      
      if (!finalChapterId) {
        throw new Error('Cannot create verse: no chapter specified or could not create chapter');
      }
      
      // Determine verse number
      let finalVerseNumber = verse_number;
      if (!finalVerseNumber) {
        const maxVerse = await client.query('SELECT COALESCE(MAX(verse_number), 0) + 1 as next_num FROM verses WHERE chapter_id = $1', [finalChapterId]);
        finalVerseNumber = maxVerse.rows[0].next_num;
      }
      
      // Insert verse
      const newVerse = await client.query(
        'INSERT INTO verses (chapter_id, verse_number, text) VALUES ($1, $2, $3) RETURNING id',
        [finalChapterId, finalVerseNumber, content]
      );
      entityType = 'verse';
      entityId = newVerse.rows[0].id;
      
    } else if (submission_type === 'chapter') {
      // For chapter: find or create book, create chapter, parse and insert verses
      let finalBookId = book_id;
      
      // Find or create book if needed
      if (!finalBookId && book_title) {
        const existingBook = await client.query('SELECT id FROM books WHERE LOWER(title) = LOWER($1)', [book_title]);
        if (existingBook.rows.length > 0) {
          finalBookId = existingBook.rows[0].id;
        } else {
          const maxBookNum = await client.query('SELECT COALESCE(MAX(book_number), 0) + 1 as next_num FROM books');
          const newBook = await client.query(
            'INSERT INTO books (title, is_dynamic, book_number) VALUES ($1, 0, $2) RETURNING id',
            [book_title, maxBookNum.rows[0].next_num]
          );
          finalBookId = newBook.rows[0].id;
        }
      }
      
      if (!finalBookId) {
        throw new Error('Cannot create chapter: no book specified or could not create book');
      }
      
      // Create chapter
      const chapterTitle = chapter_title || 'Untitled Chapter';
      const slugBase = chapterTitle.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '') || 'chapter';
      const filename = slugBase + '_' + Date.now();
      const maxChapNum = await client.query('SELECT COALESCE(MAX(chapter_number), 0) + 1 as next_num FROM chapters WHERE book_id = $1', [finalBookId]);
      
      const newChapter = await client.query(
        'INSERT INTO chapters (book_id, title, filename, created_at, chapter_number) VALUES ($1, $2, $3, $4, $5) RETURNING id',
        [finalBookId, chapterTitle, filename, Math.floor(Date.now() / 1000), maxChapNum.rows[0].next_num]
      );
      const newChapterId = newChapter.rows[0].id;
      
      // Parse content to extract verses (split by newlines or numbered patterns like "1." or "1:")
      const lines = content.split(/\n/).filter(line => line.trim());
      let nextVerseNum = 1;
      
      for (const line of lines) {
        let verseText = line.trim();
        let currentVerseNum;
        
        // Try to extract verse number from patterns like "1." or "1:" or "1)"
        const numberedMatch = verseText.match(/^(\d+)[.:)\s]+(.+)$/);
        if (numberedMatch) {
          currentVerseNum = parseInt(numberedMatch[1], 10);
          verseText = numberedMatch[2].trim();
          nextVerseNum = currentVerseNum + 1;
        } else {
          currentVerseNum = nextVerseNum;
          nextVerseNum++;
        }
        
        if (verseText) {
          await client.query(
            'INSERT INTO verses (chapter_id, verse_number, text) VALUES ($1, $2, $3)',
            [newChapterId, currentVerseNum, verseText]
          );
        }
      }
      
      entityType = 'chapter';
      entityId = newChapterId;
      
    } else if (submission_type === 'wisdom' || submission_type === 'quote') {
      // For wisdom/quote: insert into quotes table
      const newQuote = await client.query(
        'INSERT INTO quotes (text, author, source, created_at) VALUES ($1, $2, $3, $4) RETURNING id',
        [content, authorName, notes || null, Math.floor(Date.now() / 1000)]
      );
      entityType = 'quote';
      entityId = newQuote.rows[0].id;
      
    } else {
      throw new Error(`Unknown submission type: ${submission_type}`);
    }
    
    // 4. Track authorship - find or create author
    let authorId;
    const existingAuthor = await client.query(
      'SELECT id FROM authors WHERE name = $1',
      [authorName]
    );
    if (existingAuthor.rows.length > 0) {
      authorId = existingAuthor.rows[0].id;
    } else {
      const newAuthor = await client.query(
        'INSERT INTO authors (name, contact, role) VALUES ($1, $2, $3) RETURNING id',
        [authorName, user_id || null, 'contributor']
      );
      authorId = newAuthor.rows[0].id;
    }
    
    // Create revision record
    const revision = await client.query(
      'INSERT INTO revisions (entity_type, entity_id, revision_ts, author_id, note) VALUES ($1, $2, $3, $4, $5) RETURNING id',
      [entityType, entityId, Math.floor(Date.now() / 1000), authorId, `Approved submission #${submissionId}`]
    );
    
    // Link revision to author in revision_authors
    await client.query(
      'INSERT INTO revision_authors (revision_id, author_id) VALUES ($1, $2)',
      [revision.rows[0].id, authorId]
    );
    
    // 5. Update submission status to 'published'
    await client.query(`
      UPDATE submissions 
      SET status = 'published', reviewed_at = NOW(), reviewed_by = $1 
      WHERE id = $2
    `, [reviewerId, submissionId]);
    
    await client.query('COMMIT');
    console.log(`[Approval] Successfully published submission #${submissionId} as ${entityType} #${entityId}`);
    res.redirect('/moderate');
    
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Approval pipeline error:', err);
    
    // 6. Set status to 'error' with error message in notes
    try {
      await pool.query(`
        UPDATE submissions 
        SET status = 'error', 
            reviewed_at = NOW(), 
            reviewed_by = $1,
            notes = COALESCE(notes || E'\\n', '') || $2
        WHERE id = $3
      `, [reviewerId, `Error: ${err.message}`, submissionId]);
    } catch (updateErr) {
      console.error('Failed to update submission status to error:', updateErr);
    }
    
    res.status(500).send('Approval failed: ' + err.message);
  } finally {
    client.release();
  }
});

app.post('/moderate/:id/reject', requireRole(['admin', 'moderator']), async (req, res) => {
  const userId = req.user?.id || req.user?.claims?.sub;
  try {
    await pool.query(`
      UPDATE submissions 
      SET status = 'rejected', reviewed_at = NOW(), reviewed_by = $1 
      WHERE id = $2
    `, [userId, req.params.id]);
    res.redirect('/moderate');
  } catch (err) {
    console.error('Rejection error:', err);
    res.status(500).send('Server error');
  }
});

app.delete('/api/admin/verse/:id', requireRole(['admin']), async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM verses WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).send('Verse not found');
    console.log(`[Admin] Deleted verse #${req.params.id}`);
    res.send('OK');
  } catch (err) {
    console.error('Delete verse error:', err);
    res.status(500).send('Server error');
  }
});

app.delete('/api/admin/chapter/:id', requireRole(['admin']), async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM verses WHERE chapter_id = $1', [req.params.id]);
    await client.query('DELETE FROM chapter_morals WHERE chapter_id = $1', [req.params.id]);
    await client.query('DELETE FROM chapter_consequences WHERE chapter_id = $1', [req.params.id]);
    await client.query('DELETE FROM chapter_redemptions WHERE chapter_id = $1', [req.params.id]);
    await client.query('DELETE FROM chapter_tags WHERE chapter_id = $1', [req.params.id]);
    await client.query('DELETE FROM chapter_links WHERE chapter_id = $1', [req.params.id]);
    await client.query('DELETE FROM derived_books WHERE chapter_id = $1', [req.params.id]);
    const result = await client.query('DELETE FROM chapters WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).send('Chapter not found');
    }
    await client.query('COMMIT');
    console.log(`[Admin] Deleted chapter #${req.params.id} and all associated data`);
    res.send('OK');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Delete chapter error:', err);
    res.status(500).send('Server error');
  } finally {
    client.release();
  }
});

app.delete('/api/admin/book/:id', requireRole(['admin']), async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const chapters = await client.query('SELECT id FROM chapters WHERE book_id = $1', [req.params.id]);
    for (const ch of chapters.rows) {
      await client.query('DELETE FROM verses WHERE chapter_id = $1', [ch.id]);
      await client.query('DELETE FROM chapter_morals WHERE chapter_id = $1', [ch.id]);
      await client.query('DELETE FROM chapter_consequences WHERE chapter_id = $1', [ch.id]);
      await client.query('DELETE FROM chapter_redemptions WHERE chapter_id = $1', [ch.id]);
      await client.query('DELETE FROM chapter_tags WHERE chapter_id = $1', [ch.id]);
      await client.query('DELETE FROM chapter_links WHERE chapter_id = $1', [ch.id]);
      await client.query('DELETE FROM derived_books WHERE chapter_id = $1', [ch.id]);
    }
    await client.query('DELETE FROM chapters WHERE book_id = $1', [req.params.id]);
    await client.query('DELETE FROM derived_books WHERE book_id = $1', [req.params.id]);
    await client.query('DELETE FROM featured_starts WHERE book_id = $1', [req.params.id]);
    await client.query('DELETE FROM book_rules WHERE book_id = $1', [req.params.id]);
    const result = await client.query('DELETE FROM books WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).send('Book not found');
    }
    await client.query('COMMIT');
    console.log(`[Admin] Deleted book #${req.params.id} and all associated content`);
    res.send('OK');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Delete book error:', err);
    res.status(500).send('Server error');
  } finally {
    client.release();
  }
});

const PORT = process.env.PORT || 5000;

async function startServer() {
  console.log('Starting server...');
  console.log('  Views:', path.join(__dirname, 'views'));
  console.log('  Public:', path.join(__dirname, 'public'));
  console.log('  PORT:', PORT);
  console.log('  DATABASE_URL:', process.env.DATABASE_URL ? 'set' : 'NOT SET');

  try {
    await pool.query('SELECT 1');
    console.log('  Database: connected');
  } catch (err) {
    console.error('  Database: FAILED -', err.message);
  }

  await setupAuth();
  console.log('  Auth: configured');

  app.use((req, res) => {
    console.log(`[404] No route matched: ${req.method} ${req.path}`);
    res.status(404).send('Page not found');
  });

  app.listen(PORT, '0.0.0.0', () => console.log(`Server running at http://0.0.0.0:${PORT}`));
}

startServer().catch(err => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
