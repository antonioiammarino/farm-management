CREATE OR REPLACE TRIGGER process_animal_deals
AFTER INSERT OR UPDATE ON external_companies
FOR EACH ROW
DECLARE
    is_new BOOLEAN;
BEGIN
    -- If the collection contains transactions
    IF :NEW.deals IS NOT NULL AND :NEW.deals.COUNT > 0 THEN
        FOR i IN 1 .. :NEW.deals.COUNT LOOP
            
            IF :NEW.deals(i).animal_ref IS NOT NULL THEN
                -- Block duplicates (e.g., two purchases or two sales)
                FOR j IN 1 .. :NEW.deals.COUNT LOOP
                    IF j != i 
                       AND :NEW.deals(j).deal_type = :NEW.deals(i).deal_type
                       AND :NEW.deals(j).animal_ref = :NEW.deals(i).animal_ref THEN
                        RAISE_APPLICATION_ERROR(-20010, 
                            'Duplicate deal (' || :NEW.deals(i).deal_type || ') for 
                            the same animal in this transaction.');
                    END IF;
                END LOOP;

                
                is_new := TRUE;
                IF UPDATING AND :OLD.deals IS NOT NULL THEN
                    FOR k IN 1 .. :OLD.deals.COUNT LOOP
                        -- If we find the same deal_type for the same animal
                        IF :OLD.deals(k).deal_type = :NEW.deals(i).deal_type 
                           AND :OLD.deals(k).animal_ref = :NEW.deals(i).animal_ref THEN
                            
                            IF :OLD.deals(k).date_deal = :NEW.deals(i).date_deal
                               AND :OLD.deals(k).price = :NEW.deals(i).price THEN
                                is_new := FALSE; -- Idempotent update (e.g., company name/address changed)
                            ELSE
                                -- Block: attempting to modify a past deal
                                RAISE_APPLICATION_ERROR(-20012,
                                    'This animal already has a finalized deal of type (' || 
                                    :NEW.deals(i).deal_type || ') with this company.');
                            END IF;
                            EXIT; 
                        END IF;
                    END LOOP;
                END IF;

                -- BR7
                IF is_new AND :NEW.deals(i).deal_type = 'S' THEN
                    -- Explicitly vacate the animal from the barn to automatically trigger BR4
                    UPDATE animals a
                    SET a.barn_ref = NULL
                    WHERE REF(a) = :NEW.deals(i).animal_ref;
                END IF;

            END IF;
        END LOOP;
    END IF;
END;
/


-- TEST 1
-- EXPECTED ERROR 20010
UPDATE external_companies
SET deals = t_deal_nt(
    t_deal((SELECT REF(a) FROM animals a WHERE a.code = 'SWINE-01'), TRUNC(SYSDATE), 100.00, 'P'),
    t_deal((SELECT REF(a) FROM animals a WHERE a.code = 'SWINE-01'), TRUNC(SYSDATE), 120.00, 'P')
)
WHERE vat = 'IT12345678901';

-- TEST 2
-- EXPECTED: 1 row updated, animal's barn_ref becomes NULL, barn's occupancy decreases.
-- State BEFORE sale
SELECT code, barn_ref FROM animals WHERE code = 'HORSE-01';
SELECT barn_id, current_occupancy FROM barns WHERE barn_id = 'B01';

-- Execute sale
UPDATE external_companies
SET deals = t_deal_nt(
    t_deal((SELECT REF(a) FROM animals a WHERE a.code = 'HORSE-01'), TRUNC(SYSDATE), 2500.00, 'S')
)
WHERE vat = 'IT12345678901';

-- State AFTER sale (Verify BR4 and BR7 fired)
SELECT code, barn_ref FROM animals WHERE code = 'HORSE-01';
SELECT barn_id, current_occupancy FROM barns WHERE barn_id = 'B01';

COMMIT;

-- TEST 3
-- EXPECTED ERROR 20012
UPDATE external_companies
SET deals = t_deal_nt(
    t_deal((SELECT REF(a) FROM animals a WHERE a.code = 'HORSE-01'), TRUNC(SYSDATE), 2500.00, 'S'),
    t_deal((SELECT REF(a) FROM animals a WHERE a.code = 'HORSE-01'), TRUNC(SYSDATE), 3000.00, 'S')
)
WHERE vat = 'IT12345678901';

UPDATE animals SET birth = TO_DATE('2020-01-01', 'YYYY-MM-DD') WHERE code = 'SWINE-03';
COMMIT;

-- TEST 4: Valid Lifecycle (Purchase and Sale of the same animal)
-- EXPECTED: 1 row updated (Success). The trigger correctly allows different deal types ('P' and 'S').
-- The 'S' deal will also trigger BR7, automatically vacating SWINE-03 from its barn.
-- State BEFORE lifecycle completion
SELECT code, barn_ref FROM animals WHERE code = 'SWINE-03';

-- Execute valid dual-deal (Preserving the old 'P' and adding a new 'S')
UPDATE external_companies
SET deals = t_deal_nt(
    t_deal((SELECT REF(a) FROM animals a WHERE a.code = 'SWINE-03'), TRUNC(SYSDATE), 150.00, 'P'),
    t_deal((SELECT REF(a) FROM animals a WHERE a.code = 'SWINE-03'), TRUNC(SYSDATE), 200.00, 'S')
)
WHERE vat = 'IT12345678901';

-- State AFTER lifecycle completion
-- SWINE-03's barn_ref MUST be NULL now
SELECT code, barn_ref FROM animals WHERE code = 'SWINE-03';

COMMIT;




