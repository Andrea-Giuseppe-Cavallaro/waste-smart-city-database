USE smart_city;

-- Viste per KPI e LOG
CREATE OR REPLACE VIEW V_KPI_Raccolta_Zona AS
SELECT
    z.idZona,
    z.nomeZona,
    DATE(s.dataOra) AS data,
    SUM(s.pesoRaccolto) AS kgRaccolti
FROM Svuotamento s
JOIN Cassonetto c ON c.idCassonetto = s.idCassonetto
JOIN Zona z ON z.idZona = c.idZona
GROUP BY z.idZona, z.nomeZona, DATE(s.dataOra);

CREATE OR REPLACE VIEW V_KPI_Raccolta_TipoRifiuto AS
SELECT
    t.idTipoRifiuto,
    t.nome AS tipoRifiuto,
    DATE(s.dataOra) AS data,
    SUM(s.pesoRaccolto) AS kgRaccolti
FROM Svuotamento s
JOIN Cassonetto c ON c.idCassonetto = s.idCassonetto
JOIN Tipo_Rifiuto t ON t.idTipoRifiuto = c.idTipoRifiuto
GROUP BY t.idTipoRifiuto, t.nome, DATE(s.dataOra);

CREATE OR REPLACE VIEW V_KPI_Costo_Giro AS
SELECT
    g.idGiro,
    g.data,
    z.nomeZona,
    g.durataStimataMin,
    o.costoOrario AS costoOperatoreOrario,
    m.costoOrario AS costoMezzoOrario,
    (g.durataStimataMin / 60.0) * (o.costoOrario + m.costoOrario) AS costoStimatoGiro
FROM Giro_Raccolta g
JOIN Zona z ON z.idZona = g.idZona
JOIN Operatore o ON o.idOperatore = g.idOperatore
JOIN Mezzo m ON m.idMezzo = g.idMezzo;

CREATE OR REPLACE VIEW V_Log_Modifiche AS
SELECT
    idLog, tabellaCoinvolta, tipoOperazione, dataOraOperazione, idRecord
FROM Log_Modifiche;

-- O1: Inserimento di un nuovo cassonetto
CALL SP_Crea_Cassonetto(505.00, '45.0960,7.7060', 'Centro', 'Carta');

-- O2: Inserimento di una lettura di riempimento
INSERT INTO Lettura_Riempimento (dataOra, percentualeLivelloRiempimento, idCassonetto)
SELECT '2026-03-06 07:10:00', 82.50, c.idCassonetto
FROM Cassonetto c
WHERE c.coordinate = '45.0960,7.7060'
  AND NOT EXISTS (
      SELECT 1
      FROM Lettura_Riempimento lr
      WHERE lr.idCassonetto = c.idCassonetto
        AND lr.dataOra = '2026-03-06 07:10:00'
  );

-- O3: Creazione di un giro di raccolta
CALL SP_Crea_Giro_Raccolta(
    '2026-03-06',
    1,
    'Pianificato',
    105,
    'Centro',
    '06:00:00',
    '10:00:00',
    'Mario',
    'Rossi',
    'AA111AA'
);

-- O4: Registrazione svuotamento associato a giro
CALL SP_Ins_Svuotamento(
    'Completato',
    340.00,
    '2026-03-06 08:20:00',
    (SELECT idCassonetto FROM Cassonetto WHERE coordinate='45.0960,7.7060' ORDER BY idCassonetto DESC LIMIT 1),
    (SELECT idGiro FROM Giro_Raccolta g JOIN Zona z ON z.idZona=g.idZona WHERE g.data='2026-03-06' AND z.nomeZona='Centro' ORDER BY idGiro DESC LIMIT 1),
    '06:00:00','10:00:00',
    'Mario','Rossi',
    'AA111AA'
);

-- O5: Registrazione svuotamento fuori giro
CALL SP_Ins_Svuotamento(
    'Completato',
    120.00,
    '2026-03-06 12:00:00',
    (SELECT idCassonetto FROM Cassonetto WHERE coordinate='45.0960,7.7060' ORDER BY idCassonetto DESC LIMIT 1),
    NULL,
    '10:00:00','14:00:00',
    'Paolo','Neri',
    'DD444DD'
);

-- O6: Inserimento segnalazione
INSERT INTO Segnalazione (dataOra, tipoSegnalazione, descrizione, stato, idCassonetto)
SELECT
    '2026-03-06 06:50:00',
    'Rottura',
    'Segnalazione di prova operazioni.sql',
    'Aperta',
    c.idCassonetto
FROM Cassonetto c
WHERE c.coordinate = '45.0960,7.7060'
  AND NOT EXISTS (
      SELECT 1
      FROM Segnalazione sg
      WHERE sg.idCassonetto = c.idCassonetto
        AND sg.dataOra = '2026-03-06 06:50:00'
        AND sg.tipoSegnalazione = 'Rottura'
  );

-- O7: Apertura anomalia da segnalazione
INSERT INTO Anomalia (tipoAnomalia, dataApertura, dataChiusura, stato, idSegnalazione)
SELECT
    'Guasto strutturale',
    '2026-03-06 07:00:00',
    NULL,
    'Aperta',
    sg.idSegnalazione
FROM Segnalazione sg
JOIN Cassonetto c ON c.idCassonetto = sg.idCassonetto
LEFT JOIN Anomalia a ON a.idSegnalazione = sg.idSegnalazione
WHERE c.coordinate = '45.0960,7.7060'
  AND sg.stato = 'Aperta'
  AND a.idAnomalia IS NULL
ORDER BY sg.idSegnalazione DESC
LIMIT 1;

-- O8: Chiusura anomalia + chiusura segnalazione (transazione)
CALL SP_Chiudi_Ultima_Anomalia_Cassonetto((
    SELECT idCassonetto
    FROM Cassonetto
    WHERE coordinate = '45.0960,7.7060'
    ORDER BY idCassonetto DESC
    LIMIT 1
), '2026-03-06 10:00:00');

-- O9: KPI su periodo
SELECT idZona, nomeZona, SUM(kgRaccolti) AS kgTotali
FROM V_KPI_Raccolta_Zona
WHERE data BETWEEN '2026-03-01' AND '2026-03-31'
GROUP BY idZona, nomeZona
ORDER BY kgTotali DESC;

SELECT idTipoRifiuto, tipoRifiuto, SUM(kgRaccolti) AS kgTotali
FROM V_KPI_Raccolta_TipoRifiuto
WHERE data BETWEEN '2026-03-01' AND '2026-03-31'
GROUP BY idTipoRifiuto, tipoRifiuto
ORDER BY kgTotali DESC;

SELECT *
FROM V_KPI_Costo_Giro
WHERE data BETWEEN '2026-03-01' AND '2026-03-31'
ORDER BY costoStimatoGiro DESC;

-- Query di supporto Audit
SELECT tabellaCoinvolta, tipoOperazione, COUNT(*) AS totale
FROM V_Log_Modifiche
GROUP BY tabellaCoinvolta, tipoOperazione
ORDER BY tabellaCoinvolta, tipoOperazione;

SELECT *
FROM V_Log_Modifiche
ORDER BY idLog DESC
LIMIT 30;