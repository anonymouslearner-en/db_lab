--
-- Aufgabe 3: Extending Student Table
-- University Database Schema
--

-- Teil 1: Extending Student Table

-- ============================================================
-- ANSATZ 1: Nach Vorgabe
-- - VorlNr is stored as decimal (e.g., 1234.0)
-- - Inefficient: No type safety for VorlNr (any value can be inserted)
-- - No validation: Invalid VorlNr can be inserted
-- - Structure: {{Grade, VorlNr}, {Grade, VorlNr}, ...}
-- ============================================================
ALTER TABLE Studenten
ADD COLUMN Noten DECIMAL[][];
 

-- ============================================================
-- ANSATZ 2: With Custom Type (Better Solution)
-- - Type-safe: Grade as DECIMAL(2,1), VorlNr as INTEGER
-- - More readable structure with named fields
-- - However: Still no FK validation against Vorlesungen table
-- ============================================================
CREATE TYPE noten_eintrag AS (
    Note DECIMAL(2,1),
    VorlNr INTEGER
);

ALTER TABLE Studenten
ADD COLUMN Noten noten_eintrag[];


-- Teil 2: User Defined Function + View

-- ============================================================
-- User Defined Function: Durchschnitt
-- 
-- ============================================================
CREATE OR REPLACE FUNCTION durchschnitt(noten DECIMAL[][])
RETURNS DECIMAL AS $$
DECLARE
    summe DECIMAL := 0;
    anzahl INTEGER := 0;
    i INTEGER;
BEGIN
    IF noten IS NULL OR array_length(noten, 1) IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Durch alle Einträge iterieren und Noten summieren
    FOR i IN 1..array_length(noten, 1) LOOP
        summe := summe + noten[i][1];  -- Note ist das erste Element
        anzahl := anzahl + 1;
    END LOOP;
    
    RETURN ROUND(summe / anzahl, 2);
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- View: SemesterÜbersicht
--  (nach Vorgabe und Vorlage)
-- ============================================================
CREATE VIEW SUebersicht AS
SELECT MatrNr, Name, Semester, durchschnitt(Noten) AS Durchschnittsnote
FROM Studenten
ORDER BY Semester, Name;