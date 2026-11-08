-- Read-only audit for the stock schema. No subjects, bodies or account data.
-- Run before enabling generic-resource discussions. Do not auto-repair matches.
SELECT tbl, COUNT(*) AS messages, SUM(replyto=-1) AS threads
FROM messages GROUP BY tbl ORDER BY tbl;

SELECT m.uid, m.tbl, m.objectid, 'missing_or_unknown_parent' AS problem
FROM messages m
WHERE NOT (
 (m.tbl='objects' AND EXISTS (SELECT 1 FROM objects p WHERE p.uid=m.objectid)) OR
 (m.tbl='books' AND EXISTS (SELECT 1 FROM books p WHERE p.uid=m.objectid)) OR
 (m.tbl='papers' AND EXISTS (SELECT 1 FROM papers p WHERE p.uid=m.objectid)) OR
 (m.tbl='lec' AND EXISTS (SELECT 1 FROM lec p WHERE p.uid=m.objectid)) OR
 (m.tbl='forums' AND EXISTS (SELECT 1 FROM forums p WHERE p.uid=m.objectid)) OR
 (m.tbl='news' AND EXISTS (SELECT 1 FROM news p WHERE p.uid=m.objectid)) OR
 (m.tbl='polls' AND EXISTS (SELECT 1 FROM polls p WHERE p.uid=m.objectid)) OR
 (m.tbl='requests' AND EXISTS (SELECT 1 FROM requests p WHERE p.uid=m.objectid)) OR
 (m.tbl='corrections' AND EXISTS (SELECT 1 FROM corrections p WHERE p.uid=m.objectid)) OR
 (m.tbl='collab' AND EXISTS (SELECT 1 FROM collab p WHERE p.uid=m.objectid))
) OR m.tbl IS NULL;

SELECT m.uid, m.tbl, m.objectid, m.threadid, m.replyto, 'invalid_thread_or_reply' AS problem
FROM messages m
LEFT JOIN messages r ON r.uid=m.threadid
LEFT JOIN messages p ON p.uid=m.replyto
WHERE m.objectid IS NULL OR m.threadid IS NULL OR r.uid IS NULL
 OR r.replyto<>-1 OR r.replyto IS NULL OR r.threadid IS NULL OR r.threadid<>r.uid OR r.objectid IS NULL
 OR COALESCE(r.tbl,'')<>COALESCE(m.tbl,'') OR r.objectid<>m.objectid
 OR m.replyto IS NULL OR (m.replyto=-1 AND m.uid<>m.threadid)
 OR (m.replyto<>-1 AND (p.uid IS NULL OR p.uid=m.uid OR p.objectid IS NULL OR p.threadid IS NULL
 OR COALESCE(p.tbl,'')<>COALESCE(m.tbl,'') OR p.objectid<>m.objectid OR p.threadid<>m.threadid));

SELECT a.uid, a.tbl, a.objectid, a.replyto, 'two_message_cycle' AS problem
FROM messages a JOIN messages b ON b.uid=a.replyto
WHERE b.replyto=a.uid AND a.uid<b.uid;
