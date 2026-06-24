# Ranch Holdings Web App

## Architecture

```
Browser (HTML/CSS/JS)
      ↕  HTTP/JSON  (port 5000)
Flask Backend  (Python + python-oracledb)
      ↕  TCP  (port 1521)
Oracle 23c Free  (Docker · FREEPDB1)
```

## Setup

### Ensure Oracle is running
```bash
docker start oracle-db
```

### Install Python dependencies
```bash
cd backend
pip install -r requirements.txt
```

### Configure DB user

> If you created the schema as user **SYSTEM** in FREEPDB1, nothing needs to be done.
> If you have a dedicated user, export the variables:

```bash
export DB_USER=system
export DB_PASSWORD=EsameOracle123
export DB_DSN=localhost:1521/FREE
```

### Start the backend
```bash
cd backend
python app.py
```

### Open the browser
```
http://localhost:5000
```

## File structure

```
farm-webapp/
├── backend/
│   ├── app.py              # Flask API + static serving
│   └── requirements.txt    # python deps
├── frontend/
│   ├── index.html          # Single-page app
│   ├── style.css           # Dark theme
│   └── app.js              # Fetch API + rendering
└── README.md
```

## Web app sections

| Section | Oracle source | Description |
|---------|-------------|-------------|
| Dashboard | COUNT queries | General statistics |
| Animals | `animals` + DEREF | Animal list with barn |
| Barn Tools | `v_barn_tools` | Tool per barn |
| Tool Usage | `v_employee_tool` | History of tool usage by employee |
| System Design | — | System architecture |
