// Config
const API = "/api";

let allAnimals = [];
let allBarnTools = [];
let allToolUsage = [];
let currentSection = "dashboard";

// Navigation
const SECTIONS = {
  dashboard: { title: "Dashboard", subtitle: "Farm overview and statistics" },
  animals: { title: "Animals", subtitle: "All animals with barn assignment via DEREF" },
  barntools: { title: "Barn Tools", subtitle: "Tool inventory per barn — v_barn_tools view" },
  toolusage: { title: "Tool Usage", subtitle: "Employee tool usage history — v_employee_tool view" },
  arch: { title: "System Design", subtitle: "Three-layer architecture overview" },
};

function showSection(name) {
  // Hide all
  document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
  document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));

  // Show target
  document.getElementById(`section-${name}`).classList.add("active");
  document.getElementById(`nav-${name}`).classList.add("active");

  // Update topbar
  const meta = SECTIONS[name];
  document.getElementById("topbar-title").textContent = meta.title;
  document.getElementById("topbar-subtitle").textContent = meta.subtitle;

  currentSection = name;

  // Lazy-load data
  if (name === "dashboard") loadDashboard();
  if (name === "animals") loadAnimals();
  if (name === "barntools") loadBarnTools();
  if (name === "toolusage") loadToolUsage();
}

// Search
function onSearch(val) {
  if (currentSection === "animals") filterAnimals();
  if (currentSection === "barntools") filterBarnTools();
  if (currentSection === "toolusage") filterToolUsage();
}

