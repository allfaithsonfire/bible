# All Faiths On Fire - A Ministry of Good Works

## Overview
This is a web application that displays religious texts organized into books, chapters, and verses. It uses a SQLite database (`allfaithsonfire.db`) to store the content.

## Project Structure
- `website/` - Main Express.js web application
  - `server.js` - Express server entry point
  - `views/` - EJS templates
  - `public/` - Static assets (CSS, JS)
- `discordbot/` - Discord bot (separate component)
- `sql/` - SQL scripts and queries
- `bible/` - Static HTML chapters
- `img/` - Image assets

## Tech Stack
- Node.js 20
- Express.js with EJS templating
- better-sqlite3 for database access
- SQLite database

## Running Locally
The website runs on port 5000. Start with:
```
cd website && npm start
```

## Database
The SQLite database contains:
- Books and chapters with hierarchical organization
- Verses with verse numbers
- Quotes for display
- Tags, morals, consequences, and redemptions for chapters
