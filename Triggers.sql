CREATE OR REPLACE FUNCTION checkAvail() RETURNS trigger AS $$
DECLARE nro, fecha, hora, duracion_examen
BEGIN

    SELECT nroaula, duracion,
    EXTRACT(HOUR FROM fecha_hora) AS hora,
    EXTRACT(DAY FROM fecha_hora) AS dia,
    EXTRACT(MONTH FROM fecha_hora) AS mes,
    EXTRACT(YEAR FROM fecha_hora) AS año AS anio

    FROM AULA_EXAMEN
    where (nroaula=NEW.nroaula &&
            dia = EXTRACT(DAY FROM NEW.fecha_hora) &&
            mes = EXTRACT(MONTH FROM NEW.fecha_hora) &&
            anio = EXTRACT(YEAR FROM NEW.fecha_hora) &&

            )



    SELECT COUNT(*) = 0 INTO all_match
    FROM test_table
    WHERE value <> NEW.value;

    -- Insert a new row with the new value and the check result
    INSERT INTO test_table (value, check_result)
    VALUES (NEW.value, all_match);

    -- Prevent the original insert
    RETURN NULL;
END;

--se podria hacer un update de la tupla insertada, after
--o checkear y luego insertar con nuevo valor, before
CREATE TRIGGER confirm
    BEFORE INSERT ON AULA_EXAMEN
    FOR