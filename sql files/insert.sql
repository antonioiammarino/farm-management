-- Large barn: area 100 -> max capacity 25 animals
INSERT INTO barns (barn_id, area, barn_location, current_occupancy) 
VALUES ('B01', 100, 'North Wing', 0);

-- Small barn: area 12 -> max capacity 3 animals
INSERT INTO barns (barn_id, area, barn_location, current_occupancy) 
VALUES ('B02', 12, 'South Wing', 3); 

INSERT INTO tools (code, price, tool_type, tool_description, barn_ref) 
VALUES (
    'T-100', 
    50.00, 
    'Pitchfork', 
    'Standard pitchfork', 
    (SELECT REF(b) FROM barns b WHERE b.barn_id = 'B01')
);

INSERT INTO employees (tax_code, emp_name, surname, salary, emp_address, tools, animals) 
VALUES (
    'RSSMRA80A01H501U', 
    'Mario', 
    'Rossi', 
    2500.00,
    t_address('Via Roma 1', 'Bari', 'BA', '70100'),
    t_usage_nt(), -- Constructor: initially empty Nested Table
    t_cured_nt()  -- Constructor: initially empty Nested Table
);

INSERT INTO animals (code, weight, sex, birth, animal_type, last_shoeing, barn_ref) 
VALUES (
    'HORSE-01', 
    450.00, 
    'M', 
    TO_DATE('2020-05-15', 'YYYY-MM-DD'), 
    'Horse', 
    TO_DATE('2026-01-10', 'YYYY-MM-DD'),
    (SELECT REF(b) FROM barns b WHERE b.barn_id = 'B01')
);

INSERT INTO external_companies (vat, comp_name, comp_address, phones, deals) 
VALUES (
    'IT12345678901', 
    'AgriFarm S.p.A.',
    t_address('Via Milano 10', 'Milano', 'MI', '20100'),
    t_phone_varray('02-1234567', '333-9876543'),
    t_deal_nt() -- Constructor: initially empty Nested Table
);

UPDATE barns 
SET current_occupancy = 1
WHERE barn_id = 'B01';


COMMIT;




