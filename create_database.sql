-- Creazione database
DROP DATABASE IF EXISTS smart_city;
CREATE DATABASE smart_city;

-- Seleziona il database
USE smart_city;

-- Creazione tabelle
CREATE TABLE Zona (
    idZona INT AUTO_INCREMENT,
    nomeZona VARCHAR(50) NOT NULL,
    descrizione VARCHAR(255),
    PRIMARY KEY (idZona),
    UNIQUE (nomeZona)
);

CREATE TABLE Tipo_Rifiuto (
    idTipoRifiuto INT AUTO_INCREMENT,
    nome VARCHAR(40) NOT NULL,
    descrizione VARCHAR(255),
    PRIMARY KEY (idTipoRifiuto),
    UNIQUE (nome)
);

CREATE TABLE Cassonetto (
    idCassonetto INT AUTO_INCREMENT,
    capacitaKg DECIMAL(8,2) NOT NULL CHECK (capacitaKg > 0),
    coordinate VARCHAR(30) NOT NULL,
    idZona INT NOT NULL,
    idTipoRifiuto INT NOT NULL,
    PRIMARY KEY (idCassonetto),
    UNIQUE (coordinate),
    FOREIGN KEY (idZona) REFERENCES Zona(idZona),
    FOREIGN KEY (idTipoRifiuto) REFERENCES Tipo_Rifiuto(idTipoRifiuto)
);

CREATE TABLE Unita_Organizzativa (
    idUnita INT AUTO_INCREMENT,
    nomeUnita VARCHAR(60) NOT NULL,
    PRIMARY KEY (idUnita),
    UNIQUE (nomeUnita)
);

CREATE TABLE Operatore (
    idOperatore INT AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL,
    cognome VARCHAR(50) NOT NULL,
    ruolo VARCHAR(50) NOT NULL,
    costoOrario DECIMAL(8,2) NOT NULL CHECK (costoOrario > 0),
    idUnita INT NOT NULL,
    PRIMARY KEY (idOperatore),
    FOREIGN KEY (idUnita) REFERENCES Unita_Organizzativa(idUnita)
);

CREATE TABLE Mezzo (
    idMezzo INT AUTO_INCREMENT,
    targa VARCHAR(15) NOT NULL,
    tipoMezzo VARCHAR(50) NOT NULL,
    capacitaKg DECIMAL(10,2) NOT NULL CHECK (capacitaKg > 0),
    costoOrario DECIMAL(8,2) NOT NULL CHECK (costoOrario > 0),
    idUnita INT NOT NULL,
    PRIMARY KEY (idMezzo),
    UNIQUE (targa),
    FOREIGN KEY (idUnita) REFERENCES Unita_Organizzativa(idUnita)
);

CREATE TABLE Turno (
    idTurno INT AUTO_INCREMENT,
    inizio TIME NOT NULL,
    fine TIME NOT NULL,
    PRIMARY KEY (idTurno),
    CHECK (inizio < fine)
);

CREATE TABLE Giro_Raccolta (
    idGiro INT AUTO_INCREMENT,
    data DATE NOT NULL,
    priorita INT NOT NULL,
    stato VARCHAR(30) NOT NULL,
    durataStimataMin INT NOT NULL CHECK (durataStimataMin > 0),
    idZona INT NOT NULL,
    idTurno INT NOT NULL,
    idOperatore INT NOT NULL,
    idMezzo INT NOT NULL,
    PRIMARY KEY (idGiro),
    FOREIGN KEY (idZona) REFERENCES Zona(idZona),
    FOREIGN KEY (idTurno) REFERENCES Turno(idTurno),
    FOREIGN KEY (idOperatore) REFERENCES Operatore(idOperatore),
    FOREIGN KEY (idMezzo) REFERENCES Mezzo(idMezzo)
);

