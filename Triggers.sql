DROP TABLE IF EXISTS aula_examen;

CREATE TABLE aula_examen 
(
        nroaula INT NOT NULL,
        fecha_hora TIMESTAMP NOT NULL,
        duracion INTERVAL NOT NULL,
        codmateria VARCHAR NOT NULL,
        confirmado BOOLEAN NOT NULL DEFAULT FALSE,

        UNIQUE(nroaula, fecha_hora, duracion, codmateria)
);

CREATE OR REPLACE FUNCTION checkAvail() 
RETURNS trigger 
LANGUAGE plpgsql
AS $$
DECLARE 
    resultado INTEGER;
BEGIN

    IF NEW.duracion >= INTERVAL '24 hours' THEN
        RAISE EXCEPTION 'Duracion invalida de examen';
    END IF;    
    
    IF NEW.nroaula <= 0 THEN 
        RAISE EXCEPTION 'Numero de aula invalido';
    END IF;

    SELECT COUNT(*) INTO resultado
    FROM aula_examen
    WHERE nroaula = NEW.nroaula 
        AND confirmado = TRUE
        AND(
                (fecha_hora <= NEW.fecha_hora AND fecha_hora + duracion  >= NEW.fecha_hora)
                OR
                (fecha_hora >= NEW.fecha_hora AND fecha_hora <= NEW.fecha_hora + NEW.duracion)
        );

    IF resultado = 0 THEN
        NEW.confirmado := TRUE;
    ELSE
        NEW.confirmado := FALSE;
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER confirm
BEFORE INSERT ON aula_examen
FOR EACH ROW
EXECUTE FUNCTION checkAvail();


CREATE OR REPLACE FUNCTION analisis_asignaciones(dia_hora TIMESTAMP)
RETURNS VOID
AS $$
DECLARE 
    r RECORD;
    has_data BOOLEAN;

    c_true CURSOR FOR SELECT 
            codmateria, 
            DATE(fecha_hora) AS fecha, 
            AVG(duracion) AS horas, 
            ROW_NUMBER() OVER (PARTITION BY codmateria ORDER BY codmateria, AVG(duracion) DESC) AS nrolinea
    
    FROM aula_examen 
    WHERE confirmado = TRUE AND fecha_hora >= dia_hora
    GROUP BY codmateria, DATE(fecha_hora)
    ORDER BY codmateria, horas DESC;

    c_false CURSOR FOR SELECT 
            nroaula, 
            fecha_hora, 
            duracion AS horas, 
            ROW_NUMBER() OVER (PARTITION BY nroaula ORDER BY nroaula DESC) AS nrolinea
    
    FROM aula_examen 
    WHERE confirmado = FALSE AND fecha_hora >= dia_hora
    ORDER BY nroaula, fecha_hora;
    
BEGIN


    OPEN c_true;
    FETCH c_true INTO r;
    IF FOUND THEN
        has_data := TRUE;
    END IF;
    CLOSE c_true;

    OPEN c_false;
    FETCH c_false INTO r;
    IF FOUND THEN
        has_data := TRUE;
    END IF;
    CLOSE c_false;
    
    
    IF has_data THEN
    RAISE NOTICE '------------------------------------------------------------';
    RAISE NOTICE '----------------ANALISIS DE ASIGNACIONES-------------';
    RAISE NOTICE '------------------------------------------------------------';
    RAISE NOTICE 'Variable--------Fecha--------Horas--------Nro Linea-----';
    RAISE NOTICE '--------------------------------------------------------';
    
    ELSE RETURN;
    END IF;

    OPEN c_true;

    LOOP
        FETCH c_true INTO r;
        EXIT WHEN NOT FOUND;
        raise NOTICE 'Materia: %    %     %                                 %', r.codmateria, r.fecha, r.horas, r.nrolinea;   
    END LOOP;

    CLOSE c_true;

    OPEN c_false;

    LOOP
        FETCH c_false INTO r;
        EXIT WHEN NOT FOUND;
        raise NOTICE 'Aula: %                %     % a %               %', r.nroaula, r.fecha_hora::DATE, r.fecha_hora::TIME, (r.fecha_hora + r.horas)::TIME, r.nrolinea;   
    END LOOP;

    CLOSE c_false;

END; 
$$ LANGUAGE plpgsql;


SELECT analisis_asignaciones('2026-10-01 00:00:00');
SELECT * from aula_examen;
