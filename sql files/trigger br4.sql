-- TRIGGER FOR BR4
CREATE OR REPLACE TRIGGER manage_barn_capacity
BEFORE INSERT OR UPDATE OF barn_ref OR DELETE ON animals
FOR EACH ROW
DECLARE
    area NUMBER;
    occupancy INTEGER;
    max_capacity INTEGER;
    is_moving BOOLEAN := FALSE;
BEGIN
    -- Check if the animal is moving between different barns (UPDATE)
    IF UPDATING THEN
        IF (:NEW.barn_ref IS NULL AND :OLD.barn_ref IS NOT NULL) OR
           (:NEW.barn_ref IS NOT NULL AND :OLD.barn_ref IS NULL) OR
           (:NEW.barn_ref != :OLD.barn_ref) THEN
            is_moving := TRUE;
        END IF;
    END IF;

    -- Check capacity and INCREMENT new barn (INSERT or MOVING to a new barn)
    IF INSERTING OR (UPDATING AND is_moving) THEN
        IF :NEW.barn_ref IS NOT NULL THEN
            
            -- Retrieve area and current occupancy of the NEW barn
            SELECT b.area, b.current_occupancy 
            INTO area, occupancy
            FROM barns b
            WHERE REF(b) = :NEW.barn_ref;
            
            -- Calculate max capacity (1 animal per 4 sq meters)
            max_capacity := TRUNC(area / 4);
            
            -- Block if the new barn is full
            IF occupancy >= max_capacity THEN
                RAISE_APPLICATION_ERROR(-20001, 'OPERATION BLOCKED: 
                The target barn has reached its maximum capacity.');
            END IF;
            
            -- Automatically increment the new barn's occupancy
            UPDATE barns b
            SET b.current_occupancy = b.current_occupancy + 1
            WHERE REF(b) = :NEW.barn_ref;
            
        END IF;
    END IF;

    -- DECREMENT old barn (DELETE or MOVING away from old barn)
    IF DELETING OR (UPDATING AND is_moving) THEN
        IF :OLD.barn_ref IS NOT NULL THEN
            
            -- Automatically decrement the old barn's occupancy
            UPDATE barns b
            SET b.current_occupancy = b.current_occupancy - 1
            WHERE REF(b) = :OLD.barn_ref;
            
        END IF;
    END IF;

END;
/


INSERT INTO animals (code, weight, sex, birth, animal_type, last_shoeing, barn_ref) 
VALUES ('SWINE-03', 10.00, 'M', SYSDATE, 'Swine', NULL, 
        (SELECT REF(b) FROM barns b WHERE b.barn_id = 'B01'));

-- Check the count increase
SELECT barn_id, current_occupancy FROM barns WHERE barn_id = 'B01';

UPDATE animals 
SET barn_ref = (SELECT REF(b) FROM barns b WHERE b.barn_id = 'B02')
WHERE code = 'SWINE-03';