// Helpers
async function fetchJSON(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

function loadingRow(cols, msg = "Loading…") {
  return `<tr><td colspan="${cols}">
    <div class="state-box">
      <div class="spinner"></div>
      <span class="state-text">${msg}</span>
    </div></td></tr>`;
}

function emptyRow(cols, msg = "No data found.") {
  return `<tr><td colspan="${cols}">
    <div class="state-box">
      <span class="state-icon">🔍</span>
      <span class="state-text">${msg}</span>
    </div></td></tr>`;
}

function typeBadge(type) {
  if (!type) return "—";
  const t = type.toLowerCase();
  if (t === "horse") return `<span class="badge badge-horse">🐴 Horse</span>`;
  if (t === "cattle") return `<span class="badge badge-cattle">🐄 Cattle</span>`;
  if (t === "swine") return `<span class="badge badge-swine">🐖 Swine</span>`;
  return `<span class="badge badge-tool">${type}</span>`;
}

function sexBadge(sex) {
  if (!sex) return "—";
  const s = sex.trim().toUpperCase();
  if (s === "M") return `<span class="badge badge-m">♂ M</span>`;
  if (s === "F") return `<span class="badge badge-f">♀ F</span>`;
  return sex;
}

function escHtml(str) {
  if (str == null) return "—";
  return String(str)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;")
    .replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function matchSearch(row, fields) {
  const q = (document.getElementById("global-search")?.value || "").toLowerCase();
  if (!q) return true;
  return fields.some(f => String(row[f] || "").toLowerCase().includes(q));
}

// DASHBOARD
async function loadDashboard() {
  try {
    const data = await fetchJSON(`${API}/stats`);
    const ac = data.animal_counts || {};

    const cards = [
      {
        icon: "🐄",
        value: data.total_animals ?? 0,
        label: "Total Animals",
        extra: `
          <div class="animal-breakdown">
            ${ac["Horse"] ? `<div class="animal-chip">🐴 <span>${ac["Horse"]}</span> Horse</div>` : ""}
            ${ac["Cattle"] ? `<div class="animal-chip">🐄 <span>${ac["Cattle"]}</span> Cattle</div>` : ""}
            ${ac["Swine"] ? `<div class="animal-chip">🐖 <span>${ac["Swine"]}</span> Swine</div>` : ""}
          </div>`
      },
      { icon: "🏠", value: data.barns ?? 0, label: "Barns", extra: "" },
      { icon: "🔧", value: data.tools ?? 0, label: "Tools", extra: "" },
      { icon: "👷", value: data.employees ?? 0, label: "Employees", extra: "" },
      { icon: "🏢", value: data.companies ?? 0, label: "External Companies", extra: "" },
    ];

    document.getElementById("stats-grid").innerHTML = cards.map(c => `
      <div class="stat-card">
        <div class="stat-icon">${c.icon}</div>
        <div class="stat-value">${c.value}</div>
        <div class="stat-label">${c.label}</div>
        ${c.extra}
      </div>`).join("");

    // Update DB dot to green (connected)
    document.getElementById("db-dot").style.background = "var(--success)";
  } catch (err) {
    document.getElementById("stats-grid").innerHTML =
      `<div class="stat-card"><div class="state-box"><span class="state-icon">⚠️</span>
       <span class="state-text">Cannot connect to API: ${escHtml(err.message)}</span></div></div>`;
    document.getElementById("db-dot").style.background = "var(--danger, #ef4444)";
  }
}

// ANIMALS
async function loadAnimals() {
  if (allAnimals.length) { filterAnimals(); return; }
  document.getElementById("animals-tbody").innerHTML = loadingRow(8);

  try {
    allAnimals = await fetchJSON(`${API}/animals`);
    filterAnimals();
  } catch (err) {
    document.getElementById("animals-tbody").innerHTML =
      `<tr><td colspan="8"><div class="state-box">⚠️ ${escHtml(err.message)}</div></td></tr>`;
  }
}

function filterAnimals() {
  const typeF = document.getElementById("filter-animal-type")?.value || "";
  const sexF = document.getElementById("filter-animal-sex")?.value || "";

  const rows = allAnimals.filter(a =>
    (!typeF || a.type === typeF) &&
    (!sexF || (a.sex || "").trim().toUpperCase() === sexF) &&
    matchSearch(a, ["code", "type", "barn_id", "barn_location"])
  );

  document.getElementById("animals-count").textContent = `${rows.length} records`;

  if (!rows.length) {
    document.getElementById("animals-tbody").innerHTML = emptyRow(8);
    return;
  }

  document.getElementById("animals-tbody").innerHTML = rows.map(a => `
    <tr>
      <td><strong>${escHtml(a.code)}</strong></td>
      <td>${typeBadge(a.type)}</td>
      <td>${sexBadge(a.sex)}</td>
      <td>${a.weight != null ? a.weight.toFixed(1) : "—"}</td>
      <td>${escHtml(a.birth)}</td>
      <td>${a.last_shoeing ? escHtml(a.last_shoeing) : '<span style="color:var(--text-muted)">N/A</span>'}</td>
      <td><span class="badge badge-tool">${escHtml(a.barn_id)}</span></td>
      <td>${escHtml(a.barn_location)}</td>
    </tr>`).join("");
}

// BARN TOOLS
async function loadBarnTools() {
  if (allBarnTools.length) { filterBarnTools(); return; }
  document.getElementById("barntools-tbody").innerHTML = loadingRow(7);

  try {
    allBarnTools = await fetchJSON(`${API}/barn-tools`);

    // Populate barn filter
    const barns = [...new Set(allBarnTools.map(t => t.barn_id))].sort();
    const barnSel = document.getElementById("filter-barn");
    barns.forEach(b => {
      const o = document.createElement("option");
      o.value = b; o.textContent = b;
      barnSel.appendChild(o);
    });

    // Populate tool type filter
    const types = [...new Set(allBarnTools.map(t => t.tool_type).filter(Boolean))].sort();
    const typeSel = document.getElementById("filter-tool-type");
    types.forEach(t => {
      const o = document.createElement("option");
      o.value = t; o.textContent = t;
      typeSel.appendChild(o);
    });

    filterBarnTools();
  } catch (err) {
    document.getElementById("barntools-tbody").innerHTML =
      `<tr><td colspan="7"><div class="state-box">⚠️ ${escHtml(err.message)}</div></td></tr>`;
  }
}

function filterBarnTools() {
  const barnF = document.getElementById("filter-barn")?.value || "";
  const typeF = document.getElementById("filter-tool-type")?.value || "";

  const rows = allBarnTools.filter(t =>
    (!barnF || t.barn_id === barnF) &&
    (!typeF || t.tool_type === typeF) &&
    matchSearch(t, ["barn_id", "location", "tool_code", "description", "tool_type"])
  );

  document.getElementById("barntools-count").textContent = `${rows.length} records`;

  if (!rows.length) {
    document.getElementById("barntools-tbody").innerHTML = emptyRow(7);
    return;
  }

  document.getElementById("barntools-tbody").innerHTML = rows.map(t => `
    <tr>
      <td><span class="badge badge-tool">${escHtml(t.barn_id)}</span></td>
      <td>${escHtml(t.location)}</td>
      <td>${t.barn_area != null ? t.barn_area.toFixed(0) + " m²" : "—"}</td>
      <td><strong>${escHtml(t.tool_code)}</strong></td>
      <td>${escHtml(t.tool_type)}</td>
      <td>${escHtml(t.description)}</td>
      <td>${t.price != null ? "€ " + t.price.toFixed(2) : "—"}</td>
    </tr>`).join("");
}

// TOOL USAGE
async function loadToolUsage() {
  if (allToolUsage.length) { filterToolUsage(); return; }
  document.getElementById("toolusage-tbody").innerHTML = loadingRow(8);

  try {
    allToolUsage = await fetchJSON(`${API}/employee-tools`);

    // Populate employee filter
    const empMap = {};
    allToolUsage.forEach(r => { empMap[r.tax_code] = `${r.surname} ${r.name}`; });
    const empSel = document.getElementById("filter-employee");
    Object.entries(empMap).sort((a, b) => a[1].localeCompare(b[1])).forEach(([k, v]) => {
      const o = document.createElement("option");
      o.value = k; o.textContent = v;
      empSel.appendChild(o);
    });

    filterToolUsage();
  } catch (err) {
    document.getElementById("toolusage-tbody").innerHTML =
      `<tr><td colspan="8"><div class="state-box">⚠️ ${escHtml(err.message)}</div></td></tr>`;
  }
}

function filterToolUsage() {
  const empF = document.getElementById("filter-employee")?.value || "";

  const rows = allToolUsage.filter(r =>
    (!empF || r.tax_code === empF) &&
    matchSearch(r, ["surname", "name", "tax_code", "tool_code", "description", "barn_id"])
  );

  document.getElementById("toolusage-count").textContent = `${rows.length} records`;

  if (!rows.length) {
    document.getElementById("toolusage-tbody").innerHTML = emptyRow(8);
    return;
  }

  document.getElementById("toolusage-tbody").innerHTML = rows.map(r => `
    <tr>
      <td><strong>${escHtml(r.surname)}</strong> ${escHtml(r.name)}</td>
      <td><code style="color:var(--text-muted);font-size:11px">${escHtml(r.tax_code)}</code></td>
      <td>${escHtml(r.date_use)}</td>
      <td><strong>${escHtml(r.tool_code)}</strong></td>
      <td>${escHtml(r.description)}</td>
      <td>${r.tool_type ? `<span class="badge badge-tool">${escHtml(r.tool_type)}</span>` : "—"}</td>
      <td><span class="badge badge-tool">${escHtml(r.barn_id)}</span></td>
      <td>${escHtml(r.barn_location)}</td>
    </tr>`).join("");
}

// Init
document.addEventListener("DOMContentLoaded", () => {
  loadDashboard();
});