CREATE TABLE Svuotamento (
    idSvuotamento INT AUTO_INCREMENT,
    esito VARCHAR(30) NOT NULL,
    pesoRaccolto DECIMAL(10,2) NOT NULL CHECK (pesoRaccolto >= 0),
    dataOra DATETIME NOT NULL,
    idCassonetto INT NOT NULL,
    idGiro INT NULL,
    idTurno INT NOT NULL,
    idOperatore INT NOT NULL,
    idMezzo INT NOT NULL,
    PRIMARY KEY (idSvuotamento),
    FOREIGN KEY (idCassonetto) REFERENCES Cassonetto(idCassonetto),
    FOREIGN KEY (idGiro) REFERENCES Giro_Raccolta(idGiro),
    FOREIGN KEY (idTurno) REFERENCES Turno(idTurno),
    FOREIGN KEY (idOperatore) REFERENCES Operatore(idOperatore),
    FOREIGN KEY (idMezzo) REFERENCES Mezzo(idMezzo)
);

CREATE TABLE Lettura_Riempimento (
    idLettura INT AUTO_INCREMENT,
    dataOra DATETIME NOT NULL,
    percentualeLivelloRiempimento DECIMAL(5,2) NOT NULL
        CHECK (percentualeLivelloRiempimento BETWEEN 0 AND 100),
    idCassonetto INT NOT NULL,
    PRIMARY KEY (idLettura),
    UNIQUE (idCassonetto, dataOra),
    FOREIGN KEY (idCassonetto) REFERENCES Cassonetto(idCassonetto)
);

CREATE TABLE Segnalazione (
    idSegnalazione INT AUTO_INCREMENT,
    dataOra DATETIME NOT NULL,
    tipoSegnalazione VARCHAR(50) NOT NULL,
    descrizione VARCHAR(255) NOT NULL,
    stato VARCHAR(30) NOT NULL,
    idCassonetto INT NOT NULL,
    PRIMARY KEY (idSegnalazione),
    FOREIGN KEY (idCassonetto) REFERENCES Cassonetto(idCassonetto)
);

CREATE TABLE Anomalia (
    idAnomalia INT AUTO_INCREMENT,
    tipoAnomalia VARCHAR(50) NOT NULL,
    dataApertura DATETIME NOT NULL,
    dataChiusura DATETIME NULL,
    stato VARCHAR(30) NOT NULL,
    idSegnalazione INT NOT NULL,
    PRIMARY KEY (idAnomalia),
    UNIQUE (idSegnalazione),
    CHECK (dataChiusura IS NULL OR dataApertura <= dataChiusura),
    FOREIGN KEY (idSegnalazione) REFERENCES Segnalazione(idSegnalazione)
);

CREATE TABLE Log_Modifiche (
    idLog INT AUTO_INCREMENT,
    tabellaCoinvolta VARCHAR(50) NOT NULL,
    tipoOperazione VARCHAR(10) NOT NULL,
    dataOraOperazione DATETIME NOT NULL,
    idRecord INT NOT NULL,
    PRIMARY KEY (idLog)
);

-- Indice per velocizzare ricerche per cassonetto e data
CREATE INDEX idx_svuotamento_cassonetto_data
ON Svuotamento (idCassonetto, dataOra);

CREATE INDEX idx_lettura_cassonetto_data
ON Lettura_Riempimento (idCassonetto, dataOra);

-- Trigger di audit
DELIMITER //

CREATE TRIGGER trg_audit_cassonetto_ins
AFTER INSERT ON Cassonetto
FOR EACH ROW
BEGIN
    INSERT INTO Log_Modifiche VALUES (NULL,'Cassonetto','INSERT',CURRENT_TIMESTAMP,NEW.idCassonetto);
END//

CREATE TRIGGER trg_audit_cassonetto_upd
AFTER UPDATE ON Cassonetto
FOR EACH ROW
BEGIN
    INSERT INTO Log_Modifiche VALUES (NULL,'Cassonetto','UPDATE',CURRENT_TIMESTAMP,NEW.idCassonetto);
END//

