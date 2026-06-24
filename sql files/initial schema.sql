-- Address Type
CREATE OR REPLACE TYPE t_address AS OBJECT (
    street VARCHAR2(30),
    city VARCHAR2(30),
    province VARCHAR2(30),
    postalcode VARCHAR2(30)
);
/

-- External Company has a list of phones (assume max 10)
CREATE OR REPLACE TYPE t_phone_varray AS VARRAY(10) OF VARCHAR2(20);
/

CREATE OR REPLACE TYPE t_barn AS OBJECT (
    barn_id VARCHAR2(30),
    area NUMBER(8,2),
    barn_location VARCHAR2(30),
    current_occupancy INTEGER
);
/

CREATE OR REPLACE TYPE t_tool AS OBJECT (
    code VARCHAR2(30),
    price NUMBER(5,2),
    tool_type VARCHAR2(30),
    tool_description VARCHAR2(30), 
    barn_ref REF t_barn
);
/

CREATE OR REPLACE TYPE t_usage AS OBJECT (
    tool_ref REF t_tool,
    date_use DATE
);
/
CREATE OR REPLACE TYPE t_usage_nt AS TABLE OF t_usage;
/

CREATE OR REPLACE TYPE t_animal AS OBJECT (
    code VARCHAR2(30),
    weight NUMBER(6,2),
    sex CHAR(1),
    birth DATE,
    animal_type VARCHAR2(30),
    last_shoeing DATE,
    barn_ref REF t_barn
);
/

CREATE OR REPLACE TYPE t_cured_nt AS TABLE OF REF t_animal;
/

CREATE OR REPLACE TYPE t_employee AS OBJECT (
    tax_code VARCHAR2(30),
    emp_name VARCHAR2(30),
    surname VARCHAR2(30),
    salary NUMBER(8,2),
    emp_address t_address,        
    tools t_usage_nt,
    animals t_cured_nt
);
/

CREATE OR REPLACE TYPE t_deal AS OBJECT (
    animal_ref REF t_animal,
    date_deal DATE,
    price NUMBER(8,2),
    deal_type CHAR(1)
);
/
CREATE OR REPLACE TYPE t_deal_nt AS TABLE OF t_deal;
/

CREATE OR REPLACE TYPE t_external_company AS OBJECT (
    vat VARCHAR2(30),
    comp_name VARCHAR2(30),
    comp_address t_address,       
    phones t_phone_varray,            
    deals t_deal_nt       
);
/

CREATE TABLE barns OF t_barn (
    CONSTRAINT barn_pk PRIMARY KEY (barn_id),
    CONSTRAINT barn_area_chk CHECK (area > 0)
);

CREATE TABLE tools OF t_tool (
    CONSTRAINT tool_pk PRIMARY KEY (code),
    CONSTRAINT tool_price_chk CHECK (price > 0),
    CONSTRAINT tool_barn_fk FOREIGN KEY (barn_ref) REFERENCES barns
);

CREATE TABLE employees OF t_employee (
    CONSTRAINT employee_pk PRIMARY KEY (tax_code),
    CONSTRAINT emp_salary_chk CHECK (salary > 0)
) 
NESTED TABLE tools STORE AS emp_usages_nt_tab
NESTED TABLE animals STORE AS emp_cured_nt_tab;

CREATE TABLE animals OF t_animal (
    CONSTRAINT animal_pk PRIMARY KEY (code),
    CONSTRAINT animal_sex_chk CHECK (sex IN ('M', 'F')),
    CONSTRAINT animal_weight_chk CHECK (weight > 0),
    CONSTRAINT animal_type_chk CHECK (animal_type IN ('Swine', 'Cattle', 'Horse')), 
    CONSTRAINT animal_barn_fk FOREIGN KEY (barn_ref) REFERENCES barns
);

CREATE TABLE external_companies OF t_external_company (
    CONSTRAINT ext_comp_pk PRIMARY KEY (vat)
)
NESTED TABLE deals STORE AS comp_deals_nt_tab;

ALTER TABLE comp_deals_nt_tab 
ADD CONSTRAINT deal_type_chk CHECK (deal_type IN ('S', 'P'));