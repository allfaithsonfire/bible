SELECT b.id, b.book_number, b.title, is_dynamic, c.id AS chapter_id, c.chapter_number as chapter_number, c.title as chapter_title
FROM books b
JOIN chapters c ON c.id = b.id
ORDER BY b.book_number, c.chapter_number