CREATE TRIGGER trg_audit_cassonetto_del
AFTER DELETE ON Cassonetto
FOR EACH ROW
BEGIN
    INSERT INTO Log_Modifiche VALUES (NULL,'Cassonetto','DELETE',CURRENT_TIMESTAMP,OLD.idCassonetto);
END//

CREATE TRIGGER trg_audit_svuotamento_ins
AFTER INSERT ON Svuotamento
FOR EACH ROW
BEGIN
    INSERT INTO Log_Modifiche VALUES (NULL,'Svuotamento','INSERT',CURRENT_TIMESTAMP,NEW.idSvuotamento);
END//

CREATE TRIGGER trg_audit_svuotamento_upd
AFTER UPDATE ON Svuotamento
FOR EACH ROW
BEGIN
    INSERT INTO Log_Modifiche VALUES (NULL,'Svuotamento','UPDATE',CURRENT_TIMESTAMP,NEW.idSvuotamento);
END//

CREATE TRIGGER trg_audit_svuotamento_del
AFTER DELETE ON Svuotamento
FOR EACH ROW
BEGIN
    INSERT INTO Log_Modifiche VALUES (NULL,'Svuotamento','DELETE',CURRENT_TIMESTAMP,OLD.idSvuotamento);
END//

CREATE TRIGGER trg_audit_segnalazione_ins
AFTER INSERT ON Segnalazione
FOR EACH ROW
BEGIN
    INSERT INTO Log_Modifiche VALUES (NULL,'Segnalazione','INSERT',CURRENT_TIMESTAMP,NEW.idSegnalazione);
END//

CREATE TRIGGER trg_audit_segnalazione_upd
AFTER UPDATE ON Segnalazione
FOR EACH ROW
BEGIN
    INSERT INTO Log_Modifiche VALUES (NULL,'Segnalazione','UPDATE',CURRENT_TIMESTAMP,NEW.idSegnalazione);
END//

CREATE TRIGGER trg_audit_segnalazione_del
AFTER DELETE ON Segnalazione
FOR EACH ROW
BEGIN
    INSERT INTO Log_Modifiche VALUES (NULL,'Segnalazione','DELETE',CURRENT_TIMESTAMP,OLD.idSegnalazione);
END//

-- Trigger per mantenere coerenza tra Svuotamento e Giro_Raccolta
CREATE TRIGGER trg_coerenza_svuotamento_ins
BEFORE INSERT ON Svuotamento
FOR EACH ROW
BEGIN
    DECLARE giroOperatore INT;
    DECLARE giroMezzo INT;
    DECLARE giroTurno INT;

    IF NEW.idGiro IS NOT NULL THEN
        SELECT idOperatore, idMezzo, idTurno
        INTO giroOperatore, giroMezzo, giroTurno
        FROM Giro_Raccolta
        WHERE idGiro = NEW.idGiro;

        SET NEW.idOperatore = giroOperatore;
        SET NEW.idMezzo = giroMezzo;
        SET NEW.idTurno = giroTurno;
    END IF;
END//

CREATE TRIGGER trg_coerenza_svuotamento_upd
BEFORE UPDATE ON Svuotamento
FOR EACH ROW
BEGIN
    DECLARE giroOperatore INT;
    DECLARE giroMezzo INT;
    DECLARE giroTurno INT;

    IF NEW.idGiro IS NOT NULL THEN
        SELECT idOperatore, idMezzo, idTurno
        INTO giroOperatore, giroMezzo, giroTurno
        FROM Giro_Raccolta
        WHERE idGiro = NEW.idGiro;

        SET NEW.idOperatore = giroOperatore;
        SET NEW.idMezzo = giroMezzo;
        SET NEW.idTurno = giroTurno;
    END IF;
END//

DELIMITER ;

-- Stored procedures
DELIMITER //

