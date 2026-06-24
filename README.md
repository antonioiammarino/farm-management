# Farm Management System

This repository contains the complete implementation of the "Ranch Holdings" database project. The project involves designing and implementing an **Object-Relational Database** in Oracle 23c and a corresponding **Web Application** to interact with the data and showcase the advanced database features.

## 📂 Repository Structure

The project is divided into two main components:

```
farm-management/
├── sql files/           # Oracle Object-Relational Database scripts
│   ├── initial schema.sql
│   ├── insert.sql
│   ├── indexes.sql
│   ├── views.sql
│   ├── procedure deal.sql
│   ├── procedure tool usage.sql
│   └── trigger *.sql
└── farm-webapp/         # Python/Flask + Vanilla JS Web Application
    ├── backend/
    ├── frontend/
    ├── Project_Report.md
    └── README.md
```

## 🗄️ Database Design (`sql files/`)

The database is built on **Oracle 23c Free** utilizing its Object-Oriented capabilities.

To deploy the database, execute the SQL scripts sequentially from the `sql files/` directory in your Oracle environment.

## 🌐 Web Application (`farm-webapp/`)

To conclude the project, a custom web dashboard was built to validate the schema design in a real-world scenario.

### Architecture
It follows a 3-tier architecture:
1.  **Frontend:** HTML5, CSS3 (Light theme), and Vanilla JavaScript (Fetch API).
2.  **Backend:** Python with Flask microframework and `oracledb` Thin mode.
3.  **Database:** Oracle 23c Free Docker Container.

### Features
*   **Dashboard:** High-level summary of active schema elements using aggregated counts.
*   **Animals:** Displays the livestock registry, pulling location data from the associated Barn object via `DEREF`.
*   **Barn Tools:** Visualizes inventory using the `v_barn_tools` object view.
*   **Tool Usage:** Traces the complex relationship between employees, tools, and barns using `v_employee_tool`.

### How to Run the Web App
1.  **Ensure Oracle is running** and the schema is deployed.
2.  **Configure environment variables:**
    ```bash
    export DB_USER=...
    export DB_PASSWORD=...
    export DB_DSN=...
    ```
3.  **Install dependencies and run the backend:**
    ```bash
    cd farm-webapp/backend
    conda create -n webapp_db python=3.11 -y
    conda activate webapp_db
    pip install -r requirements.txt
    python app.py
    ```
4.  Open your browser to `http://127.0.0.1:5000`

---

**Author:** Antonio Iammarino
