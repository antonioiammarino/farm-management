-- Uncomment to reset the environment before rerunning
/*
DELETE FROM external_companies;
DELETE FROM employees;
DELETE FROM animals;
DELETE FROM tools;
DELETE FROM barns;
COMMIT;

BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_tools_barn_ref'; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_emp_usages_tool_ref'; EXCEPTION WHEN OTHERS THEN NULL; END;
*/

-- Insert 60 Barns
BEGIN
    FOR i IN 1..60 LOOP
        INSERT INTO barns VALUES (
            t_barn('BARN'||i, 500, 'Farm Sector '||i, 0)
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inserted 60 barns.');
END;
/

-- Insert 600 Tools (~10 tools distributed per barn)
BEGIN
    FOR i IN 1..600 LOOP
        INSERT INTO tools VALUES (
            t_tool(
                'TOOL'||i, 
                50.00, 
                'Generic Tool', 
                'Standard Equipment',
                (SELECT REF(b) FROM barns b WHERE b.barn_id = 'BARN'||TO_CHAR(MOD(i,60)+1))
            )
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inserted 600 tools.');
END;
/

-- Insert 20 Maintenance Employees
BEGIN
    FOR i IN 1..20 LOOP
        INSERT INTO employees VALUES (
            t_employee(
                'EMP'||i, 
                'John', 
                'Doe '||i, 
                2000.00,
                t_address('Main St', 'City', 'PR', '00000'),
                t_usage_nt(), 
                t_cured_nt()
            )
        );
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inserted 20 employees.');
END;
/

-- Insert 200 Tool Usages per Employee (4000 total records in Nested Table)
BEGIN
    FOR i IN 1..20 LOOP
        FOR j IN 1..200 LOOP
            INSERT INTO TABLE(
                SELECT e.tools FROM employees e WHERE e.tax_code = 'EMP'||i
            ) VALUES (
                t_usage(
                    (SELECT REF(t) FROM tools t WHERE t.code = 'TOOL'||TO_CHAR(MOD(j,600)+1)),
                    SYSDATE - 1
                )
            );
        END LOOP;
        -- Commit per employee
        COMMIT; 
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Inserted 4000 tool usages.');
END;
/


-- UPDATE STATISTICS: Required to allow the Cost-Based Optimizer to recognize the new data volumes.
-- ----------------------------------------------------------------------------
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'BARNS');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'TOOLS');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'EMPLOYEES');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'EMP_USAGES_NT_TAB');

-- EXPLAIN PLAN BEFORE INDEXES
-- OP2: Tools available in a specific barn
SELECT 'OP2 BEFORE INDEX: Tools in BARN5' AS status FROM DUAL;
EXPLAIN PLAN FOR
    SELECT t.code, t.tool_type, t.tool_description, t.price
    FROM tools t
    WHERE t.barn_ref = (SELECT REF(b) FROM barns b WHERE b.barn_id = 'BARN5');
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- OP4: Complete tool history for a specific employee
SELECT 'OP4 BEFORE INDEX: Tool usages by EMP1' AS status FROM DUAL;
EXPLAIN PLAN FOR
    SELECT *
    FROM v_employee_tool
    WHERE employee_tax_code = 'EMP1';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Index Creation
CREATE INDEX idx_tools_barn_ref ON tools(barn_ref);
CREATE INDEX idx_emp_usages_tool_ref ON emp_usages_nt_tab(tool_ref);

-- Update statistics
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'TOOLS');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'EMP_USAGES_NT_TAB');

-- EXPLAIN PLAN AFTER INDEXES
-- OP2 AFTER
SELECT 'OP2 AFTER INDEX: Tools in BARN5' AS status FROM DUAL;
EXPLAIN PLAN FOR
    SELECT t.code, t.tool_type, t.tool_description, t.price
    FROM tools t
    WHERE t.barn_ref = (SELECT REF(b) FROM barns b WHERE b.barn_id = 'BARN5');
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- OP4 AFTER
SELECT 'OP4 AFTER INDEX: Tool usages by EMP1' AS status FROM DUAL;
EXPLAIN PLAN FOR
    SELECT *
    FROM v_employee_tool
    WHERE employee_tax_code = 'EMP1';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);