CREATE PROCEDURE SP_Crea_Cassonetto(
    IN p_capacitaKg DECIMAL(8,2),
    IN p_coordinate VARCHAR(30),
    IN p_nomeZona VARCHAR(50),
    IN p_nomeTipoRifiuto VARCHAR(40)
)
BEGIN
    DECLARE v_idZona INT;
    DECLARE v_idTipoRifiuto INT;

    SELECT idZona INTO v_idZona
    FROM Zona
    WHERE nomeZona = p_nomeZona;

    SELECT idTipoRifiuto INTO v_idTipoRifiuto
    FROM Tipo_Rifiuto
    WHERE nome = p_nomeTipoRifiuto;

    INSERT INTO Cassonetto (capacitaKg, coordinate, idZona, idTipoRifiuto)
    VALUES (p_capacitaKg, p_coordinate, v_idZona, v_idTipoRifiuto);
END//

CREATE PROCEDURE SP_Ins_Operatore_ByUnita(
    IN p_nome VARCHAR(50),
    IN p_cognome VARCHAR(50),
    IN p_ruolo VARCHAR(50),
    IN p_costoOrario DECIMAL(8,2),
    IN p_nomeUnita VARCHAR(60)
)
BEGIN
    DECLARE v_idUnita INT;

    SELECT idUnita INTO v_idUnita
    FROM Unita_Organizzativa
    WHERE nomeUnita = p_nomeUnita;

    INSERT INTO Operatore (nome, cognome, ruolo, costoOrario, idUnita)
    VALUES (p_nome, p_cognome, p_ruolo, p_costoOrario, v_idUnita);
END//

CREATE PROCEDURE SP_Ins_Mezzo_ByUnita(
    IN p_targa VARCHAR(15),
    IN p_tipoMezzo VARCHAR(50),
    IN p_capacitaKg DECIMAL(10,2),
    IN p_costoOrario DECIMAL(8,2),
    IN p_nomeUnita VARCHAR(60)
)
BEGIN
    DECLARE v_idUnita INT;

    SELECT idUnita INTO v_idUnita
    FROM Unita_Organizzativa
    WHERE nomeUnita = p_nomeUnita;

    INSERT INTO Mezzo (targa, tipoMezzo, capacitaKg, costoOrario, idUnita)
    VALUES (p_targa, p_tipoMezzo, p_capacitaKg, p_costoOrario, v_idUnita);
END//


CREATE PROCEDURE SP_Crea_Giro_Raccolta(
    IN p_data DATE,
    IN p_priorita INT,
    IN p_stato VARCHAR(30),
    IN p_durataStimataMin INT,
    IN p_nomeZona VARCHAR(50),
    IN p_inizio TIME,
    IN p_fine TIME,
    IN p_nomeOperatore VARCHAR(50),
    IN p_cognomeOperatore VARCHAR(50),
    IN p_targaMezzo VARCHAR(15)
)
BEGIN
    DECLARE v_idZona INT;
    DECLARE v_idTurno INT;
    DECLARE v_idOperatore INT;
    DECLARE v_idMezzo INT;

    SELECT idZona INTO v_idZona
    FROM Zona WHERE nomeZona = p_nomeZona;

    SELECT idTurno INTO v_idTurno
    FROM Turno WHERE inizio = p_inizio AND fine = p_fine;

    SELECT idOperatore INTO v_idOperatore
    FROM Operatore WHERE nome = p_nomeOperatore AND cognome = p_cognomeOperatore;

    SELECT idMezzo INTO v_idMezzo
    FROM Mezzo WHERE targa = p_targaMezzo;

    INSERT INTO Giro_Raccolta (data, priorita, stato, durataStimataMin, idZona, idTurno, idOperatore, idMezzo)
    VALUES (p_data, p_priorita, p_stato, p_durataStimataMin, v_idZona, v_idTurno, v_idOperatore, v_idMezzo);
END//

