CREATE OR REPLACE VIEW v_barn_tools AS
SELECT DEREF(t.barn_ref).barn_id AS barn_id,
       DEREF(t.barn_ref).barn_location AS location,
       DEREF(t.barn_ref).area AS barn_area,
       t.code AS tool_code,
       t.tool_type,
       t.tool_description,
       t.price
FROM tools t
WHERE t.barn_ref IS NOT NULL
ORDER BY barn_id, tool_type;

CREATE OR REPLACE VIEW v_employee_tool AS
SELECT e.tax_code AS employee_tax_code,
       e.surname,
       e.emp_name,
       u.date_use,
       DEREF(u.tool_ref).code AS tool_code,
       DEREF(u.tool_ref).tool_description AS description,
       DEREF(u.tool_ref).tool_type AS type,
       DEREF(DEREF(u.tool_ref).barn_ref).barn_id AS located_in_barn,
       DEREF(DEREF(u.tool_ref).barn_ref).barn_location AS barn_location
FROM employees e, TABLE(e.tools) u
/


SELECT * FROM v_barn_tools;

SELECT * FROM v_employee_tool;