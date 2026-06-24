CREATE OR REPLACE PROCEDURE log_tool_usage (
    p_tax_code IN VARCHAR2,
    p_tool_code IN VARCHAR2,
    p_usage_date IN DATE DEFAULT SYSDATE
) AS
    tool_ref REF t_tool;
    usages t_usage_nt;
BEGIN
    SELECT REF(t) INTO tool_ref 
    FROM tools t 
    WHERE code = p_tool_code;

    SELECT tools INTO usages 
    FROM employees 
    WHERE tax_code = p_tax_code;
    
    -- Initialize the collection if it is currently empty
    IF usages IS NULL THEN
        usages := t_usage_nt();
    END IF;

    -- Extend the collection array and append the new tool usage record
    usages.EXTEND;
    usages(usages.LAST) := t_usage(tool_ref, TRUNC(p_usage_date));

    -- Execute insertion on the Parent Row.
    -- This forces the 'check_tool_usage_date' trigger to fire
    UPDATE employees
    SET tools = usages
    WHERE tax_code = p_tax_code;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20022, 'DATA ERROR: Employee Tax Code or Tool Code not found.');
END;
/


-- TEST: Prove that the procedure forces the parent-trigger to fire.
INSERT INTO employees (tax_code, emp_name, surname, salary, emp_address, tools, animals)
VALUES (
    'TEST-EMP', 'Test', 'Procedure1', 2000.00, 
    t_address('Via Test', 'Roma', 'RM', '00100'), 
    t_usage_nt(), t_cured_nt()
);

INSERT INTO tools (code, price, tool_type, tool_description, barn_ref)
VALUES ('TEST-TOOL', 150.00, 'Test', 'Procedure1', NULL);

COMMIT;
BEGIN
    log_tool_usage('TEST-EMP', 'TEST-TOOL', TRUNC(SYSDATE) + 10);
END;





