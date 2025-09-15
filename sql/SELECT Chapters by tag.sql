SELECT b.title AS book, c.title AS chapter
FROM chapters c
JOIN books b ON b.id=c.book_id
JOIN chapter_tags ct ON ct.chapter_id=c.id
JOIN tags t ON t.tag_id=ct.tag_id
WHERE t.tag_name='courage'
ORDER BY b.book_number, c.id;
