--
-- Aufgabe 3: Query Optimization with Indexes
-- Analyzing and optimizing Query 3 from Aufgabe 2
--

SET search_path = universitaet;

-- ============================================================
-- ORIGINAL QUERY 3 (Before Optimization)
-- ============================================================
-- Query: Which students attend ALL lectures that Schopenhauer attends?

-- Step 1: Analyze the query BEFORE creating index
-- ============================================================

EXPLAIN ANALYZE
SELECT s.Name
FROM Studenten s
WHERE s.MatrNr IN (
    SELECT h.MatrNr
    FROM hoeren h
    WHERE h.VorlNr IN (
        SELECT h2.VorlNr
        FROM hoeren h2
        JOIN Studenten s2 ON h2.MatrNr = s2.MatrNr
        WHERE s2.Name = 'Schopenhauer'
    )
    GROUP BY h.MatrNr
    HAVING COUNT(DISTINCT h.VorlNr) = (
        SELECT COUNT(*)
        FROM hoeren h3
        JOIN Studenten s3 ON h3.MatrNr = s3.MatrNr
        WHERE s3.Name = 'Schopenhauer'
    )
)
AND s.Name != 'Schopenhauer';

-- ============================================================
-- PERFORMANCE ANALYSIS
-- ============================================================
-- Problems identified:
-- 1. Sequential scan on Studenten table filtering by Name (no index on Name)
-- 2. Multiple scans of hoeren table
-- 3. Repeated filtering on Studenten.Name = 'Schopenhauer' (appears twice)
--
-- Solution: Create indexes on:
-- - Studenten.Name (for WHERE s.Name = 'Schopenhauer' lookups)
-- - hoeren.VorlNr (for faster joins and subquery lookups)

-- ============================================================
-- CREATE INDEXES
-- ============================================================

-- Index 1: Speed up lookups by student name
CREATE INDEX idx_studenten_name ON Studenten(Name);

-- Index 2: Speed up joins on hoeren.VorlNr
CREATE INDEX idx_hoeren_vorlnr ON hoeren(VorlNr);

-- Index 3: Speed up joins on hoeren.MatrNr (may already be fast due to small table, but helps)
CREATE INDEX idx_hoeren_matrnr ON hoeren(MatrNr);

-- ============================================================
-- Step 2: Analyze the query AFTER creating indexes
-- ============================================================

EXPLAIN ANALYZE
SELECT s.Name
FROM Studenten s
WHERE s.MatrNr IN (
    SELECT h.MatrNr
    FROM hoeren h
    WHERE h.VorlNr IN (
        SELECT h2.VorlNr
        FROM hoeren h2
        JOIN Studenten s2 ON h2.MatrNr = s2.MatrNr
        WHERE s2.Name = 'Schopenhauer'
    )
    GROUP BY h.MatrNr
    HAVING COUNT(DISTINCT h.VorlNr) = (
        SELECT COUNT(*)
        FROM hoeren h3
        JOIN Studenten s3 ON h3.MatrNr = s3.MatrNr
        WHERE s3.Name = 'Schopenhauer'
    )
)
AND s.Name != 'Schopenhauer';

-- ============================================================
-- IMPROVEMENTS
-- ============================================================
-- 1. Index Scan instead of Sequential Scan on Studenten.Name
-- 2. Faster lookups in hoeren table using VorlNr index
-- 3. Reduced execution time overall