import { Client, GatewayIntentBits, REST, Routes, SlashCommandBuilder, ModalBuilder, TextInputBuilder, TextInputStyle, ActionRowBuilder } from 'discord.js';
import pg from 'pg';
import OpenAI from 'openai';

const { Pool } = pg;

const client = new Client({ 
  intents: [
    GatewayIntentBits.Guilds, 
    GatewayIntentBits.GuildMessages, 
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.GuildMembers
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

const commands = [
  new SlashCommandBuilder()
    .setName('submit')
    .setDescription('Submit a verse, chapter, or wisdom to the living scripture'),
  new SlashCommandBuilder()
    .setName('word')
    .setDescription('Receive today\'s word from the scripture'),
  new SlashCommandBuilder()
    .setName('quote')
    .setDescription('Receive a wisdom quote')
].map(cmd => cmd.toJSON());

async function registerCommands() {
  const rest = new REST({ version: '10' }).setToken(DISCORD_TOKEN);
  try {
    console.log('Registering slash commands...');
    await rest.put(
      Routes.applicationCommands(client.user.id),
      { body: commands }
    );
    console.log('Slash commands registered');
  } catch (error) {
    console.error('Error registering commands:', error);
  }
}

client.once('ready', async () => {
  console.log(`AllFaithsBot ready as ${client.user.tag}`);
  console.log(`AI-powered conversations enabled`);
  
  await registerCommands();

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

client.on('guildMemberAdd', async member => {
  try {
    await member.send(`Welcome to **All Faiths On Fire**, ${member.user.username}! 🔥

We're a community writing the Book as it should have been written — together.

**Get started:**
• Say hello in the server and introduce yourself
• Use \`/submit\` to contribute your own verses or wisdom
• Use \`/word\` for daily scripture, \`/quote\` for wisdom
• Mention me anytime you want to talk about faith, life, or the scripture

The fire recognizes its own. We're glad you're here.

**Explore the scripture:** https://allfaithsonfire.replit.app`);
  } catch (error) {
    console.log('Could not DM new member:', member.user.username);
  }
});

client.on('interactionCreate', async interaction => {
  if (interaction.isChatInputCommand()) {
    const { commandName } = interaction;
    
    if (commandName === 'submit') {
      const modal = new ModalBuilder()
        .setCustomId('submitModal')
        .setTitle('Submit to the Living Scripture');
      
      const typeInput = new TextInputBuilder()
        .setCustomId('submissionType')
        .setLabel('What are you submitting?')
        .setPlaceholder('verse, chapter, book, or quote')
        .setStyle(TextInputStyle.Short)
        .setRequired(true);
      
      const titleInput = new TextInputBuilder()
        .setCustomId('bookTitle')
        .setLabel('Book/Chapter Title (if applicable)')
        .setPlaceholder('e.g., Book of Dawn, The First Light...')
        .setStyle(TextInputStyle.Short)
        .setRequired(false);
      
      const contentInput = new TextInputBuilder()
        .setCustomId('content')
        .setLabel('Your Words')
        .setPlaceholder('Write your verse, chapter, or wisdom here...')
        .setStyle(TextInputStyle.Paragraph)
        .setRequired(true);
      
      const notesInput = new TextInputBuilder()
        .setCustomId('notes')
        .setLabel('Notes (optional)')
        .setPlaceholder('Any context or inspiration...')
        .setStyle(TextInputStyle.Paragraph)
        .setRequired(false);
      
      modal.addComponents(
        new ActionRowBuilder().addComponents(typeInput),
        new ActionRowBuilder().addComponents(titleInput),
        new ActionRowBuilder().addComponents(contentInput),
        new ActionRowBuilder().addComponents(notesInput)
      );
      
      await interaction.showModal(modal);
    }
    
    if (commandName === 'word') {
      await interaction.deferReply();
      const result = await pool.query(`
        SELECT v.text, v.verse_number, c.title as chapter, b.title as book 
        FROM verses v 
        JOIN chapters c ON v.chapter_id = c.id 
        JOIN books b ON c.book_id = b.id 
        ORDER BY RANDOM() LIMIT 1
      `);
      if (result.rows.length > 0) {
        const verse = result.rows[0];
        await interaction.editReply(`📜 **Today's Word:**\n\n*${verse.text}*\n\n— ${verse.chapter} ${verse.verse_number}, ${verse.book}`);
      } else {
        await interaction.editReply('The scripture rests quietly. Check back soon.');
      }
    }
    
    if (commandName === 'quote') {
      await interaction.deferReply();
      const result = await pool.query('SELECT text, author FROM quotes ORDER BY RANDOM() LIMIT 1');
      if (result.rows.length > 0) {
        const quote = result.rows[0];
        const attribution = quote.author ? `\n— ${quote.author}` : '';
        await interaction.editReply(`💬 *${quote.text}*${attribution}`);
      } else {
        await interaction.editReply('Wisdom gathers in silence. Check back soon.');
      }
    }
  }
  
  if (interaction.isModalSubmit() && interaction.customId === 'submitModal') {
    const submissionType = interaction.fields.getTextInputValue('submissionType').toLowerCase();
    const bookTitle = interaction.fields.getTextInputValue('bookTitle') || null;
    const content = interaction.fields.getTextInputValue('content');
    const notes = interaction.fields.getTextInputValue('notes') || null;
    const discordId = interaction.user.id;
    const discordName = interaction.user.username;
    
    try {
      await pool.query(`
        INSERT INTO submissions (user_id, submission_type, book_title, content, notes, status, discord_user_id, discord_username)
        VALUES (NULL, $1, $2, $3, $4, 'pending', $5, $6)
      `, [submissionType, bookTitle, content, notes, discordId, discordName]);
      
      await interaction.reply({
        content: `🔥 **Your words have been received.**\n\nThank you, ${interaction.user.username}. Your submission will be reviewed by the community with care. The fire recognizes its own.`,
        ephemeral: true
      });
    } catch (error) {
      console.error('Submission error:', error);
      await interaction.reply({
        content: 'Something went awry. Please try again, seeker.',
        ephemeral: true
      });
    }
  }
});

client.login(DISCORD_TOKEN);
