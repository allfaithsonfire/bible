# All Faiths On Fire - A Ministry of Good Works

## Overview
This is a web application that displays religious texts organized into books, chapters, and verses. It uses PostgreSQL for data storage.

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
- PostgreSQL database (via pg client)

## Running Locally
The website runs on port 5000. Start with:
```
cd website && npm start
```

## Database
The PostgreSQL database (accessed via DATABASE_URL) contains:
- Books and chapters with hierarchical organization
- Verses with verse numbers
- Quotes for display
- Tags, morals, consequences, and redemptions for chapters

## Recent Changes
- December 2025: Migrated from SQLite to PostgreSQL
