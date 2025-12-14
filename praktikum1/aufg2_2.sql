--
-- SQL Queries for Testing
-- Based on the test data from aufgabe2_1.sql
--

SET search_path = universitaet;

-- ============================================================
-- Query 1: Find all students (MatrNr) who attend the lecture "Ethik"
-- ============================================================

SELECT s.MatrNr
FROM Studenten s
JOIN hoeren h ON s.MatrNr = h.MatrNr
JOIN Vorlesungen v ON h.VorlNr = v.VorlNr
WHERE v.Titel = 'Ethik';

-- Result: MatrNr 28106 (Carnap), 29120 (Theophrastos)


-- ============================================================
-- Query 2: Which students have attended at least one lecture together 
-- with the student "Schopenhauer"? Output the names of these students 
-- without duplicates. Schopenhauer himself should not appear in the result.
-- ============================================================

SELECT DISTINCT s2.Name
FROM Studenten s1
JOIN hoeren h1 ON s1.MatrNr = h1.MatrNr
JOIN hoeren h2 ON h1.VorlNr = h2.VorlNr  -- Same lecture
JOIN Studenten s2 ON h2.MatrNr = s2.MatrNr
WHERE s1.Name = 'Schopenhauer'
AND s2.Name != 'Schopenhauer';  -- Exclude Schopenhauer himself

-- Result: Fichte, Theophrastos, Feuerbach
-- (All attended VorlNr 5001 "Grundzuege" together with Schopenhauer)

-- ============================================================
-- Query 3: Which students attend ALL lectures that Schopenhauer attends?
-- ============================================================

SELECT s.Name
FROM Studenten s
WHERE s.MatrNr IN (
    -- Students who attend all of Schopenhauer's lectures
    SELECT h.MatrNr
    FROM hoeren h
    WHERE h.VorlNr IN (
        -- Get all lectures Schopenhauer attends
        SELECT h2.VorlNr
        FROM hoeren h2
        JOIN Studenten s2 ON h2.MatrNr = s2.MatrNr
        WHERE s2.Name = 'Schopenhauer'
    )
    GROUP BY h.MatrNr
    HAVING COUNT(DISTINCT h.VorlNr) = (
        -- Count of Schopenhauer's lectures
        SELECT COUNT(*)
        FROM hoeren h3
        JOIN Studenten s3 ON h3.MatrNr = s3.MatrNr
        WHERE s3.Name = 'Schopenhauer'
    )
)
AND s.Name != 'Schopenhauer';  -- Exclude Schopenhauer himself

-- Result: Schopenhauer attends 5001 (Grundzuege) and 4052 (Logik)

-- ============================================================
-- Query 4: Which lectures (VorlNr is sufficient) have at least 
-- two other lectures as prerequisites?
-- ============================================================

SELECT Nachfolger AS VorlNr
FROM voraussetzen
GROUP BY Nachfolger
HAVING COUNT(*) >= 2;

-- Result: 5052 (Wissenschaftstheorie)
-- Prerequisites: 5043 (Erkenntnistheorie) and 5041 (Ethik)

-- ============================================================
-- Query 5: Output a descending sorted list of all lectures and the 
-- number of exams held per lecture 
-- ============================================================

SELECT v.VorlNr, COUNT(p.VorlNr) AS Anzahl
FROM Vorlesungen v
LEFT JOIN pruefen p ON v.VorlNr = p.VorlNr
GROUP BY v.VorlNr
ORDER BY Anzahl DESC;

