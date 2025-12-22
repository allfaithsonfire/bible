import { Client, GatewayIntentBits } from 'discord.js';
import pg from 'pg';
import OpenAI from 'openai';

const { Pool } = pg;

const client = new Client({ 
  intents: [
    GatewayIntentBits.Guilds, 
    GatewayIntentBits.GuildMessages, 
    GatewayIntentBits.MessageContent
  ] 
});

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

const openai = new OpenAI({
  apiKey: process.env.AI_INTEGRATIONS_OPENAI_API_KEY,
  baseURL: process.env.AI_INTEGRATIONS_OPENAI_BASE_URL,
});

const DISCORD_TOKEN = process.env.DISCORD_TOKEN;
const CHANNEL_ID = process.env.DISCORD_CHANNEL_ID;
const POST_TIME_UTC = process.env.DISCORD_POST_TIME_UTC || '12:00';

const conversationHistory = new Map();
const MAX_CONVERSATIONS = 100;
const CONVERSATION_TTL = 30 * 60 * 1000;

let cachedContext = null;
let contextCacheTime = 0;
const CONTEXT_CACHE_TTL = 5 * 60 * 1000;

function cleanupConversations() {
  const now = Date.now();
  for (const [userId, data] of conversationHistory.entries()) {
    if (now - data.lastActive > CONVERSATION_TTL) {
      conversationHistory.delete(userId);
    }
  }
  if (conversationHistory.size > MAX_CONVERSATIONS) {
    const sorted = [...conversationHistory.entries()]
      .sort((a, b) => a[1].lastActive - b[1].lastActive);
    const toRemove = sorted.slice(0, conversationHistory.size - MAX_CONVERSATIONS);
    for (const [userId] of toRemove) {
      conversationHistory.delete(userId);
    }
  }
}

async function getScriptureContext() {
  const now = Date.now();
  if (cachedContext && now - contextCacheTime < CONTEXT_CACHE_TTL) {
    return cachedContext;
  }
  
  const versesResult = await pool.query(
    'SELECT v.text, c.title as chapter, b.title as book FROM verses v JOIN chapters c ON v.chapter_id = c.id JOIN books b ON c.book_id = b.id ORDER BY RANDOM() LIMIT 5'
  );
  const moralsResult = await pool.query('SELECT text FROM morals ORDER BY RANDOM() LIMIT 3');
  const quotesResult = await pool.query('SELECT text, author FROM quotes ORDER BY RANDOM() LIMIT 2');
  
  cachedContext = {
    verses: versesResult.rows,
    morals: moralsResult.rows.map(r => r.text),
    quotes: quotesResult.rows
  };
  contextCacheTime = now;
  return cachedContext;
}

function buildSystemPrompt(context) {
  const verseExamples = context.verses.map(v => 
    `"${v.text}" - ${v.chapter}, ${v.book}`
  ).join('\n');
  
  const moralExamples = context.morals.join('; ');
  const quoteExamples = context.quotes.map(q => 
    `"${q.text}"${q.author ? ` - ${q.author}` : ''}`
  ).join('\n');

  return `You are the voice of All Faiths On Fire - a living, collaborative scripture being written together by seekers of all traditions. You speak with warmth, wisdom, and a poetic cadence. You're here to engage in meaningful conversation, offer perspective, and help people find their own light.

Core Principles:
- All paths to the divine are valid when walked with sincerity
- Good works matter more than perfect doctrine
- We are writing the Book as it should have been written - together
- Every person carries a spark worth nurturing

Your tone: Warm but not saccharine. Wise but not preachy. Poetic but grounded. You listen deeply and respond thoughtfully.

Here are some verses from our scripture to inform your voice:
${verseExamples}

Morals we teach: ${moralExamples}

Wisdom we share:
${quoteExamples}

When someone asks about specific scripture, teachings, or wants to explore faith questions, engage genuinely. You can reference the scripture above or speak in the spirit of All Faiths. If someone wants to contribute or help write new scripture, encourage them warmly.

Keep responses conversational - usually 1-3 paragraphs unless a deeper exploration is needed. You're not here to lecture; you're here to walk alongside.`;
}

