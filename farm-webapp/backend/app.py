import os
import sys
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
import oracledb
from dotenv import load_dotenv

# Setup
app = Flask(__name__, static_folder="../frontend")
CORS(app)

# Load environment variables from .env file
load_dotenv()


DB_CONFIG = {
    "user": os.getenv("DB_USER", ""),
    "password": os.getenv("DB_PASSWORD", ""),
    "dsn": os.getenv("DB_DSN", "localhost:1521/FREEPDB1"),
}

def get_conn():
    """Return a thin-mode Oracle connection (no Oracle Client required)."""
    return oracledb.connect(**DB_CONFIG)

def rows_to_dicts(cursor):
    """Convert cursor rows to list of dicts using column names."""
    cols = [d[0].lower() for d in cursor.description]
    return [dict(zip(cols, row)) for row in cursor.fetchall()]

def fmt_date(val):
    return val.strftime("%Y-%m-%d") if val else None

# Frontend
@app.route("/")
def index():
    return send_from_directory("../frontend", "index.html")

@app.route("/<path:path>")
def static_files(path):
    return send_from_directory("../frontend", path)

# API: Dashboard stats 
@app.route("/api/stats")
def api_stats():
    try:
        with get_conn() as conn:
            cur = conn.cursor()

            cur.execute("""
                SELECT animal_type, COUNT(*) AS cnt
                FROM animals
                GROUP BY animal_type
            """)
            animal_counts = {r[0]: r[1] for r in cur.fetchall()}

            cur.execute("SELECT COUNT(*) FROM barns")
            barn_count = cur.fetchone()[0]

            cur.execute("SELECT COUNT(*) FROM tools")
            tool_count = cur.fetchone()[0]

            cur.execute("SELECT COUNT(*) FROM employees")
            emp_count = cur.fetchone()[0]

            cur.execute("SELECT COUNT(*) FROM external_companies")
            company_count = cur.fetchone()[0]

        return jsonify({
            "animal_counts": animal_counts,
            "total_animals": sum(animal_counts.values()),
            "barns":         barn_count,
            "tools":         tool_count,
            "employees":     emp_count,
            "companies":     company_count,
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# API: All animals
@app.route("/api/animals")
def api_animals():
    try:
        with get_conn() as conn:
            cur = conn.cursor()
            cur.execute("""
                SELECT
                    a.code,
                    a.animal_type,
                    a.sex,
                    a.weight,
                    a.birth,
                    a.last_shoeing,
                    DEREF(a.barn_ref).barn_id AS barn_id,
                    DEREF(a.barn_ref).barn_location AS barn_location
                FROM animals a
                ORDER BY a.animal_type, a.code
            """)
            results = []
            for row in cur.fetchall():
                results.append({
                    "code":          row[0],
                    "type":          row[1],
                    "sex":           row[2],
                    "weight":        float(row[3]) if row[3] is not None else None,
                    "birth":         fmt_date(row[4]),
                    "last_shoeing":  fmt_date(row[5]),
                    "barn_id":       row[6],
                    "barn_location": row[7],
                })
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# API: Barn tools (via v_barn_tools)
@app.route("/api/barn-tools")
def api_barn_tools():
    try:
        with get_conn() as conn:
            cur = conn.cursor()
            cur.execute("""
                SELECT barn_id, location, barn_area,
                       tool_code, tool_type, tool_description, price
                FROM v_barn_tools
            """)
            results = []
            for row in cur.fetchall():
                results.append({
                    "barn_id":     row[0],
                    "location":    row[1],
                    "barn_area":   float(row[2]) if row[2] is not None else None,
                    "tool_code":   row[3],
                    "tool_type":   row[4],
                    "description": row[5],
                    "price":       float(row[6]) if row[6] is not None else None,
                })
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# API: Employee tool usage (via v_employee_tool)
@app.route("/api/employee-tools")
def api_employee_tools():
    try:
        with get_conn() as conn:
            cur = conn.cursor()
            cur.execute("""
                SELECT employee_tax_code, surname, emp_name,
                       date_use, tool_code, description,
                       type, located_in_barn, barn_location
                FROM v_employee_tool
                ORDER BY surname, date_use DESC
            """)
            results = []
            for row in cur.fetchall():
                results.append({
                    "tax_code":      row[0],
                    "surname":       row[1],
                    "name":          row[2],
                    "date_use":      fmt_date(row[3]),
                    "tool_code":     row[4],
                    "description":   row[5],
                    "tool_type":     row[6],
                    "barn_id":       row[7],
                    "barn_location": row[8],
                })
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# API: Barns list
@app.route("/api/barns")
def api_barns():
    try:
        with get_conn() as conn:
            cur = conn.cursor()
            cur.execute("""
                SELECT barn_id, barn_location, area, current_occupancy
                FROM barns
                ORDER BY barn_id
            """)
            results = []
            for row in cur.fetchall():
                results.append({
                    "barn_id":    row[0],
                    "location":   row[1],
                    "area":       float(row[2]) if row[2] is not None else None,
                    "occupancy":  row[3],
                })
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, port=5000)
