-- Check last_shoeing date for Horses
CREATE OR REPLACE TRIGGER check_shoeing_date
BEFORE INSERT OR UPDATE OF last_shoeing ON animals
FOR EACH ROW
BEGIN
    -- Check only if it is a Horse and the date is provided
    IF :NEW.animal_type = 'Horse' AND :NEW.last_shoeing IS NOT NULL THEN
        IF :NEW.last_shoeing > SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20002, 
                'INVALID DATE: The last shoeing date cannot be in the future.');
        END IF;
    END IF;
END;
/

-- Check tool usage date
CREATE OR REPLACE TRIGGER check_tool_usage_date
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
BEGIN
    IF :NEW.tools IS NOT NULL AND :NEW.tools.COUNT > 0 THEN
        FOR i IN 1 .. :NEW.tools.COUNT LOOP
            IF :NEW.tools(i).date_use > SYSDATE THEN
                RAISE_APPLICATION_ERROR(-20003, 
                    'INVALID DATE: Tool usage date cannot be in the future. 
                    Index: ' || i);
            END IF;
        END LOOP;
    END IF;
END;
/

-- Check deal date vs animal birth date 
CREATE OR REPLACE TRIGGER check_deal_date
BEFORE INSERT OR UPDATE ON external_companies
FOR EACH ROW
DECLARE
    birth DATE;
BEGIN
    IF :NEW.deals IS NOT NULL AND :NEW.deals.COUNT > 0 THEN
        FOR i IN 1 .. :NEW.deals.COUNT LOOP
            IF :NEW.deals(i).animal_ref IS NOT NULL THEN

                SELECT a.birth INTO birth
                FROM animals a
                WHERE REF(a) = :NEW.deals(i).animal_ref;

                IF :NEW.deals(i).date_deal < birth THEN
                    RAISE_APPLICATION_ERROR(-20004, 
                        'INVALID DATE: Deal date cannot be earlier than the animal birth date.');
                END IF;

                IF :NEW.deals(i).date_deal > SYSDATE THEN
                    RAISE_APPLICATION_ERROR(-20005, 
                        'INVALID DATE: Deal date cannot be in the future.');
                END IF;

            END IF;
        END LOOP;
    END IF;
END;
/

-- TEST 1a: EXPECTED: 1 row updated.
UPDATE animals 
SET last_shoeing = TRUNC(SYSDATE) - 5 
WHERE code = 'HORSE-01';

-- TEST 1b: Expected Error
UPDATE animals 
SET last_shoeing = TO_DATE('2030-01-01', 'YYYY-MM-DD') 
WHERE code = 'HORSE-01';

-- TEST 2a: EXPECTED: 1 row updated.
UPDATE employees 
SET tools = t_usage_nt(
    t_usage((SELECT REF(t) FROM tools t WHERE t.code = 'T-100'), TRUNC(SYSDATE))
)
WHERE tax_code = 'RSSMRA80A01H501U';

-- TEST 2b: Expected Error
UPDATE employees 
SET tools = t_usage_nt(
    t_usage((SELECT REF(t) FROM tools t WHERE t.code = 'T-100'), TRUNC(SYSDATE) + 1)
)
WHERE tax_code = 'RSSMRA80A01H501U';


-- TEST 3a: EXPECTED: 1 row updated.
UPDATE external_companies
SET deals = t_deal_nt(
    t_deal((SELECT REF(a) FROM animals a WHERE a.code = 'SWINE-03'), (SYSDATE), 150.00, 'P')
)
WHERE vat = 'IT12345678901';

-- TEST 3b: Expected Error
UPDATE external_companies
SET deals = t_deal_nt(
    t_deal((SELECT REF(a) FROM animals a WHERE a.code = 'SWINE-03'), TO_DATE('2010-01-01', 'YYYY-MM-DD'), 150.00, 'P')
)
WHERE vat = 'IT12345678901';

-- Commit the valid transactions
COMMIT;

-- Limitation Test: Expected: Trigger not activated -> Success
INSERT INTO TABLE(SELECT e.tools FROM employees e WHERE e.tax_code = 'RSSMRA80A01H501U')
VALUES (
    t_usage((SELECT REF(t) FROM tools t WHERE t.code = 'T-100'), TRUNC(SYSDATE) + 10)
);

-- Remove garbage data
ROLLBACK;




