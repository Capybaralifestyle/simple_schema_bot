import asyncio, asyncpg
from langgraph.graph import StateGraph, START, END
from typing import TypedDict
from langchain_ollama import ChatOllama
from langchain_core.messages import HumanMessage, SystemMessage

# ---------- LangGraph State ----------
class State(TypedDict):
    schema: str      # raw DDL dumped from Postgres
    summary: str     # human-readable description produced by the LLM

# ---------- Configuration ----------
DB_URI = "postgresql://postgres:example@localhost:5432/postgres"
OLLAMA_MODEL = "llama3.2"

# ---------- Node 1: fetch schema ----------
async def fetch_schema(state: State) -> State:
    conn = await asyncpg.connect(DB_URI)
    rows = await conn.fetch(
        """
        SELECT
          'CREATE TABLE '||quote_ident(t.tablename)||' ('||
          string_agg(
            quote_ident(c.column_name)||' '||c.data_type||
            CASE WHEN c.character_maximum_length IS NOT NULL
                 THEN '('||c.character_maximum_length||')' ELSE '' END||
            CASE WHEN c.is_nullable='NO' THEN ' NOT NULL' ELSE '' END||
            CASE WHEN c.column_default IS NOT NULL
                 THEN ' DEFAULT '||c.column_default ELSE '' END,
            ', ' ORDER BY c.ordinal_position
          )||');' AS ddl
        FROM pg_tables t
        JOIN information_schema.columns c
          ON c.table_name = t.tablename
        WHERE t.schemaname = 'public'
        GROUP BY t.tablename
        ORDER BY t.tablename;
        """
    )
    await conn.close()
    return {"schema": "\n".join(r["ddl"] for r in rows), "summary": ""}

# ---------- Node 2: LLM summarizer ----------
async def summarize_schema(state: State) -> State:
    llm = ChatOllama(model=OLLAMA_MODEL, temperature=0.1)
    messages = [
        SystemMessage(content=(
            "You are a helpful database assistant. "
            "Explain the schema in plain English and mention any relations you detect."
        )),
        HumanMessage(content=state["schema"])
    ]
    response = await llm.ainvoke(messages)
    return {"summary": response.content}

# ---------- Build the graph ----------
workflow = StateGraph(State)
workflow.add_node("fetch_schema", fetch_schema)
workflow.add_node("summarize_schema", summarize_schema)

workflow.add_edge(START, "fetch_schema")
workflow.add_edge("fetch_schema", "summarize_schema")
workflow.add_edge("summarize_schema", END)

app = workflow.compile()

# ---------- Run ----------
if __name__ == "__main__":
    final = asyncio.run(app.ainvoke({"schema": "", "summary": ""}))
    print("=== Raw Schema ===")
    print(final["schema"])
    print("\n=== LLM Summary ===")
    print(final["summary"])