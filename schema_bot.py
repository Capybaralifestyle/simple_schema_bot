import asyncio, asyncpg, textwrap
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

class State(TypedDict):
    schema: str          # will hold the final DDL

DB_URI = "postgresql://postgres:example@localhost:5432/postgres"

async def fetch_schema(state: State) -> State:
    conn = await asyncpg.connect(DB_URI)
    # Get tables, columns, PK/FK, indexes
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
    return {"schema": "\n".join(r["ddl"] for r in rows)}

workflow = StateGraph(State)
workflow.add_node("get_schema", fetch_schema)
workflow.add_edge(START, "get_schema")
workflow.add_edge("get_schema", END)

graph = workflow.compile()

if __name__ == "__main__":
    result = asyncio.run(graph.ainvoke({"schema": ""}))
    print("=== PostgreSQL Schema ===")
    print(result["schema"])