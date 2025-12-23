# All Faiths On Fire - A Ministry of Good Works

## Overview
This is a collaborative, living scripture platform consisting of a website for browsing religious texts and an AI-powered Discord bot for community engagement. Discord is the primary platform for community building, with the website serving as a learning resource.

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
- Dual OAuth: Discord (production) / Replit (development)
- OpenAI (via Replit AI Integrations) for Discord bot conversations
- Discord.js for bot functionality

## Development Roadmap
See `ROADMAP.md` for the full feature roadmap with progress tracking.

## Discord-First Community
Discord is the primary community hub. The website directs users to join Discord:
- Main "Join Us on Discord" button in header links to https://discord.gg/4kypdCMsC5
- Sidebar prominently features Discord link
- Submission page encourages Discord for contributions

## Discord Bot Features
- **Slash Commands**:
  - `/submit` - Opens a modal to submit verses, chapters, or wisdom (saves to database)
  - `/word` - Posts a random scripture verse
  - `/quote` - Posts a wisdom quote
- **AI Conversations**: Responds when mentioned (@All Faiths) or replied to
- **Scripture Context**: AI responses informed by verses, morals, and quotes
- **Daily Word**: Posts random scripture at configured time (12:00 UTC default)
- **Welcome Messages**: New members receive DM with getting started info
- **Memory Management**: LRU-based cleanup, 100 conversations max, 30-min TTL

## Community Submissions
Members can submit scripture contributions via:
1. **Discord** (preferred): Use `/submit` command - opens modal form
2. **Website**: `/submit` form for logged-in users

All submissions go to moderation queue at `/moderate`

### Moderator Access
By default, all logged-in users can moderate. To restrict:
- Set `MODERATOR_IDS` environment variable with comma-separated user IDs
- Example: `MODERATOR_IDS=user123,user456`

## Running the Website
The website runs on port 5000:
```
cd website && npm start
```

## Running the Discord Bot
Required environment variables:
- `DISCORD_TOKEN` - Discord bot token
- `DISCORD_CHANNEL_ID` - Channel ID for daily posts
- `DISCORD_POST_TIME_UTC` - (Optional) Daily post time, defaults to "12:00"

Start with:
```
cd discordbot && npm start
```

## Database
PostgreSQL database (via DATABASE_URL) contains:
- `books`, `chapters`, `verses` - Scripture content
- `quotes` - Wisdom quotes
- `morals`, `consequences`, `redemptions` - Chapter metadata
- `users`, `sessions` - User accounts and sessions
- `submissions` - Community contributions (with discord_user_id, discord_username for Discord submissions)

## Deployment
Production uses **Reserved VM** deployment (required for Discord bot's WebSocket):
- **Build**: `cd website && npm install && cd ../discordbot && npm install`
- **Run**: `cd website && node server.js & cd discordbot && node bot.js`
- Custom domain: allfaithsonfire.org

### Important Deployment Notes
- **NEVER switch deployment types** (Static/Autoscale/VM) - this clears custom domain links and requires re-linking
- Reserved VM is required because the Discord bot needs persistent WebSocket connections
- The website and bot run together in the same VM

## Recent Changes
- December 2025: Added dual OAuth - Discord for production, Replit for development
- December 2025: Submit form autocomplete for existing books/chapters
- December 2025: Edit mode with dropdowns + book_id/chapter_id tracking
- December 2025: Fixed production deployment - switching deployment types clears custom domains
- December 2025: Made Discord the primary community path
- December 2025: Added /submit slash command with modal form
- December 2025: Added welcome messages for new Discord members
- December 2025: Added community submission system with moderation queue
- December 2025: Enhanced Discord bot with AI-powered conversations
