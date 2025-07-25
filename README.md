# Simple Schema Bot  
*A minimal LangGraph pipeline that introspects a PostgreSQL database and explains its schema with a local Ollama LLM.*

---

## What it does
1. Spins up PostgreSQL 15 + pgvector in Docker (one command).  
2. Uses **LangGraph** to fetch the live schema.  
3. Sends the raw DDL to **Ollama** (`llama3.2` by default) for a human-readable summary.  
4. Runs entirely on your Fedora 42 laptop—no cloud calls.

---

## Quick start (Fedora 42)

```bash
# 1. Clone & enter repo
git clone https://github.com/Capybaralifestyle/simple_schema_bot.git
cd simple_schema_bot

# 2. Install Python deps
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Start PostgreSQL
docker compose up -d           # http://localhost:8080 → Adminer

# 4. Pull an Ollama model (first time only)
ollama pull llama3.2

# 5. Run the bot
python schema_bot_with_llm.py