CREATE PROCEDURE SP_Ins_Svuotamento(
    IN p_esito VARCHAR(30),
    IN p_pesoRaccolto DECIMAL(10,2),
    IN p_dataOra DATETIME,
    IN p_idCassonetto INT,
    IN p_idGiro INT,
    IN p_inizioTurno TIME,
    IN p_fineTurno TIME,
    IN p_nomeOperatore VARCHAR(50),
    IN p_cognomeOperatore VARCHAR(50),
    IN p_targaMezzo VARCHAR(15)
)
BEGIN
    DECLARE v_idTurno INT;
    DECLARE v_idOperatore INT;
    DECLARE v_idMezzo INT;

    SELECT idTurno INTO v_idTurno
    FROM Turno WHERE inizio = p_inizioTurno AND fine = p_fineTurno;

    SELECT idOperatore INTO v_idOperatore
    FROM Operatore WHERE nome = p_nomeOperatore AND cognome = p_cognomeOperatore;

    SELECT idMezzo INTO v_idMezzo
    FROM Mezzo WHERE targa = p_targaMezzo;

    INSERT INTO Svuotamento (esito, pesoRaccolto, dataOra, idCassonetto, idGiro, idTurno, idOperatore, idMezzo)
    VALUES (p_esito, p_pesoRaccolto, p_dataOra, p_idCassonetto, p_idGiro, v_idTurno, v_idOperatore, v_idMezzo);
END//

-- Procedura: Chiusura ultima anomalia di un cassonetto
CREATE PROCEDURE SP_Chiudi_Ultima_Anomalia_Cassonetto(
    IN p_idCassonetto INT,
    IN p_dataChiusura DATETIME
)
BEGIN
    DECLARE v_idAnomalia INT;

    START TRANSACTION;

    SELECT a.idAnomalia
    INTO v_idAnomalia
    FROM Anomalia a
    JOIN Segnalazione sg ON sg.idSegnalazione = a.idSegnalazione
    WHERE sg.idCassonetto = p_idCassonetto
      AND a.stato <> 'Chiusa'
    ORDER BY a.idAnomalia DESC
    LIMIT 1;

    IF v_idAnomalia IS NOT NULL THEN
        UPDATE Anomalia
        SET dataChiusura = p_dataChiusura,
            stato = 'Chiusa'
        WHERE idAnomalia = v_idAnomalia;

        UPDATE Segnalazione sg
        JOIN Anomalia a ON a.idSegnalazione = sg.idSegnalazione
        SET sg.stato = 'Chiusa'
        WHERE a.idAnomalia = v_idAnomalia;
    END IF;

    COMMIT;
END//

DELIMITER ;

-- Popolamento database
INSERT INTO Zona (nomeZona, descrizione) VALUES
('Centro', 'Zona centrale'),
('Nord', 'Zona residenziale nord'),
('Sud', 'Zona periferica sud'),
('Est', 'Zona industriale est'),
('Ovest', 'Zona commerciale ovest'),
('Collina', 'Zona collinare'),
('Porto', 'Zona portuale'),
('Universita', 'Zona universitaria'),
('Stazione', 'Zona stazione centrale'),
('Parco', 'Zona verde urbana');

INSERT INTO Tipo_Rifiuto (nome, descrizione) VALUES
('Carta', 'Rifiuti cartacei'),
('Plastica', 'Materiale plastico'),
('Vetro', 'Rifiuti in vetro'),
('Organico', 'Scarti alimentari'),
('Indifferenziato', 'Rifiuti misti');

INSERT INTO Unita_Organizzativa (nomeUnita) VALUES
('Squadra A'),
('Squadra B'),
('Squadra C');

INSERT INTO Turno (inizio, fine) VALUES
('06:00:00','10:00:00'),
('10:00:00','14:00:00'),
('14:00:00','18:00:00');

