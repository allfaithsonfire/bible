import { Client, GatewayIntentBits } from 'discord.js';
import pg from 'pg';

const { Pool } = pg;

const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent] });

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

const DISCORD_TOKEN = process.env.DISCORD_TOKEN;
const CHANNEL_ID = process.env.DISCORD_CHANNEL_ID;
const POST_TIME_UTC = process.env.DISCORD_POST_TIME_UTC || '12:00';

async function postTodaysWord(channel) {
  const result = await pool.query('SELECT text FROM verses ORDER BY RANDOM() LIMIT 1');
  if (result.rows.length > 0) {
    channel.send(`📜 **Today's Word:**
${result.rows[0].text}`);
  }
}

async function postQuote(channel) {
  const result = await pool.query('SELECT text FROM quotes ORDER BY RANDOM() LIMIT 1');
  if (result.rows.length > 0) {
    channel.send(`💬 *${result.rows[0].text}*`);
  }
}

client.once('ready', async () => {
  console.log(`AllFaithsBot ready as ${client.user.tag}`);

  const now = new Date();
  const [hour, minute] = POST_TIME_UTC.split(':').map(Number);
  const msUntilPost = new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), hour, minute, 0, 0).getTime() - now.getTime();
  setTimeout(() => {
    const channel = client.channels.cache.get(CHANNEL_ID);
    if (channel) postTodaysWord(channel);
    setInterval(() => postTodaysWord(channel), 24 * 60 * 60 * 1000); // every 24h
  }, msUntilPost > 0 ? msUntilPost : 1000); // post soon if missed

  console.log('Bot scheduled for daily Word.');
});

client.on('messageCreate', async message => {
  if (!message.guild || message.author.bot) return;

  const cmd = message.content.trim().toLowerCase();
  if (cmd === '/word') {
    await postTodaysWord(message.channel);
  } else if (cmd === '/quote') {
    await postQuote(message.channel);
  }
});

client.login(DISCORD_TOKEN);
