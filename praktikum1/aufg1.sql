--
-- Aufgabe 1: DDL Schema Creation
-- University Database Schema
--

-- Allows us to reference schema without schema prefix
CREATE SCHEMA universitaet;

SET search_path = universitaet;

-- ============================================================
-- PHASE 1: Create all tables with PRIMARY KEYS and basic constraints
-- (No FOREIGN KEYS yet to avoid circular dependencies)
-- ============================================================

CREATE TABLE Professoren (
    PersNr INTEGER PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Raum VARCHAR(10),  -- Room can be NULL (professor might not have assigned room yet)
    VVorl INTEGER NOT NULL  -- Every professor must be responsible for at least one lecture
);

CREATE TABLE Studenten (
    MatrNr INTEGER PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Semester INTEGER NOT NULL,
    CONSTRAINT chk_semester_positive CHECK (Semester > 0)
);

CREATE TABLE Vorlesungen (
    VorlNr INTEGER PRIMARY KEY,
    Titel VARCHAR(150) NOT NULL,
    SWS INTEGER NOT NULL,
    gelesenVon INTEGER NOT NULL,  -- Every lecture must have a professor (dozent)
    CONSTRAINT chk_sws_positive CHECK (SWS > 0)
);

CREATE TABLE Assistenten (
    PersNr INTEGER PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Fachgebiet VARCHAR(150) NOT NULL,
    Boss INTEGER NOT NULL  -- Every assistant must have a professor as supervisor
);

CREATE TABLE hoeren (
    MatrNr INTEGER NOT NULL,
    VorlNr INTEGER NOT NULL,
    PRIMARY KEY (MatrNr, VorlNr)
);

CREATE TABLE pruefen (
    MatrNr INTEGER NOT NULL,
    VorlNr INTEGER NOT NULL,
    PersNr INTEGER NOT NULL,
    Note DECIMAL(2,1) NOT NULL,  -- Allows grades like 1.0, 1.3, 1.7, 2.0, etc.
    PRIMARY KEY (MatrNr, VorlNr, PersNr),
    CONSTRAINT chk_note_range CHECK (Note >= 1.0 AND Note <= 5.0)
);

CREATE TABLE voraussetzen (
    Vorgaenger INTEGER NOT NULL,  
    Nachfolger INTEGER NOT NULL,  
    PRIMARY KEY (Vorgaenger, Nachfolger)
);

-- ============================================================
-- PHASE 2: Add FOREIGN KEY constraints (referential integrity)
-- ============================================================


-- Professoren.VVorl references Vorlesungen
-- Ensures: Every professor is responsible for at least one lecture
ALTER TABLE Professoren 
    ADD CONSTRAINT fk_prof_vvorl FOREIGN KEY (VVorl) 
    REFERENCES Vorlesungen(VorlNr);

-- Vorlesungen.gelesenVon references Professoren
-- Ensures: Every lecture has a professor as lecturer (dozent)
ALTER TABLE Vorlesungen 
    ADD CONSTRAINT fk_vorl_dozent FOREIGN KEY (gelesenVon) 
    REFERENCES Professoren(PersNr);


-- Assistenten.Boss references Professoren
-- Ensures: Every assistant has a professor as supervisor
ALTER TABLE Assistenten 
    ADD CONSTRAINT fk_assi_boss FOREIGN KEY (Boss) 
    REFERENCES Professoren(PersNr);

-- hoeren table: Students attend lectures
ALTER TABLE hoeren 
    ADD CONSTRAINT fk_hoeren_student FOREIGN KEY (MatrNr) 
    REFERENCES Studenten(MatrNr);

ALTER TABLE hoeren 
    ADD CONSTRAINT fk_hoeren_vorlesung FOREIGN KEY (VorlNr) 
    REFERENCES Vorlesungen(VorlNr);

-- pruefen table: Exam records
ALTER TABLE pruefen 
    ADD CONSTRAINT fk_pruefen_student FOREIGN KEY (MatrNr) 
    REFERENCES Studenten(MatrNr);

ALTER TABLE pruefen 
    ADD CONSTRAINT fk_pruefen_vorlesung FOREIGN KEY (VorlNr) 
    REFERENCES Vorlesungen(VorlNr);

-- Only professors can administer exams (pruefer)
ALTER TABLE pruefen 
    ADD CONSTRAINT fk_pruefen_pruefer FOREIGN KEY (PersNr) 
    REFERENCES Professoren(PersNr);

-- voraussetzen table: Lecture prerequisites (self-referencing)
-- A lecture (Nachfolger) can require another lecture (Vorgaenger) as prerequisite
ALTER TABLE voraussetzen 
    ADD CONSTRAINT fk_voraus_vorgaenger FOREIGN KEY (Vorgaenger) 
    REFERENCES Vorlesungen(VorlNr);

ALTER TABLE voraussetzen 
    ADD CONSTRAINT fk_voraus_nachfolger FOREIGN KEY (Nachfolger) 
    REFERENCES Vorlesungen(VorlNr);