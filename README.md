# 🧠 Codebase Genius

AI-powered Agentic Code-Documentation System built with JacLang + Streamlit

---

## 🚀 Overview

Codebase Genius automatically analyzes any public GitHub repository and generates high-quality Markdown documentation including:

### 🗂 Features

- Repository mapping and file-tree visualization
- Code Context Graph (CCG) built using Tree-sitter for Python, Jac, and JavaScript
- README summarization powered by byLLM (GPT/Gemini)
- Final structured Markdown documentation (`outputs/<repo>/docs.md`)

---

## 🧩 System Architecture

```
Streamlit UI  →  Jac Server (app.jac)
                      ↓
        ┌──────────────────────────┐
        │ code_genius (Supervisor) │
        ├──────────────────────────┤
        │  repo_mapper   → clones repo & builds manifest.json
        │  code_analyzer  → parses repo via Tree-sitter, builds CCG
        │  docgenie      → summarises README (byLLM) + generates docs
        └──────────────────────────┘
```

---

## 📂 Project Structure

```
codebase_genius/
│
├── app.jac              # Main Jac backend (served)
├── repo_mapper.jac      # Agent 1 – Repository Mapper
├── code_analyzer.jac    # Agent 2 – Tree-sitter CCG Analyzer
├── docgenie.jac         # Agent 3 – byLLM Documentation Generator
├── main.py              # Streamlit frontend UI
├── outputs/             # Generated results (manifest, ccg, docs)
└── requirements.txt     # Python dependencies
```

---

## ⚙️ Installation Guide

### 1️⃣ Clone the Repository

```bash
git clone <your-repo-url>
cd codebase_genius
```

### 2️⃣ Create and Activate a Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

### 3️⃣ Install Dependencies

```bash
pip install -r requirements.txt
```

### 4️⃣ Create `requirements.txt` (if not already present)

```text
jaclang
streamlit
tree_sitter
byllm
requests
```

### 5️⃣ Set Up Environment Variables

Create a `.env` file in the root directory:

```bash
OPENAI_API_KEY=sk-your-openai-key
# or
GEMINI_API_KEY=your-gemini-key
```

---

## ▶️ Running the Backend (Jac)

### Step 1: Serve the Jac Backend

```bash
jac serve app.jac
```

The Jac server starts at **[http://localhost:8000](http://localhost:8000)** and exposes the following endpoints:

### Endpoints

- **POST /walker_run** → Run any Jac walker (e.g., code_genius, ping)
- **GET /report_log** → Fetch live logs from Jac `report()`
- **GET /graph_list** → List all active graphs/walkers for debugging

### Step 2: Example API Call

```bash
curl -X POST http://localhost:8000/walker_run \
     -H "Content-Type: application/json" \
     -d '{"name": "code_genius", "ctx": {"repo_url": "https://github.com/psf/requests"}}'
```

---

## 💻 Running the Frontend (Streamlit)

### Step 1: Start Streamlit

```bash
streamlit run main.py
```

### Step 2: Open the UI

Visit: [http://localhost:8501](http://localhost:8501)

### Step 3: Generate Documentation

1. Paste a **public GitHub repository URL**.
2. Click **"🚀 Generate Documentation"**.
3. Watch logs as the Jac agents execute.
4. View and download the generated Markdown documentation.

---

## 📁 Output Files

### 📄 manifest.json

Repository file tree and metadata.

### 🌳 ccg.json

Code Context Graph (nodes and edges via Tree-sitter).

### 🧩 ccg_diagram.md

Mermaid diagram representing the generated Code Context Graph.

### 📘 docs.md

Final Markdown documentation containing:

- LLM-based README summary (byLLM)
- Auto-generated API reference

---

## 🧪 Sample Output

```
outputs/requests/docs.md
├── # Documentation for requests
├── ## README Summary
│   → (Generated via byLLM)
├── ## API Reference
│   – function get (file: requests/api.py)
│   – class Session (file: requests/sessions.py)
```

---

## 🧰 Dependencies and Tools

### Dependencies

| Tool        | Purpose                                     |
| ----------- | ------------------------------------------- |
| JacLang     | Backend language for agent coordination     |
| byLLM       | LLM connector for README summarization      |
| Tree-sitter | Code parser for Python, Jac, and JavaScript |
| Streamlit   | Frontend UI                                 |
| Git         | Repository cloning                          |

---

## 💡 Development Notes

### Key Points

- Add additional Tree-sitter grammars under `vendor/tree-sitter-*` to support other languages.
- Extend DocGenie to include diagrams and deeper LLM-based analysis.
- Poll `/report_log` endpoint from Streamlit for live updates.
- Keep `.env` private; never push it to GitHub.
- Add `outputs/` to `.gitignore` to avoid large file commits.

---

## 📜 Endpoints Summary

### API Endpoints

| Method | Endpoint      | Description                             |
| ------ | ------------- | --------------------------------------- |
| POST   | `/walker_run` | Runs a Jac walker (e.g., code_genius)   |
| GET    | `/report_log` | Fetches Jac backend logs                |
| GET    | `/graph_list` | Lists all active Jac graphs and walkers |

---

## 🧠 How the System Works

### Execution Flow

1. Streamlit sends the GitHub repo URL to Jac backend via `/walker_run`.
2. Jac server launches the `code_genius` walker (supervisor).
3. `repo_mapper` clones and maps the repository, writing `manifest.json`.
4. `code_analyzer` builds a Code Context Graph (CCG) using Tree-sitter.
5. `docgenie` summarizes README via byLLM and generates Markdown documentation.
6. Streamlit reads `outputs/<repo>/docs.md` and displays it in the UI.

---

## 🧩 System Flow Diagram

```mermaid
graph LR
A[Streamlit UI] -->|POST /walker_run| B[Jac Server (app.jac)]
B -->|spawn| C[repo_mapper]
C --> D[code_analyzer]
D --> E[docgenie]
E --> F[outputs/<repo>/docs.md]
F -->|load| A
```

---

## 🧾 requirements.txt

```text
jaclang
streamlit
tree_sitter
byllm
requests
```

---

## 🧰 .env Template

```bash
# byLLM API keys
OPENAI_API_KEY=sk-your-openai-key
# or
GEMINI_API_KEY=your-gemini-key
```

---

## 🧩 Example Commands

### Run the Backend

```bash
jac serve app.jac
```

### Run the Frontend

```bash
streamlit run main.py
```

### Trigger via cURL

```bash
curl -X POST http://localhost:8000/walker_run \
     -H "Content-Type: application/json" \
     -d '{"name": "code_genius", "ctx": {"repo_url": "https://github.com/psf/requests"}}'
```


