# Smart City – Database Raccolta Rifiuti

Progetto di progettazione e implementazione di un database per la gestione della raccolta dei rifiuti in una Smart City.

Il sistema permette di gestire cassonetti sul territorio, monitorare il livello di riempimento tramite sensori, registrare gli svuotamenti effettuati da operatori e mezzi e gestire segnalazioni e anomalie. Inoltre consente di analizzare lo storico delle operazioni e calcolare KPI sull’efficienza del servizio. :contentReference[oaicite:0]{index=0}

## Contenuto del progetto

- **Relazione**: analisi dei requisiti, progettazione E-R, modello relazionale, normalizzazione e progettazione fisica.
- **create-database-sql.sql**: creazione del database `smart_city`, tabelle, vincoli, indici, trigger e stored procedure. :contentReference[oaicite:1]{index=1}
- **operations-sql.sql**: operazioni di esempio, viste per KPI e query di analisi. :contentReference[oaicite:2]{index=2}

## Funzionalità principali

- gestione cassonetti, zone e tipologie di rifiuto  
- registrazione letture di riempimento  
- gestione giri di raccolta e svuotamenti  
- gestione segnalazioni dei cittadini e anomalie  
- audit delle modifiche tramite trigger  
- KPI e statistiche tramite viste SQL

## Tecnologie

- MySQL
- SQL (DDL, DML, trigger, stored procedure, view)