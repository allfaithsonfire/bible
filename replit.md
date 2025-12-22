# All Faiths On Fire - A Ministry of Good Works

## Overview
This is a collaborative, living scripture platform consisting of a website for browsing religious texts and an AI-powered Discord bot for community engagement. The project aims to create an inclusive spiritual resource where people can join, contribute, and engage with the community.

## Project Structure
- `website/` - Main Express.js web application
  - `server.js` - Express server with Replit Auth (OIDC)
  - `views/` - EJS templates
  - `public/` - Static assets (CSS, JS)
- `discordbot/` - AI-powered Discord bot
  - `bot.js` - Main bot with OpenAI integration
- `sql/` - SQL scripts and queries
- `bible/` - Static HTML chapters
- `img/` - Image assets

## Tech Stack
- Node.js 20
- Express.js with EJS templating
- PostgreSQL database (via pg client)
- Replit Auth (OpenID Connect) for user authentication
- OpenAI (via Replit AI Integrations) for Discord bot conversations

## Authentication
The website uses Replit Auth (OIDC) for user authentication:
- "Join Us" button in header allows users to sign in with Google, GitHub, Apple, or email
- User sessions stored in PostgreSQL (sessions table)
- User profiles stored in users table
- Uses SESSION_SECRET environment variable (auto-provided by Replit)

## Community Submissions
Members can submit their own scripture contributions:
- `/submit` - Submission form for verses, chapters, books, quotes, or edits
- `/moderate` - Moderation queue for reviewing pending submissions
- Submissions are stored with status (pending/approved/rejected)

### Moderator Access
By default, all logged-in users can access the moderation queue. To restrict access:
- Set `MODERATOR_IDS` environment variable with comma-separated user IDs
- Example: `MODERATOR_IDS=user123,user456`

## Running the Website
The website runs on port 5000. Start with:
```
cd website && npm start
```

## Running the Discord Bot
The Discord bot requires these environment variables:
- `DISCORD_TOKEN` - Discord bot token
- `DISCORD_CHANNEL_ID` - Channel ID for daily posts
- `DISCORD_POST_TIME_UTC` - (Optional) Time for daily posts, defaults to "12:00"

The bot uses Replit AI Integrations for OpenAI access (no API key needed).

Start with:
```
cd discordbot && npm start
```

### Bot Features
- **AI Conversations**: Responds when mentioned (@All Faiths) or when someone replies to it
- **Scripture Context**: AI responses are informed by verses, morals, and quotes from the database
- **Daily Word**: Posts a random scripture at the configured time (12:00 UTC default)
- **Commands**: `/word` for daily scripture, `/quote` for wisdom quotes
- **Memory Management**: LRU-based cleanup keeps 100 conversations max, 30-min TTL
- **Context Caching**: Scripture context cached for 5 minutes to reduce DB load

## Database
The PostgreSQL database (accessed via DATABASE_URL) contains:
- `books` - Scripture books
- `chapters` - Chapters within books
- `verses` - Individual verses with verse numbers
- `quotes` - Wisdom quotes for display
- `morals`, `consequences`, `redemptions` - Chapter metadata
- `users` - Registered user accounts
- `sessions` - User session storage
- `submissions` - Community scripture contributions (pending review)

## Deployment
Production deployment runs both website and Discord bot:
```
node website/server.js & node discordbot/bot.js
```

## Recent Changes
- December 2025: Added community submission system with moderation queue
- December 2025: Added Replit Auth (OIDC) for user authentication
- December 2025: Enhanced Discord bot with AI-powered conversations using OpenAI
- December 2025: Added memory management (LRU cleanup) and scripture context caching
- December 2025: Updated Discord bot to use PostgreSQL
- December 2025: Migrated from SQLite to PostgreSQL