-- Result:
-- 4630 | 1  (Schopenhauer's exam)
-- 5001 | 1  (Carnap's exam)
-- 5041 | 1  (Jonas's exam)
-- All other lectures | 0


-- ============================================================
-- Query 6: Find the professor(s) (output Name) with the most assistants.
-- ============================================================

SELECT p.Name
FROM Professoren p
JOIN Assistenten a ON p.PersNr = a.Boss
GROUP BY p.PersNr, p.Name
HAVING COUNT(*) = (
    -- Find the maximum number of assistants any professor has
    SELECT MAX(assistant_count)
    FROM (
        SELECT COUNT(*) AS assistant_count
        FROM Assistenten
        GROUP BY Boss
    ) AS counts
);

-- Result: Sokrates, Kopernikus
-- Sokrates (2125) has 2 assistants: Platon, Aristoteles
-- Kopernikus (2127) has 2 assistants: Rhetikus, Newton

-- ============================================================
-- Query 7: Which students attend ALL lectures?
-- ============================================================

SELECT s.Name
FROM Studenten s
JOIN hoeren h ON s.MatrNr = h.MatrNr
GROUP BY s.MatrNr, s.Name
HAVING COUNT(DISTINCT h.VorlNr) = (
    -- Total number of lectures in the database
    SELECT COUNT(*)
    FROM Vorlesungen
);

-- Result: EMPTY SET
-- Total lectures: 10
-- Maximum lectures attended by any student: Carnap with 4 lectures
-- No student attends all 10 lectures

-- ============================================================
-- Query 8: How many times was an exam graded with a 1 or 2?
-- ============================================================

SELECT COUNT(*) AS Anzahl
FROM pruefen
WHERE Note >= 1.0 AND Note < 3.0;

-- Result: 3
-- All three exams in our data have grades 1 or 2:
-- - Carnap: 1.0
-- - Jonas: 2.0
-- - Schopenhauer: 2.0

-- ============================================================
-- Query 9: Create an overview showing MatrNr and Name of students 
-- together with their average grade and the corresponding variance value.
-- ============================================================

SELECT s.MatrNr, 
       s.Name, 
       AVG(p.Note) AS Durchschnitt,
       VAR_POP(p.Note) AS Varianz
FROM Studenten s
JOIN pruefen p ON s.MatrNr = p.MatrNr
GROUP BY s.MatrNr, s.Name;

-- Result:
-- MatrNr | Name          | Durchschnitt | Varianz
-- ======================================================
-- 28106  | Carnap        | 1.0          | 0
-- 25403  | Jonas         | 2.0          | 0
-- 27550  | Schopenhauer  | 2.0          | 0
-- (Each student has only 1 exam, so variance is 0)

-- ============================================================
-- Query 10: Are there names of persons that appear in at least 
-- two different tables?
-- ============================================================

SELECT Name
FROM (
    SELECT Name FROM Studenten
    UNION ALL
    SELECT Name FROM Professoren
    UNION ALL
    SELECT Name FROM Assistenten
) AS all_names
GROUP BY Name
HAVING COUNT(*) >= 2;

-- Result: EMPTY SET

-- ============================================================
-- Query 11: Create an overview showing which lecture (VorlNr is sufficient) 
-- has which other lectures as direct or indirect prerequisites.
-- ============================================================

WITH RECURSIVE voraussetzungen_rekursiv AS (
    -- Base case: direct prerequisites
    SELECT Vorgaenger, Nachfolger
    FROM voraussetzen
    
    UNION
    
    -- Recursive case: indirect prerequisites
    -- If A is prerequisite of B, and B is prerequisite of C, then A is prerequisite of C
    SELECT v.Vorgaenger, vr.Nachfolger
    FROM voraussetzen v
    JOIN voraussetzungen_rekursiv vr ON v.Nachfolger = vr.Vorgaenger
)
SELECT Nachfolger AS VorlNr, Vorgaenger AS Voraussetzung
FROM voraussetzungen_rekursiv
ORDER BY Nachfolger, Vorgaenger;

-- Result (partial):
-- VorlNr | Voraussetzung
-- ========================
-- 5041   | 5001           (direct)
-- 5043   | 5001           (direct)
-- 5049   | 5001           (direct)
-- 5052   | 5001           (indirect: 5001→5041→5052 and 5001→5043→5052)
-- 5052   | 5041           (direct)
-- 5052   | 5043           (direct)
-- 5216   | 5001           (indirect: 5001→5041→5216)
-- 5216   | 5041           (direct)
-- 5259   | 5001           (indirect: 5001→5041→5052→5259 and 5001→5043→5052→5259)
-- 5259   | 5041           (indirect: 5041→5052→5259)
-- 5259   | 5043           (indirect: 5043→5052→5259)
-- 5259   | 5052           (direct)