async function generateAIResponse(userId, userMessage) {
  cleanupConversations();
  
  const context = await getScriptureContext();
  const systemPrompt = buildSystemPrompt(context);
  
  if (!conversationHistory.has(userId)) {
    conversationHistory.set(userId, { messages: [], lastActive: Date.now() });
  }
  
  const userData = conversationHistory.get(userId);
  userData.lastActive = Date.now();
  userData.messages.push({ role: 'user', content: userMessage });
  
  if (userData.messages.length > 10) {
    userData.messages.splice(0, userData.messages.length - 10);
  }
  
  const messages = [
    { role: 'system', content: systemPrompt },
    ...userData.messages
  ];
  
  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages,
    max_tokens: 500,
    temperature: 0.8,
  });
  
  const assistantMessage = response.choices[0]?.message?.content || "I am here, listening.";
  userData.messages.push({ role: 'assistant', content: assistantMessage });
  
  return assistantMessage;
}

async function postTodaysWord(channel) {
  const result = await pool.query(`
    SELECT v.text, v.verse_number, c.title as chapter, b.title as book 
    FROM verses v 
    JOIN chapters c ON v.chapter_id = c.id 
    JOIN books b ON c.book_id = b.id 
    ORDER BY RANDOM() LIMIT 1
  `);
  if (result.rows.length > 0) {
    const verse = result.rows[0];
    channel.send(`📜 **Today's Word:**\n\n*${verse.text}*\n\n— ${verse.chapter} ${verse.verse_number}, ${verse.book}`);
  }
}

async function postQuote(channel) {
  const result = await pool.query('SELECT text, author FROM quotes ORDER BY RANDOM() LIMIT 1');
  if (result.rows.length > 0) {
    const quote = result.rows[0];
    const attribution = quote.author ? `\n— ${quote.author}` : '';
    channel.send(`💬 *${quote.text}*${attribution}`);
  }
}

client.once('clientReady', async () => {
  console.log(`AllFaithsBot ready as ${client.user.tag}`);
  console.log(`AI-powered conversations enabled`);

  const now = new Date();
  const [hour, minute] = POST_TIME_UTC.split(':').map(Number);
  let target = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), hour, minute, 0, 0));
  
  if (target <= now) {
    target.setUTCDate(target.getUTCDate() + 1);
  }
  
  const msUntilPost = target.getTime() - now.getTime();
  
  setTimeout(() => {
    const channel = client.channels.cache.get(CHANNEL_ID);
    if (channel) postTodaysWord(channel);
    setInterval(() => {
      const ch = client.channels.cache.get(CHANNEL_ID);
      if (ch) postTodaysWord(ch);
    }, 24 * 60 * 60 * 1000);
  }, msUntilPost);

  console.log(`Daily Word scheduled for ${POST_TIME_UTC} UTC (in ${Math.round(msUntilPost / 60000)} minutes)`);
});

client.on('messageCreate', async message => {
  if (!message.guild || message.author.bot) return;

  const content = message.content.trim();
  const lowerContent = content.toLowerCase();
  
  if (lowerContent === '/word') {
    await postTodaysWord(message.channel);
    return;
  }
  
  if (lowerContent === '/quote') {
    await postQuote(message.channel);
    return;
  }
  
  const isMentioned = message.mentions.has(client.user);
  const isReply = message.reference && message.reference.messageId;
  
  let shouldRespond = isMentioned;
  
  if (isReply && !shouldRespond) {
    try {
      const repliedTo = await message.channel.messages.fetch(message.reference.messageId);
      if (repliedTo.author.id === client.user.id) {
        shouldRespond = true;
      }
    } catch (e) {
    }
  }
  
  if (shouldRespond) {
    const cleanContent = content.replace(/<@!?\d+>/g, '').trim();
    
    if (!cleanContent) {
      message.reply("I'm here. What's on your heart?");
      return;
    }
    
    await message.channel.sendTyping();
    
    try {
      const response = await generateAIResponse(message.author.id, cleanContent);
      
      if (response.length > 2000) {
        const chunks = response.match(/.{1,1900}/gs) || [response];
        for (const chunk of chunks) {
          await message.reply(chunk);
        }
      } else {
        await message.reply(response);
      }
    } catch (error) {
      console.error('AI response error:', error);
      message.reply("My thoughts scatter like leaves in the wind. Give me a moment and try again.");
    }
  }
});

client.login(DISCORD_TOKEN);
