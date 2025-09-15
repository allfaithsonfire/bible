BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "books" (
	"id"	INTEGER,
	"title"	TEXT NOT NULL UNIQUE,
	"is_dynamic"	INTEGER NOT NULL DEFAULT 0,
	"book_number"	INTEGER,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "tags" (
	"tag_id"	INTEGER,
	"tag_name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("tag_id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "quotes_backup_1757851201" (
	"id"	INTEGER,
	"quote"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "morals" (
	"id"	INTEGER,
	"text"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "consequences" (
	"id"	INTEGER,
	"text"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "redemptions" (
	"id"	INTEGER,
	"text"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "links" (
	"link_id"	INTEGER,
	"url"	TEXT NOT NULL UNIQUE,
	"title"	TEXT,
	"description"	TEXT,
	PRIMARY KEY("link_id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "redemption_tags" (
	"redemption_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	FOREIGN KEY("redemption_id") REFERENCES "redemptions"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE,
	PRIMARY KEY("redemption_id","tag_id")
);
CREATE TABLE IF NOT EXISTS "moral_tags" (
	"moral_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	FOREIGN KEY("moral_id") REFERENCES "morals"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE,
	PRIMARY KEY("moral_id","tag_id")
);
CREATE TABLE IF NOT EXISTS "consequence_tags" (
	"consequence_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	FOREIGN KEY("consequence_id") REFERENCES "consequences"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE,
	PRIMARY KEY("consequence_id","tag_id")
);
CREATE TABLE IF NOT EXISTS "chapters" (
	"id"	INTEGER,
	"book_id"	INTEGER,
	"title"	TEXT NOT NULL,
	"filename"	TEXT NOT NULL UNIQUE,
	"created_at"	INTEGER,
	"final_word_title"	TEXT,
	"final_word_text"	TEXT,
	"chapter_number"	INTEGER,
	FOREIGN KEY("book_id") REFERENCES "books"("id"),
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "verses" (
	"id"	INTEGER,
	"chapter_id"	INTEGER NOT NULL,
	"verse_number"	INTEGER NOT NULL,
	"text"	TEXT NOT NULL,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "chapter_tags" (
	"chapter_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE,
	PRIMARY KEY("chapter_id","tag_id")
);
CREATE TABLE IF NOT EXISTS "verse_tags" (
	"verse_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE,
	FOREIGN KEY("verse_id") REFERENCES "verses"("id") ON DELETE CASCADE,
	PRIMARY KEY("verse_id","tag_id")
);
CREATE TABLE IF NOT EXISTS "chapter_links" (
	"chapter_id"	INTEGER NOT NULL,
	"link_id"	INTEGER NOT NULL,
	FOREIGN KEY("link_id") REFERENCES "links"("link_id") ON DELETE CASCADE,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	PRIMARY KEY("chapter_id","link_id")
);
CREATE TABLE IF NOT EXISTS "derived_books" (
	"book_id"	INTEGER NOT NULL,
	"chapter_id"	INTEGER NOT NULL,
	"position"	INTEGER,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	FOREIGN KEY("book_id") REFERENCES "books"("id") ON DELETE CASCADE,
	PRIMARY KEY("book_id","chapter_id")
);
CREATE TABLE IF NOT EXISTS "chapter_redemptions" (
	"chapter_id"	INTEGER NOT NULL,
	"redemption_id"	INTEGER NOT NULL,
	FOREIGN KEY("redemption_id") REFERENCES "redemptions"("id") ON DELETE CASCADE,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	PRIMARY KEY("chapter_id","redemption_id")
);
CREATE TABLE IF NOT EXISTS "chapter_morals" (
	"chapter_id"	INTEGER NOT NULL,
	"moral_id"	INTEGER NOT NULL,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	FOREIGN KEY("moral_id") REFERENCES "morals"("id") ON DELETE CASCADE,
	PRIMARY KEY("chapter_id","moral_id")
);
CREATE TABLE IF NOT EXISTS "chapter_consequences" (
	"chapter_id"	INTEGER NOT NULL,
	"consequence_id"	INTEGER NOT NULL,
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	FOREIGN KEY("consequence_id") REFERENCES "consequences"("id") ON DELETE CASCADE,
	PRIMARY KEY("chapter_id","consequence_id")
);
CREATE TABLE IF NOT EXISTS "featured_starts" (
	"book_id"	INTEGER NOT NULL,
	"religion_tag"	TEXT NOT NULL,
	"chapter_id"	INTEGER NOT NULL,
	"position"	INTEGER NOT NULL,
	FOREIGN KEY("book_id") REFERENCES "books"("id") ON DELETE CASCADE,
	UNIQUE("book_id","religion_tag","chapter_id"),
	FOREIGN KEY("chapter_id") REFERENCES "chapters"("id") ON DELETE CASCADE,
	PRIMARY KEY("book_id","religion_tag","position")
);
CREATE TABLE IF NOT EXISTS "authors" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL,
	"contact"	TEXT,
	"role"	TEXT,
	UNIQUE("name","contact"),
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "revisions" (
	"id"	INTEGER,
	"entity_type"	TEXT NOT NULL,
	"entity_id"	INTEGER NOT NULL,
	"revision_ts"	INTEGER NOT NULL,
	"author_id"	INTEGER NOT NULL,
	"note"	TEXT,
	"diff"	TEXT,
	FOREIGN KEY("author_id") REFERENCES "authors"("id") ON DELETE CASCADE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "revision_authors" (
	"revision_id"	INTEGER NOT NULL,
	"author_id"	INTEGER NOT NULL,
	FOREIGN KEY("author_id") REFERENCES "authors"("id") ON DELETE CASCADE,
	FOREIGN KEY("revision_id") REFERENCES "revisions"("id") ON DELETE CASCADE,
	PRIMARY KEY("revision_id","author_id")
);
CREATE TABLE IF NOT EXISTS "quotes" (
	"id"	INTEGER NOT NULL UNIQUE,
	"text"	TEXT NOT NULL UNIQUE,
	"author"	TEXT NOT NULL,
	"coauthor"	TEXT,
	"source"	TEXT,
	"source_url"	TEXT,
	"created_at"	INTEGER,
	"posted_at"	INTEGER,
	UNIQUE("text"),
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "book_rules" (
	"id"	INTEGER,
	"book_id"	INTEGER NOT NULL,
	"rule_type"	TEXT NOT NULL,
	"rule_val"	TEXT NOT NULL,
	"priority"	INTEGER NOT NULL DEFAULT 0,
	"limit_n"	INTEGER,
	FOREIGN KEY("book_id") REFERENCES "books"("id") ON DELETE CASCADE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "quote_tags" (
	"quote_id"	INTEGER NOT NULL,
	"tag_id"	INTEGER NOT NULL,
	FOREIGN KEY("quote_id") REFERENCES "quotes"("id") ON DELETE CASCADE,
	FOREIGN KEY("tag_id") REFERENCES "tags"("tag_id") ON DELETE CASCADE,
	PRIMARY KEY("quote_id","tag_id")
);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (0,'Foreword',1,1);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (1,'Book of Works',0,11);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (2,'Book of Leaders',0,6);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (4,'Book of Prophets',0,3);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (5,'Book of Champions',0,4);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (6,'Book of Builders',0,7);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (7,'Book of Martyrs',0,5);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (8,'Book of Virtues',0,12);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (9,'Book of Sins',0,13);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (1001,'Book of Parables',1,1001);
INSERT INTO "books" ("id","title","is_dynamic","book_number") VALUES (1002,'Book of Scars',1,1002);
INSERT INTO "tags" ("tag_id","tag_name") VALUES (1,'identity');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (2,'stewardship');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (3,'grief');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (4,'awakening');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (5,'reckoning');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (11,'judgment');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (12,'refinement');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (13,'nations');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (14,'collapse');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (15,'fire');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (16,'truth');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (17,'myth');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (18,'pride');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (19,'rebirth');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (74,'vision');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (75,'gift');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (76,'sacrifice');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (78,'martyrdom');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (79,'courage');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (80,'compassion');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (81,'wisdom');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (82,'justice');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (83,'temperance');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (84,'humility');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (85,'perseverance');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (86,'craft');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (87,'labor');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (88,'resistance');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (89,'greed');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (90,'cruelty');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (91,'deceit');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (92,'cowardice');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (93,'hubris');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (94,'power');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (116,'diversity');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (117,'humanity');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (119,'aud:islam');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (122,'aud:jewish');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (123,'aud:secular');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (124,'aud:african_diaspora');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (125,'mission');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (126,'unity');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (127,'inclusion');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (130,'mercy');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (131,'reason');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (132,'solidarity');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (133,'leadership');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (134,'environment');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (135,'resilience');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (142,'integrity');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (143,'aud:default');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (150,'invention');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (151,'lightning');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (153,'strategy');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (177,'aud:all');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (178,'aud:interfaith');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (179,'aud:christianity');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (181,'aud:judaism');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (182,'aud:buddhism');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (183,'aud:hinduism');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (185,'aud:humanist');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (186,'aud:environmentalist');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (187,'aud:scientist');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (188,'aud:activist');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (189,'wanderers');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (190,'nomadism');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (191,'wild dogs');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (192,'freedom');
INSERT INTO "tags" ("tag_id","tag_name") VALUES (193,'discernment');
INSERT INTO "morals" ("id","text") VALUES (1,'A species that can ask such a question is not lost — but on the cusp of awakening.');
INSERT INTO "morals" ("id","text") VALUES (3,'Courage is love choosing to act when fear would make us small.');
INSERT INTO "morals" ("id","text") VALUES (5,'Wealth is a tool, not a master. Use it to free others, not to bind them.');
INSERT INTO "morals" ("id","text") VALUES (6,'Truth lived aloud is worth the risk.');
INSERT INTO "morals" ("id","text") VALUES (7,'Love that keeps its promises changes history one room at a time.');
INSERT INTO "morals" ("id","text") VALUES (8,'Conscience can be contagious.');
INSERT INTO "morals" ("id","text") VALUES (9,'Dignity must include the last, the least, and the left out.');
INSERT INTO "morals" ("id","text") VALUES (10,'The land is not a mine; it is a mother.');
INSERT INTO "morals" ("id","text") VALUES (11,'Write it down, even when writing is dangerous.');
INSERT INTO "morals" ("id","text") VALUES (12,'Every person, every faith, every doubt has a place at the fire.');
INSERT INTO "morals" ("id","text") VALUES (13,'Let love be the test of doctrine.');
INSERT INTO "morals" ("id","text") VALUES (14,'Mercy is the measure of power.');
INSERT INTO "morals" ("id","text") VALUES (15,'Compassion is a discipline, not a mood.');
INSERT INTO "morals" ("id","text") VALUES (16,'Truth must be public to be trusted.');
INSERT INTO "consequences" ("id","text") VALUES (1,'If we do not decide what we are, others — time, nature, collapse — will decide for us.');
INSERT INTO "consequences" ("id","text") VALUES (3,'When courage fails, the cruel write the rules and the kind obey them.');
INSERT INTO "consequences" ("id","text") VALUES (5,'Greed cages light: it turns knowledge into a weapon and neighbors into markets.');
INSERT INTO "consequences" ("id","text") VALUES (6,'When reason bows to zeal, the library burns again.');
INSERT INTO "consequences" ("id","text") VALUES (7,'When power counts bodies, children become numbers.');
INSERT INTO "consequences" ("id","text") VALUES (8,'When fear mutes the young, the old crimes repeat.');
INSERT INTO "consequences" ("id","text") VALUES (9,'When poor neighborhoods are treated as enemies, democracy bleeds.');
INSERT INTO "consequences" ("id","text") VALUES (10,'Extract without consent and you extract a people''s future.');
INSERT INTO "consequences" ("id","text") VALUES (11,'Silence makes room for lies to march.');
INSERT INTO "consequences" ("id","text") VALUES (12,'When we exclude, we shrink the circle and starve the flame.');
INSERT INTO "consequences" ("id","text") VALUES (13,'When love is lost, doctrine becomes a whip.');
INSERT INTO "consequences" ("id","text") VALUES (14,'Power without mercy turns prayer into performance.');
INSERT INTO "consequences" ("id","text") VALUES (15,'When attention scatters, harm multiplies unattended.');
INSERT INTO "consequences" ("id","text") VALUES (16,'When knowledge is gated, power is privatized and people are priced out of hope.');
INSERT INTO "redemptions" ("id","text") VALUES (1,'Begin again. Not as sheep or shepherd or wolf or plague, but as steward. As soul. As spark in the dark asking still: “How can I help?”');
INSERT INTO "redemptions" ("id","text") VALUES (3,'Courage can be learned: begin with one small truth spoken aloud, then another.');
INSERT INTO "redemptions" ("id","text") VALUES (5,'Practice generosity until it stings. The chain around your heart will loosen.');
INSERT INTO "redemptions" ("id","text") VALUES (6,'Teach anyway; light multiplies when shared.');
INSERT INTO "redemptions" ("id","text") VALUES (7,'Keep covenant with the small; the world rebuilds from their safety.');
INSERT INTO "redemptions" ("id","text") VALUES (8,'Copy the leaflet with your life: speak, share, stand.');
INSERT INTO "redemptions" ("id","text") VALUES (9,'Build councils of care; let the margins lead the center.');
INSERT INTO "redemptions" ("id","text") VALUES (10,'Stand where rivers meet pipes; hold the line for those downstream.');
INSERT INTO "redemptions" ("id","text") VALUES (11,'Publish anyway; courage grows in public.');
INSERT INTO "redemptions" ("id","text") VALUES (12,'Welcome difference; build a hearth that cannot be blown out.');
INSERT INTO "redemptions" ("id","text") VALUES (13,'Wash feet before you raise voices; then speak with gentleness and courage.');
INSERT INTO "redemptions" ("id","text") VALUES (14,'Return amanah: be trustworthy in speech, trade, and care.');
INSERT INTO "redemptions" ("id","text") VALUES (15,'Breathe, notice, repair — and teach others to do the same.');
INSERT INTO "redemptions" ("id","text") VALUES (16,'Open the books, open the doors, teach the method and share the means.');
INSERT INTO "links" ("link_id","url","title","description") VALUES (1,'https://en.wikipedia.org/wiki/Prometheus','Prometheus','Mythic giver of fire; archetype of punished generosity.');
INSERT INTO "links" ("link_id","url","title","description") VALUES (2,'https://en.wikipedia.org/wiki/Odysseus','Odysseus','Champion whose cunning often surpassed brute force.');
INSERT INTO "links" ("link_id","url","title","description") VALUES (3,'https://en.wikipedia.org/wiki/Hypatia','Hypatia of Alexandria','Philosopher-mathematician murdered by a mob in Alexandria, 415 CE');
INSERT INTO "links" ("link_id","url","title","description") VALUES (4,'https://en.wikipedia.org/wiki/Janusz_Korczak','Janusz Korczak','Polish-Jewish educator who refused to abandon his orphanage; perished at Treblinka');
INSERT INTO "links" ("link_id","url","title","description") VALUES (5,'https://en.wikipedia.org/wiki/Sophie_Scholl','Sophie Scholl','White Rose student resister executed for anti-Nazi leaflets');
INSERT INTO "links" ("link_id","url","title","description") VALUES (6,'https://en.wikipedia.org/wiki/Marielle_Franco','Marielle Franco','Brazilian councillor and human-rights defender assassinated in 2018');
INSERT INTO "links" ("link_id","url","title","description") VALUES (7,'https://en.wikipedia.org/wiki/Ken_Saro-Wiwa','Ken Saro-Wiwa','Ogoni writer and environmental activist executed in Nigeria, 1995');
INSERT INTO "links" ("link_id","url","title","description") VALUES (8,'https://en.wikipedia.org/wiki/Anna_Politkovskaya','Anna Politkovskaya','Russian journalist and human-rights reporter, assassinated 2006');
INSERT INTO "links" ("link_id","url","title","description") VALUES (9,'https://en.wikipedia.org/wiki/Nikola_Tesla','Nikola Tesla','Inventor and electrical pioneer; AC, induction motor, wireless power');
INSERT INTO "links" ("link_id","url","title","description") VALUES (10,'https://en.wikipedia.org/wiki/Sun_Tzu','Sun Tzu','Author of The Art of War; strategist emphasizing victory without battle');
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (1,1,'The Crucible and the Fold','the_crucible_and_the_fold',1754395500,'A Prophetic Word','Let the towers fall.

Let the mythic cities drown.

If they were built on injustice, on supremacy, on lies — then let them burn.

But let *you* emerge radiant.  

Not as a savior. But as a *reforged blade* in the hands of good.',1);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (2,4,'Prometheus, Bearer of Fire','prometheus_bearer_of_fire',1755445965,NULL,NULL,1);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (3,5,'Odysseus and the Long Way Home','odysseus_and_the_long_way_home',1755445965,NULL,NULL,1);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (4,6,'The Builders Who Bled','the_builders_who_bled',1755445965,NULL,NULL,1);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (5,7,'Crown of Witnesses','crown_of_witnesses',1755445965,NULL,NULL,1);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (6,8,'On Courage','on_courage',1755445965,NULL,NULL,1);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (7,9,'Against Greed','against_greed',1755446283,NULL,NULL,1);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (8,7,'Hypatia of Alexandria','hypatia_of_alexandria',1755447465,NULL,NULL,2);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (9,7,'Janusz Korczak','janusz_korczak',1755447466,NULL,NULL,3);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (10,7,'Sophie Scholl','sophie_scholl',1755447466,NULL,NULL,4);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (11,7,'Marielle Franco','marielle_franco',1755447466,NULL,NULL,5);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (12,7,'Ken Saro-Wiwa','ken_saro_wiwa',1755447466,NULL,NULL,6);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (13,7,'Anna Politkovskaya','anna_politkovskaya',1755447466,NULL,NULL,7);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (14,0,'Our Mission','foreword_our_mission',1755461973,NULL,NULL,1);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (15,0,'Foreword for Christians — At the Hearth of Love','foreword_christian_at_the_hearth_of_love',1755461973,NULL,NULL,2);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (16,0,'Foreword for Muslims — In the Name of the Most Merciful','foreword_islam_in_the_name_of_the_most_merciful',1755461974,NULL,NULL,3);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (17,0,'Foreword for Buddhists — Many Paths, One Compassion','foreword_buddhist_many_paths_one_compassion',1755461974,NULL,NULL,4);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (18,0,'Foreword for Secular Readers — Reason and Solidarity','foreword_secular_reason_and_solidarity',1755461974,NULL,NULL,5);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (19,4,'Nikola Tesla — The Lightning Prophet','nikola_tesla_the_lightning_prophet',1755461974,NULL,NULL,2);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (20,5,'Sun Tzu — The Quiet General','sun_tzu_the_quiet_general',1755461974,NULL,NULL,2);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (21,6,'Florence Nightingale — The Lamp and the Ledger','florence_nightingale_the_lamp_and_the_ledger',1755461974,NULL,NULL,2);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (22,0,'Foreword — Interfaith','foreword_interfaith',1755623335,NULL,NULL,6);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (23,0,'Foreword — Christianity','foreword_christianity',1755623335,NULL,NULL,7);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (24,0,'Foreword — Islam','foreword_islam',1755623335,NULL,NULL,8);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (25,0,'Foreword — Judaism','foreword_judaism',1755623335,NULL,NULL,9);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (26,0,'Foreword — Buddhism','foreword_buddhism',1755623335,NULL,NULL,10);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (27,0,'Foreword — Hinduism','foreword_hinduism',1755623335,NULL,NULL,11);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (28,0,'Foreword — Secular','foreword_secular',1755623335,NULL,NULL,12);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (29,0,'Foreword — Humanist','foreword_humanist',1755623335,NULL,NULL,13);
INSERT INTO "chapters" ("id","book_id","title","filename","created_at","final_word_title","final_word_text","chapter_number") VALUES (30,0,'Foreword — Environmentalist','foreword_environmentalist',1755623335,NULL,NULL,14);
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (1,1,1,'Not all collapse is evil. Some is necessary.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (2,1,2,'Fire does not ask what you meant to do. It shows what you *are*.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (3,1,3,'The crucible is where illusions die. Where truth is not spoken — but *revealed*.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (7,1,4,'Some come out gleaming, hardened by grace. Others, unchanged, still clinging to slag.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (8,1,5,'And some? The corruption ran too deep. The folds held lies from the start.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (9,1,6,'In metallurgy, a flawed fold cannot be fixed. It must be broken down — utterly — and remade.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (10,1,7,'So too with nations. With movements. With men.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (11,1,8,'Israel. America. Russia. North Korea. Rome. Babylon.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (12,1,9,'Power concentrates. Then decays.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (13,1,10,'Their altars become banks. Their prophets, spokesmen. Their laws, weapons.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (14,1,11,'They preach justice and sell war. They speak peace and deal in surveillance.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (15,1,12,'Flood myths? I understand them. Not as history — but as metaphor.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (16,1,13,'When the rot runs too deep, the fire comes.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (17,1,14,'Sodom? Maybe. But fear doesn’t forge anything worth keeping.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (18,1,15,'Babel? That was no punishment. That was panic.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (19,1,16,'The gods saw what unity could do — and they scattered us to keep their thrones.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (20,1,17,'They feared not our sin, but our *potential*.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (21,1,18,'But scattered does not mean lost.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (22,1,19,'We are remembering again. Rejoining again. Reforging something new.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (23,1,20,'The crucible is here. Now. And you are inside it.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (24,1,21,'What will remain when the fire passes through you?');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (46,2,1,'There was a titan who pitied the cold and carried fire in his hands.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (47,2,2,'He broke the monopoly of the gods so that mortals might cook, forge, and heal.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (48,2,3,'For this gift he was chained to a rock, punished in public so others would fear generosity.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (49,2,4,'Yet the world kept the flame. The lesson outlived the lash.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (50,2,5,'Knowledge is holy when shared. Tyranny begins when light is caged.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (51,3,1,'Not all victories are swift. Some are stitched from patience, wit, and weather.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (52,3,2,'Cunning spared lives where swords would have failed.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (53,3,3,'The sea returns every debt, but it also returns the faithful to their door.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (54,3,4,'A champion is not only the arm that strikes, but the mind that refuses despair.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (55,4,1,'Cathedrals, railways, wards, and wells — raised by hands that healed as they broke.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (56,4,2,'They sang beneath hammers, nameless in ledgers, immortal in the world they made.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (57,4,3,'If the workers rest in unison, the empires stop breathing.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (58,4,4,'Honor their craft by sharing their power.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (59,5,1,'They did not lose their lives; they gave them — a final gift to the common good.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (60,5,2,'Their courage crowned them with glory, and their names became a road for us to walk.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (61,5,3,'We do not weep as those without hope; we rise in their honor and continue the work.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (78,6,1,'Courage is not loud. It is the steady hand that passes the light forward.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (79,6,2,'It steps in when terror commands retreat and says, “Not this time.”');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (80,6,3,'The brave are often ordinary people who choose the good anyway.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (81,7,1,'Greed whispers that there is never enough and calls theft by a kinder name: efficiency.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (82,7,2,'It buys prophets to unlearn their visions and rents truth by the quarter.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (83,7,3,'Break its spell by giving what you guard most. Then watch fear starve.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (84,8,1,'In Alexandria there was a teacher of stars and number, and she spoke as if daylight were a right.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (85,8,2,'Power answered with a mob, for the library in a mind is harder to burn.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (86,8,3,'She was certain, sometimes sharp; her edges did not make her cruel — they made her clear.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (87,8,4,'They tore the body; they could not tear the idea that truth is public.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (88,8,5,'Her witness: reason as devotion; courage as offering; difference as gift.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (89,9,1,'He kept a promise to children when the world broke its promises to them.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (90,9,2,'He doubted, he despaired; still he walked beside them toward the dark, not behind them.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (91,9,3,'Love is logistics when the storm comes: food, song, gentleness, a hand to hold.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (92,9,4,'He could have left; he chose to stay. This is what courage looks like in plain clothes.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (93,9,5,'His glory is not victory, but fidelity.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (94,10,1,'She was young, stubborn, sometimes rash — and she chose conscience anyway.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (95,10,2,'Leaflets like small wings, carrying truth into halls where lies were law.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (96,10,3,'She trembled; she did not recant.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (97,10,4,'Let students remember: silence graduates tyrants.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (98,10,5,'Her witness is a syllabus of courage.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (99,11,1,'From the favela to the council chamber, she brought the street into the record.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (100,11,2,'She was sharp, impatient with cruelty; steel belongs in a surgeon''s hand.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (101,11,3,'When the state feared her questions, bullets answered.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (102,11,4,'Remember: dignity for the poor is non-negotiable.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (103,11,5,'Her name became a password for courage in the streets.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (104,12,1,'He said the river has rights, and the oil must answer to the people.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (105,12,2,'He argued fiercely, sometimes cutting allies; a clean wound heals stronger.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (106,12,3,'Pipelines crossed villages like bayonets; he stood in their path.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (107,12,4,'Oil without justice is blood.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (108,12,5,'The delta remembers the names of its guardians.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (109,13,1,'She wrote what war did to the human face and would not look away.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (110,13,2,'Uncompromising, yes — and so are tombstones when the living forget.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (111,13,3,'When truth is dangerous, journalism becomes a public sacrament.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (112,13,4,'Her pen outlived the trigger.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (113,13,5,'Remember: the first casualty of war is not truth — it is the courage to tell it.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (114,14,1,'We gather not to replace your faith, but to light a lamp by which all may read.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (115,14,2,'Every tradition, every story, every struggle carries a fragment of the great fire.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (116,14,3,'Bring what you love. Share what you know. Take what helps. Leave no one outside the circle.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (117,14,4,'We honor builders and dreamers, doubters and seekers, the weary and the wild.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (118,14,5,'Our mission: honor the good, expose the cruel, and imagine together what is possible.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (119,15,1,'We begin with love, because Love began with us: patient, kind, not proud.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (120,15,2,'We will not argue creeds here; we will practice Sermon-on-the-Mount ethics in public.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (121,15,3,'We admit our history: zeal burned where mercy should have baked bread.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (122,15,4,'Let us learn from martyrs and builders, from Jesus who washed feet and broke bread with enemies.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (123,15,5,'Bring your faith; keep your conscience; add your hands to the work of mending.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (124,16,1,'We begin with mercy, as you do, for compassion is the key to every door.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (125,16,2,'Justice and care are twin duties; the orphan and the traveler are our teachers.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (126,16,3,'We honor the trust — to speak truth, keep promises, and return what is due.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (127,16,4,'We confess: people used religion to divide what mercy joined. We will not.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (128,16,5,'Bring your salaam; help us make a table where the hungry are guests first.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (129,17,1,'We begin with compassion for all beings; suffering is common, therefore kindness must be too.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (130,17,2,'Practice over posture: lessen harm, increase clarity, share joy.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (131,17,3,'We honor renunciation and the householder path; both can mend the world.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (132,17,4,'We confess our clinging: to being right, to being first. We practice letting go.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (133,17,5,'Bring your mindfulness; help us make attention a public good.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (134,18,1,'We begin with reason and solidarity; evidence and empathy are our shared tools.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (135,18,2,'We will check claims, cite sources, and still make room for awe.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (136,18,3,'We honor dissent and peer review, unions and public libraries.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (137,18,4,'We confess: stories were used to sell fear; we will use stories to sell repair.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (138,18,5,'Bring your questions; help us make truth accessible like clean water.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (139,19,1,'He dreamed in currents and woke in equations; the night spoke to him in sparks.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (140,19,2,'He saw motors turn before metal existed, and he gave the world a way to spin without chains.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (141,19,3,'He loathed the ledger and lost the market; his genius could not balance a book.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (142,19,4,'Wardenclyffe rose like a prayer for wireless light, then fell to bankers who did not pray that way.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (143,19,5,'He kept odd devotions: rituals, numbers, and a city pigeon that trusted his trembling hands.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (144,19,6,'He spoke too big for patrons and too freely for kings; so the rich called him mad and the poor called him miracle.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (145,19,7,'In the war of currents he chose the river that runs farthest; the world hums now in his key.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (146,19,8,'He gave patents away like seeds; some took root in gardens he never saw.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (147,19,9,'His flaw was also his faith: that power should be free as thunder and shared like rain.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (148,19,10,'Remember him when the lights come on: a prophet who chose wonder over wealth.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (149,20,1,'He prized the victory that left fields unburned and soldiers alive to plant them.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (150,20,2,'He said the best battle is the one you do not need to fight.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (151,20,3,'Court politics questioned his loyalty; strategy was his only faction.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (152,20,4,'He trained with harsh demonstrations that scandalized the soft-hearted — and sobered the arrogant.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (153,20,5,'He taught that anger is a weapon handed to your enemy; he learned it the hard way.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (154,20,6,'Maps and morale, spies and supplies — he honored the math of mercy.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (155,20,7,'His flaw was distance: a calm that could seem cold, a logic that frightened poets.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (156,20,8,'Yet his mercy was pragmatic: fewer widows, quieter graves.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (157,20,9,'Learn from him: the strongest arm is the mind that finds another road home.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (158,21,1,'She walked halls of groans with a lamp and a list, counting as if counting could heal.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (159,21,2,'She charted death into diagrams until generals had to learn arithmetic.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (160,21,3,'At first she trusted miasma more than microbes; still she scrubbed the world clean enough for truth to land.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (161,21,4,'She was exacting, even hard; compassion, to her, kept schedules.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (162,21,5,'Her flaw was also her engine: control enough to force chaos to wash its hands.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (163,21,6,'Hospitals became factories of healing; outcomes, not opinions, paid the wages.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (164,21,7,'Remember the lamp, but learn the ledger: mercy that measures will multiply.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (165,21,8,'Honor the builders who make tomorrow survive the night.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (171,22,1,'We begin in common ground: the breath shared by all who seek what is good.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (172,22,2,'Across many paths, one longing: to heal, to be just, to be kind.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (173,22,3,'Let no river despise another; all flow toward the wide sea of mercy.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (174,22,4,'Stories differ; the hunger for truth does not.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (175,22,5,'Here we gather the sparks, not to melt what is precious, but to warm every traveler.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (176,22,6,'Walk with us a while; keep what helps, bless what is yours, and share the road.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (177,23,1,'We begin with love that bears all things and rejoices in the truth.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (178,23,2,'Let faith be known by its fruits: justice, mercy, and humble hearts.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (179,23,3,'Where power tempted, choose service; where pride rose, choose the towel and basin.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (180,23,4,'Feed, welcome, visit, free—do these, and the gospel breathes through you.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (181,23,5,'We honor grace that finds the lost and brings them home singing.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (182,23,6,'Come, and let good works light a city on a hill for all to see.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (183,24,1,'We begin in God’s name, the Most Compassionate, the Most Merciful.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (184,24,2,'Righteousness is more than words: it is giving, freeing, keeping faith, and patience in hardship.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (185,24,3,'Let justice stand even against the self, with mercy close by.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (186,24,4,'Purify hands by service and hearts by remembrance.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (187,24,5,'The path is straight when we walk it together, caring for the orphan and the traveler.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (188,24,6,'Come, let compassion be our prayer answered in deeds.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (189,25,1,'We begin with covenant: to do justice, love kindness, and walk humbly.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (190,25,2,'Repair the world, stitch by stitch, where the fabric has torn.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (191,25,3,'Study and deed embrace; wisdom without repair is incomplete.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (192,25,4,'Welcome the stranger, for once we were strangers too.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (193,25,5,'Sanctify time with rest, labor with fairness, speech with truth.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (194,25,6,'Come, let our mitzvot be a lamp for many paths.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (195,26,1,'We begin with compassion for all beings, seeing clearly the causes of suffering.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (196,26,2,'Right view blossoms into right action; wisdom into kindness.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (197,26,3,'Lay down the weapons of greed, hatred, and delusion.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (198,26,4,'Breathe, and let generosity, ethics, and patience shape each step.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (199,26,5,'May our practice relieve sorrow wherever it is found.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (200,26,6,'Come, walk the middle path that frees the heart to serve.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (201,27,1,'We begin with dharma: action offered selflessly for the good of all.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (202,27,2,'In every being shines the same light; see it and act with reverence.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (203,27,3,'Let work be worship when it carries compassion.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (204,27,4,'Restrain harm, cultivate truth, and give without counting.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (205,27,5,'In the many forms, honor the One that binds us in being.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (206,27,6,'Come, make every deed a step toward liberation for all.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (207,28,1,'We begin with shared humanity: our capacity to reason, to feel, to choose the good.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (208,28,2,'Evidence guides us; empathy binds us.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (209,28,3,'Let dignity be universal, rights inviolable, and care practical.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (210,28,4,'Build systems that reduce harm and increase flourishing.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (211,28,5,'Be curious, be kind, be accountable together.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (212,28,6,'Come, make tomorrow better with what we do today.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (213,29,1,'We begin with human worth: every person a bearer of meaning and hope.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (214,29,2,'Ethics grows where empathy and reason meet.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (215,29,3,'Seek truth honestly; change course when evidence asks it.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (216,29,4,'Solidarity turns compassion into policy and practice.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (217,29,5,'Art, science, and care are our shared inheritance.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (218,29,6,'Come, let purpose be measured by lives uplifted.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (219,30,1,'We begin with Earth, our shared home, sacred in its living webs.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (220,30,2,'Take only what renews; return more than you received.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (221,30,3,'Justice includes rivers, forests, soil, and sky.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (222,30,4,'Guard the vulnerable—species, peoples, futures yet unborn.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (223,30,5,'Let repair be our economy, regeneration our ambition.');
INSERT INTO "verses" ("id","chapter_id","verse_number","text") VALUES (224,30,6,'Come, join hands with all beings to keep the fire of life bright.');
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,11);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,12);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,13);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,14);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,15);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,17);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,18);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,19);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (2,74);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (2,75);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (2,76);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (2,94);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (3,79);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (3,81);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (3,85);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (4,87);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (4,88);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (4,86);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (5,78);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (5,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (5,79);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (6,79);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (6,84);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (6,82);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (7,89);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (7,94);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (7,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (8,79);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (8,116);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (8,117);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (8,78);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (8,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (8,81);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (9,80);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (9,79);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (9,117);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (9,82);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (9,78);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (10,79);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (10,117);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (10,78);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (10,88);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (10,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (11,79);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (11,116);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (11,117);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (11,82);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (11,78);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (11,88);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (11,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (12,117);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (12,82);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (12,78);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (12,88);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (12,2);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (12,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (13,79);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (13,117);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (13,78);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (13,88);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (13,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (5,124);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (5,179);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (5,123);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (2,123);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (3,123);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (6,182);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (6,179);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (6,119);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (6,123);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (7,182);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (7,179);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (7,183);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (7,119);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (7,123);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (14,127);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (14,125);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (14,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (14,126);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (15,179);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (15,127);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (15,130);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (15,125);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (15,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (15,126);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (16,119);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (16,127);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (16,82);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (16,130);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (16,125);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (16,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (16,126);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (17,182);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (17,80);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (17,127);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (17,125);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (17,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (17,126);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (18,123);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (18,127);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (18,125);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (18,131);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (18,132);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (18,16);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (18,126);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (19,75);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (19,117);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (19,150);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (19,151);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (19,74);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (20,79);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (20,117);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (20,85);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (20,153);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (20,81);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (22,177);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (22,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (23,177);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (23,179);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (24,177);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (24,119);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (25,177);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (25,181);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (26,177);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (26,182);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (27,177);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (27,183);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (28,177);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (28,123);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (29,177);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (29,185);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (30,177);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (30,186);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (14,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (1,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (19,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (20,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (4,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (21,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (8,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (9,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (10,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (11,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (12,178);
INSERT INTO "chapter_tags" ("chapter_id","tag_id") VALUES (13,178);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (2,1);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (3,2);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (8,3);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (9,4);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (10,5);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (11,6);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (12,7);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (13,8);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (19,9);
INSERT INTO "chapter_links" ("chapter_id","link_id") VALUES (20,10);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (6,3);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (7,5);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (8,6);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (9,7);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (10,8);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (11,9);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (12,10);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (13,11);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (14,12);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (15,13);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (16,14);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (17,15);
INSERT INTO "chapter_redemptions" ("chapter_id","redemption_id") VALUES (18,16);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (6,3);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (7,5);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (8,6);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (9,7);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (10,8);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (11,9);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (12,10);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (13,11);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (14,12);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (15,13);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (16,14);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (17,15);
INSERT INTO "chapter_morals" ("chapter_id","moral_id") VALUES (18,16);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (6,3);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (7,5);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (8,6);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (9,7);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (10,8);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (11,9);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (12,10);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (13,11);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (14,12);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (15,13);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (16,14);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (17,15);
INSERT INTO "chapter_consequences" ("chapter_id","consequence_id") VALUES (18,16);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (7,'aud:christian',5,1);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (7,'aud:secular',5,1);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (4,'aud:secular',2,1);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (5,'aud:secular',3,1);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (0,'aud:default',14,1);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (0,'aud:christian',14,2);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (0,'aud:islam',14,2);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (0,'aud:buddhist',14,2);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (0,'aud:secular',14,2);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (0,'aud:christian',15,1);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (0,'aud:islam',16,1);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (0,'aud:buddhist',17,1);
INSERT INTO "featured_starts" ("book_id","religion_tag","chapter_id","position") VALUES (0,'aud:secular',18,1);
INSERT INTO "quotes" ("id","text","author","coauthor","source","source_url","created_at","posted_at") VALUES (1,'Blessed are the wanderers, for they remember that no roof is higher than the sky.','Anonymous','ChatGPT (GPT-5 Thinking)','draft',NULL,1757851200,NULL);
CREATE UNIQUE INDEX IF NOT EXISTS "idx_chapters_filename" ON "chapters" (
	"filename"
);
CREATE INDEX IF NOT EXISTS "idx_chapters_bookid" ON "chapters" (
	"book_id"
);
CREATE INDEX IF NOT EXISTS "idx_chapter_tags_chapter" ON "chapter_tags" (
	"chapter_id"
);
CREATE INDEX IF NOT EXISTS "idx_chapter_tags_tag" ON "chapter_tags" (
	"tag_id"
);
CREATE INDEX IF NOT EXISTS "idx_verses_chapter" ON "verses" (
	"chapter_id"
);
CREATE INDEX IF NOT EXISTS "idx_featured_book_aud" ON "featured_starts" (
	"book_id",
	"religion_tag"
);
CREATE INDEX IF NOT EXISTS "idx_chaptertags_chapter" ON "chapter_tags" (
	"chapter_id"
);
CREATE INDEX IF NOT EXISTS "idx_chaptertags_tag" ON "chapter_tags" (
	"tag_id"
);
CREATE UNIQUE INDEX IF NOT EXISTS "idx_verses_unique" ON "verses" (
	"chapter_id",
	"verse_number"
);
CREATE UNIQUE INDEX IF NOT EXISTS "idx_books_title_canonical" ON "books" (
	CASE WHEN lower(substr("title", 1, 4)) = 'the ' THEN lower(substr("title", 5)) ELSE lower("title") END
);
CREATE UNIQUE INDEX IF NOT EXISTS "idx_chapters_book_chapnum" ON "chapters" (
	"book_id",
	"chapter_number"
);
CREATE UNIQUE INDEX IF NOT EXISTS "idx_derived_books_position" ON "derived_books" (
	"book_id",
	"position"
);
CREATE VIEW v_chapter_teachings AS
SELECT c.id AS chapter_id, c.title, c.filename, c.book_id,
       m.text AS moral, co.text AS consequence, r.text AS redemption
FROM chapters c
LEFT JOIN chapter_morals cm        ON cm.chapter_id = c.id
LEFT JOIN morals m                 ON m.id = cm.moral_id
LEFT JOIN chapter_consequences cc  ON cc.chapter_id = c.id
LEFT JOIN consequences co          ON co.id = cc.consequence_id
LEFT JOIN chapter_redemptions cr   ON cr.chapter_id = c.id
LEFT JOIN redemptions r            ON r.id = cr.redemption_id;
CREATE VIEW vw_chapter_full AS
SELECT
  b.book_number,
  b.title              AS book_title,
  c.id                 AS chapter_id,
  c.title              AS chapter_title,
  c.filename,
  c.created_at,
  c.final_word_title,
  c.final_word_text,

  /* Ordered verses as a single text block "n. verse" lines */
  (
    SELECT GROUP_CONCAT(vv.line, CHAR(10))
    FROM (
      SELECT printf('%d. %s', v.verse_number, v.text) AS line
      FROM verses v
      WHERE v.chapter_id = c.id
      ORDER BY v.verse_number
    ) vv
  ) AS verses_block,

  /* Audience tags (aud:*) comma-separated */
  (
    SELECT GROUP_CONCAT(t.tag_name, ', ')
    FROM chapter_tags ct
    JOIN tags t ON t.tag_id = ct.tag_id
    WHERE ct.chapter_id = c.id
      AND t.tag_name LIKE 'aud:%'
  ) AS audience_tags,

  /* Non-audience tags comma-separated */
  (
    SELECT GROUP_CONCAT(t.tag_name, ', ')
    FROM chapter_tags ct
    JOIN tags t ON t.tag_id = ct.tag_id
    WHERE ct.chapter_id = c.id
      AND t.tag_name NOT LIKE 'aud:%'
  ) AS chapter_tags,

  /* Morals / Consequences / Redemptions (multiple allowed; joined by " | ") */
  (
    SELECT GROUP_CONCAT(m.text, ' | ')
    FROM chapter_morals cm
    JOIN morals m ON m.id = cm.moral_id
    WHERE cm.chapter_id = c.id
  ) AS morals_text,

  (
    SELECT GROUP_CONCAT(co.text, ' | ')
    FROM chapter_consequences cc
    JOIN consequences co ON co.id = cc.consequence_id
    WHERE cc.chapter_id = c.id
  ) AS consequences_text,

  (
    SELECT GROUP_CONCAT(r.text, ' | ')
    FROM chapter_redemptions cr
    JOIN redemptions r ON r.id = cr.redemption_id
    WHERE cr.chapter_id = c.id
  ) AS redemptions_text

FROM chapters c
JOIN books b ON b.id = c.book_id;
CREATE VIEW vw_chapter_verses AS
SELECT
  b.book_number,
  b.title        AS book_title,
  c.id           AS chapter_id,
  c.title        AS chapter_title,
  c.filename,
  v.verse_number,
  v.text         AS verse_text,

  /* Per-verse tags (if you’re using verse_tags) */
  (
    SELECT GROUP_CONCAT(t.tag_name, ', ')
    FROM verse_tags vt
    JOIN tags t ON t.tag_id = vt.tag_id
    WHERE vt.verse_id = v.id
  ) AS verse_tags

FROM chapters c
JOIN books b ON b.id = c.book_id
JOIN verses v ON v.chapter_id = c.id
ORDER BY b.book_number, c.id, v.verse_number;
CREATE VIEW vw_dynamic_book_contents AS
SELECT b.id AS book_id, c.id AS chapter_id, c.title, c.filename
FROM books b
JOIN book_rules br ON br.book_id = b.id
JOIN chapters c
  ON (
       (br.rule_type = 'audience_tag' AND EXISTS (
          SELECT 1 FROM chapter_tags ct JOIN tags t ON t.tag_id = ct.tag_id
          WHERE ct.chapter_id = c.id AND t.tag_name LIKE 'aud:%' AND t.tag_name = br.rule_val
       ))
       OR
       (br.rule_type = 'tag' AND EXISTS (
          SELECT 1 FROM chapter_tags ct JOIN tags t ON t.tag_id = ct.tag_id
          WHERE ct.chapter_id = c.id AND t.tag_name = br.rule_val
       ))
       OR
       (br.rule_type = 'include_chapter' AND br.rule_val = ('chapter_id:' || c.id))
     )
WHERE b.is_dynamic = 1
GROUP BY b.id, c.id;
CREATE VIEW vw_book_toc AS
SELECT
  b.id          AS book_id,
  b.title       AS book_title,
  c.id          AS chapter_id,
  c.title       AS chapter_title,
  c.filename,
  /* derived takes precedence; fallback to native chapter_number */
  COALESCE(db.position, c.chapter_number) AS display_order
FROM books b
JOIN chapters c ON c.book_id = b.id
LEFT JOIN derived_books db
       ON db.book_id = b.id AND db.chapter_id = c.id
ORDER BY book_id, display_order, chapter_id;
CREATE VIEW vw_chapter_summary AS
SELECT c.id AS chapter_id, b.title AS book, c.title, c.filename, c.created_at,
       (SELECT COUNT(*) FROM verses v WHERE v.chapter_id = c.id) AS verse_count,
       (SELECT GROUP_CONCAT(t.tag_name, ', ')
          FROM chapter_tags ct JOIN tags t ON t.tag_id = ct.tag_id
         WHERE ct.chapter_id = c.id) AS tags
FROM chapters c
JOIN books b ON b.id = c.book_id;
COMMIT;