CALL SP_Ins_Operatore_ByUnita('Mario','Rossi','Autista',18.50,'Squadra A');
CALL SP_Ins_Operatore_ByUnita('Luca','Bianchi','Operatore',16.00,'Squadra A');
CALL SP_Ins_Operatore_ByUnita('Giulia','Verdi','Operatore',17.00,'Squadra B');
CALL SP_Ins_Operatore_ByUnita('Paolo','Neri','Autista',19.00,'Squadra B');
CALL SP_Ins_Operatore_ByUnita('Anna','Gallo','Operatore',15.50,'Squadra C');
CALL SP_Ins_Operatore_ByUnita('Marco','Ferrari','Operatore',16.50,'Squadra C');
CALL SP_Ins_Operatore_ByUnita('Elena','Romano','Autista',20.00,'Squadra A');
CALL SP_Ins_Operatore_ByUnita('Davide','Greco','Operatore',15.80,'Squadra B');
CALL SP_Ins_Operatore_ByUnita('Sara','Conti','Operatore',17.20,'Squadra C');
CALL SP_Ins_Operatore_ByUnita('Andrea','Moretti','Autista',19.50,'Squadra A');

CALL SP_Ins_Mezzo_ByUnita('AA111AA','Compattatore',5000,25.00,'Squadra A');
CALL SP_Ins_Mezzo_ByUnita('BB222BB','Compattatore',5200,26.00,'Squadra A');
CALL SP_Ins_Mezzo_ByUnita('CC333CC','Camion',4500,22.00,'Squadra B');
CALL SP_Ins_Mezzo_ByUnita('DD444DD','Camion',4800,23.00,'Squadra B');
CALL SP_Ins_Mezzo_ByUnita('EE555EE','Furgone',3000,18.00,'Squadra C');

CALL SP_Crea_Cassonetto(500,'45.0700,7.6800','Centro','Carta');
CALL SP_Crea_Cassonetto(600,'45.0710,7.6810','Nord','Plastica');
CALL SP_Crea_Cassonetto(450,'45.0720,7.6820','Sud','Vetro');
CALL SP_Crea_Cassonetto(700,'45.0730,7.6830','Est','Organico');
CALL SP_Crea_Cassonetto(550,'45.0740,7.6840','Ovest','Indifferenziato');
CALL SP_Crea_Cassonetto(520,'45.0750,7.6850','Collina','Carta');
CALL SP_Crea_Cassonetto(610,'45.0760,7.6860','Porto','Plastica');
CALL SP_Crea_Cassonetto(480,'45.0770,7.6870','Universita','Vetro');
CALL SP_Crea_Cassonetto(530,'45.0780,7.6880','Stazione','Organico');
CALL SP_Crea_Cassonetto(620,'45.0790,7.6890','Parco','Indifferenziato');
CALL SP_Crea_Cassonetto(510,'45.0800,7.6900','Centro','Plastica');
CALL SP_Crea_Cassonetto(590,'45.0810,7.6910','Nord','Vetro');
CALL SP_Crea_Cassonetto(400,'45.0900,7.7000','Sud','Carta');
CALL SP_Crea_Cassonetto(450,'45.0910,7.7010','Est','Plastica');

CALL SP_Crea_Giro_Raccolta('2026-03-01',1,'Pianificato',120,'Centro','06:00:00','10:00:00','Mario','Rossi','AA111AA');
CALL SP_Crea_Giro_Raccolta('2026-03-01',2,'Pianificato',90,'Nord','10:00:00','14:00:00','Giulia','Verdi','CC333CC');
CALL SP_Crea_Giro_Raccolta('2026-03-02',1,'Completato',100,'Sud','06:00:00','10:00:00','Luca','Bianchi','AA111AA');
CALL SP_Crea_Giro_Raccolta('2026-03-02',3,'Pianificato',110,'Est','10:00:00','14:00:00','Paolo','Neri','DD444DD');
CALL SP_Crea_Giro_Raccolta('2026-03-03',1,'Pianificato',95,'Ovest','14:00:00','18:00:00','Anna','Gallo','EE555EE');
CALL SP_Crea_Giro_Raccolta('2026-03-03',2,'Completato',130,'Collina','06:00:00','10:00:00','Marco','Ferrari','BB222BB');
CALL SP_Crea_Giro_Raccolta('2026-03-04',1,'Pianificato',85,'Porto','10:00:00','14:00:00','Elena','Romano','AA111AA');
CALL SP_Crea_Giro_Raccolta('2026-03-04',2,'Completato',140,'Universita','14:00:00','18:00:00','Davide','Greco','CC333CC');

