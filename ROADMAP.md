# All Faiths On Fire - Development Roadmap

This roadmap outlines the planned features and improvements for the platform.

---

## 0) Stabilize the spine (so everything else doesn't wobble)

### 0.1 Database health check
- [ ] Add a health check route (admin-only) that verifies:
  - Database connection
  - Basic counts (books/chapters/verses)
- [ ] App refuses to boot if DB can't be opened

**Done when:** A health page shows counts and the app refuses to boot if DB can't be opened.

---

## 1) Discord login (everyone has an identity)

### 1.1 OAuth: Discord sign-in
- [x] Add "Sign in with Discord" (production)
- [x] Replit OAuth for development
- [x] Store user record in `users` table:
  - id, discord_id (unique), username, avatar, created_at, last_login_at
- [x] Session cookie: httpOnly, secure, sameSite=lax

### 1.2 Roles
- [x] `users` table has `role` column (admin, moderator, author, reader)
- [x] Middleware: requireAuth, role checking via MODERATOR_IDS env var
- [ ] Formal `requireRole(['moderator','admin'])` middleware

**Done when:** Clicking "Contribute" forces login; after login you return to where you were; role gates work.

**Status:** Mostly complete - Discord OAuth configured, needs credentials in production.

---

## 2) Submission portal (the "write it into the fire" pipeline)

### 2.1 Submission data model
- [x] `submissions` table exists with:
  - id, type (chapter | verse | moral | consequence | redemption)
  - status (pending | approved | rejected)
  - content fields (book_title, chapter_title, verse_number, content)
  - user_id, discord_user_id, discord_username
  - created_at, reviewed_at, reviewed_by
  - review_note
  - book_id, chapter_id (for edits to existing content)
- [ ] Optional: submission_comments (mod discussion thread)

### 2.2 Submit UI
- [x] Submit form with book/chapter/verse fields
- [x] Autocomplete for existing books/chapters
- [x] Dropdown mode for editing existing content
- [x] Type selector (verse, chapter, moral, consequence, redemption)
- [ ] "New Chapter" form with full verse editor
- [ ] Morals / consequences / redemptions picker

### 2.3 Moderator queue
- [x] List view at `/moderate`
- [x] Filter by status
- [x] Approve / reject buttons
- [ ] "Request changes" option (keeps status=draft and adds note)
- [ ] Detail view: render payload as it would appear in scripture

### 2.4 Approval writes to canon
- [ ] Approval inserts into chapters + verses
- [ ] Insert into join tables: chapter_tags, chapter_links, chapter_morals, etc.
- [ ] Create a revisions row noting "Approved submission #X"

**Done when:** A moderator can approve a submission and it immediately appears in the reader + ToC.

**Status:** Partially complete - submission and moderation UI exist, approval-to-canon not yet implemented.

---

## 3) Teachings pane (Morals / Consequences / Redemptions shown every chapter)

Tables exist: `morals`, `consequences`, `redemptions` with join tables.

### 3.1 Reader UI: "Teachings" section
- [ ] At bottom of chapter show:
  - Morals
  - Consequences
  - Redemptions
- [ ] Support multiple entries per category

### 3.2 Linkouts
- [ ] Display links connected via chapter_links

**Done when:** Every chapter renders its attached moral/consequence/redemption + links (if present), cleanly.

---

## 4) Conversation (site-native reflections, Discord as identity)

### 4.1 Add reflections tables
- [ ] `reflection_threads` table:
  - id, chapter_id, verse_id nullable, created_by_user_id, created_at, is_locked
- [ ] `reflection_messages` table:
  - id, thread_id, user_id, prev_message_id nullable (threading)
  - message, created_at, edited_at, is_deleted
  - moderation_status (visible, held, removed), moderation_note

### 4.2 UI
- [ ] Button: "Reflect" on chapter
- [ ] Clicking a verse → shows "Reflect on Verse X"
- [ ] Thread view with replies (simple indentation)

### 4.3 Moderation tools
- [ ] Hold/remove message
- [ ] Lock thread
- [ ] Auto-hold first message from new accounts (optional)

**Done when:** Logged-in users can post reflections; mods can moderate; verse-level reflections exist.

---

## 5) Search and tags (so the scripture becomes usable at scale)

### 5.1 Search endpoint
- [ ] Search by:
  - Chapter title
  - Verse text
  - Tags
  - Morals/consequences/redemptions text
- [ ] Return grouped results with links to the chapter, and verse anchor if applicable

### 5.2 Tag browsing
- [ ] Click a tag → list chapters
- [ ] (Later) Tag cloud / "meditation map"

**Done when:** "search: courage" returns Courage chapter + other matching verses/teachings.

---

## 6) UX polish that makes it feel alive

### 6.1 Verse interactions
- [ ] Click verse → highlight + copy link (deep-link ?chapter=...#v12)
- [ ] Keyboard nav ← → between chapters
- [ ] Scroll-to-top button (both ToC pane and reader pane)

### 6.2 Theme selector
- [x] Multiple themes (light / dark / sepia / high contrast)
- [x] Theme picker UI with rounded buttons
- [x] Save to localStorage
- [ ] Optional: save to user profile

### 6.3 Fixed header + rotating quote
- [x] Random quotes from database (Discord bot uses this)
- [ ] Render quote under the title on website
- [ ] Optional daily cache using posted_at

**Done when:** It feels like a real reader, not a static blog.

**Status:** Theme selector complete. Other items pending.

---

## 7) Admin "tools of stewardship" (so you don't drown later)

### 7.1 Revisions viewer
- [ ] `revisions` table exists in DB
- [ ] Build admin page:
  - Filter by entity_type/entity_id
  - Show note + author + timestamp

### 7.2 Backups
- [ ] Admin button: "Download DB snapshot"
- [ ] Scheduled backup job (daily) to a safe location

**Done when:** You can undo mistakes and sleep better.

---

## 8) Hardening (because internet)

- [ ] Rate limit submit/reflection endpoints
- [ ] Basic HTML sanitization for reflections (no script tags)
- [ ] CSRF protection for form posts
- [ ] Audit logs for mod actions (simple table: who did what, when)

**Done when:** Trolls get bored.

---

## Summary of Current Status

| Phase | Status |
|-------|--------|
| 0. Database health | Not started |
| 1. Discord login | ~80% complete (needs prod credentials) |
| 2. Submission portal | ~50% complete (UI done, approval-to-canon pending) |
| 3. Teachings pane | Not started |
| 4. Conversations | Not started |
| 5. Search & tags | Not started |
| 6. UX polish | ~30% complete (themes done) |
| 7. Admin tools | Not started |
| 8. Hardening | Not started |

---

*Last updated: December 2025*
