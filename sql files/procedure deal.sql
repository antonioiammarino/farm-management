CREATE OR REPLACE PROCEDURE register_animal_deal (
    p_vat IN VARCHAR2,
    p_animal_code IN VARCHAR2,
    p_deal_type IN CHAR,
    p_price IN NUMBER,
    p_date IN DATE DEFAULT SYSDATE
) AS
    animal_ref REF t_animal;
    deals t_deal_nt;
    sold_count NUMBER;
BEGIN
    SELECT REF(a) INTO animal_ref 
    FROM animals a 
    WHERE code = p_animal_code;

    -- If registering a Purchase ('P'), ensure the entity wasn't 
    -- previously Sold ('S') globally
    IF p_deal_type = 'P' THEN
        SELECT COUNT(*) INTO sold_count
        FROM external_companies ec, TABLE(ec.deals) d
        WHERE d.animal_ref = animal_ref AND d.deal_type = 'S';

        IF sold_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20020, 
                'DOMAIN INTEGRITY VIOLATION: This animal was previously sold.
                To repurchase, you must register a new animal entity.');
        END IF;
    END IF;

    -- Retrieve the current collection, extend it, and append the new deal
    SELECT deals INTO deals 
    FROM external_companies 
    WHERE vat = p_vat;
    
    -- Initialize the collection if it is currently empty
    IF deals IS NULL THEN
        deals := t_deal_nt();
    END IF;

    deals.EXTEND;
    deals(deals.LAST) := t_deal(animal_ref, TRUNC(p_date), p_price, p_deal_type);

    -- Execute Update on the Parent Row to guarantee Trigger execution
    UPDATE external_companies
    SET deals = deals
    WHERE vat = p_vat;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20021, 'External Company VAT or Animal Code 
        not found.');
END;
/


-- TEST REPURCHASE
INSERT INTO animals (code, weight, sex, birth, animal_type, last_shoeing, barn_ref) 
VALUES ('TEST-HORSE', 450.00, 'M', TO_DATE('2020-01-01', 'YYYY-MM-DD'), 'Horse', NULL, NULL);

INSERT INTO external_companies (vat, comp_name, comp_address, phones, deals) 
VALUES ('TEST-VAT', 'Global Trading Corp', t_address('Main St', 'Milan', 'MI', '20100'), t_phone_varray(), t_deal_nt());

COMMIT;

-- Register a standard Sale ('S').
BEGIN
    register_animal_deal('TEST-VAT', 'TEST-HORSE', 'S', 2500.00, TRUNC(SYSDATE));
END;
/

-- Attempt to register a Purchase ('P') for the same animal.
BEGIN
    register_animal_deal('TEST-VAT', 'TEST-HORSE', 'P', 1500.00, TRUNC(SYSDATE) + 1);
END;
/