INSERT INTO Lettura_Riempimento (dataOra, percentualeLivelloRiempimento, idCassonetto) VALUES
('2026-03-01 05:30:00',75,1),
('2026-03-01 05:40:00',60,2),
('2026-03-01 06:00:00',85,3),
('2026-03-02 07:00:00',50,4),
('2026-03-02 07:30:00',90,5),
('2026-03-02 08:00:00',45,6),
('2026-03-03 09:00:00',70,7),
('2026-03-03 09:30:00',65,8),
('2026-03-03 10:00:00',80,9),
('2026-03-04 06:45:00',55,10),
('2026-03-04 07:15:00',95,11),
('2026-03-04 07:45:00',60,12);

CALL SP_Ins_Svuotamento('Completato',350,'2026-03-01 07:00:00',1,1,'06:00:00','10:00:00','Mario','Rossi','AA111AA');
CALL SP_Ins_Svuotamento('Completato',420,'2026-03-01 11:00:00',2,2,'10:00:00','14:00:00','Giulia','Verdi','CC333CC');
CALL SP_Ins_Svuotamento('Completato',300,'2026-03-02 08:30:00',3,3,'06:00:00','10:00:00','Luca','Bianchi','AA111AA');
CALL SP_Ins_Svuotamento('Completato',500,'2026-03-02 12:00:00',4,4,'10:00:00','14:00:00','Paolo','Neri','DD444DD');
CALL SP_Ins_Svuotamento('Completato',280,'2026-03-03 15:00:00',5,5,'14:00:00','18:00:00','Anna','Gallo','EE555EE');
CALL SP_Ins_Svuotamento('Completato',390,'2026-03-03 09:30:00',6,6,'06:00:00','10:00:00','Marco','Ferrari','BB222BB');
CALL SP_Ins_Svuotamento('Completato',410,'2026-03-04 11:00:00',7,7,'10:00:00','14:00:00','Elena','Romano','AA111AA');
CALL SP_Ins_Svuotamento('Completato',450,'2026-03-04 16:00:00',8,8,'14:00:00','18:00:00','Davide','Greco','CC333CC');
CALL SP_Ins_Svuotamento('Completato',320,'2026-03-04 09:00:00',9,1,'06:00:00','10:00:00','Mario','Rossi','AA111AA');
CALL SP_Ins_Svuotamento('Completato',370,'2026-03-04 10:30:00',10,2,'10:00:00','14:00:00','Giulia','Verdi','CC333CC');

INSERT INTO Segnalazione (dataOra, tipoSegnalazione, descrizione, stato, idCassonetto) VALUES
('2026-03-01 06:00:00','Danneggiamento','Coperchio rotto','Aperta',1),
('2026-03-01 07:00:00','Pieno','Cassonetto pieno','Chiusa',2),
('2026-03-02 08:00:00','Vandalismo','Graffiti','In gestione',3),
('2026-03-02 09:00:00','Ostruzione','Blocco apertura','Aperta',4),
('2026-03-03 10:00:00','Odore','Odore forte','Aperta',5),
('2026-03-03 11:00:00','Perdita','Liquido fuoriuscito','Chiusa',6),
('2026-03-04 08:00:00','Rumore','Rumore anomalo','In gestione',7),
('2026-03-04 09:00:00','Rottura','Struttura danneggiata','Aperta',8);

INSERT INTO Anomalia (tipoAnomalia, dataApertura, dataChiusura, stato, idSegnalazione) VALUES
('Guasto meccanico','2026-03-01 06:30:00',NULL,'In gestione',1),
('Blocco struttura','2026-03-02 08:30:00',NULL,'Aperta',3),
('Perdita liquidi','2026-03-03 10:30:00',NULL,'In gestione',5),
('Vandalismo grave','2026-03-04 08:30:00',NULL,'Aperta',7),
('Usura','2026-03-04 09:30:00',NULL,'In gestione',8);