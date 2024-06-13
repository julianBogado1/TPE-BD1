CREATE OR REPLACE FUNCTION checkAvail() RETURNS trigger AS $$
DECLARE result BOOLEAN;
BEGIN

    SELECT COUNT(*)=0 INTO result
    FROM AULA_EXAMEN
    WHERE nroaula = NEW.nroaula &&
        EXTRACT(DAY FROM fecha_hora) = EXTRACT(DAY FROM NEW.fecha_hora) &&
        EXTRACT(MONTH FROM fecha_hora) = EXTRACT(MONTH FROM NEW.fecha_hora) &&
        EXTRACT(YEAR FROM fecha_hora) = EXTRACT(YEAR FROM NEW.fecha_hora) &&
        EXTRACT(HOUR FROM fecha_hora)+duracion_examen <= EXTRACT(HOUR FROM NEW.fecha_hora)  &&     --total tiempo de examen antes o dps
        EXTRACT(HOUR FROM fecha_hora) >= EXTRACT(HOUR FROM NEW.fecha_hora) + NEW.duracion_examen;  --no se pisan

    INSERT INTO AULA_EXAMEN VALUES (nroaula, fecha_hora, duracion, codmateria, result);
    RETURN NULL;
END;

CREATE TRIGGER confirm
BEFORE INSERT ON AULA_EXAMEN
EXECUTE PROCEDURE checkAvail();