import asyncio, asyncpg
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

DB_URI = "postgresql://postgres:example@localhost:5432/postgres"

class State(TypedDict):
    ascii: str    # the final bar chart

async def fetch_and_chart(state: State) -> State:
    conn = await asyncpg.connect(DB_URI)
    rows = await conn.fetch(
        "SELECT name, price FROM products ORDER BY price"
    )
    await conn.close()

    # Build simple ASCII bar chart
    max_price = max(r["price"] for r in rows) if rows else 1
    scale = 40 / max_price               # 40 chars wide max
    bars = [
        f"{r['name']:<12} │{'█' * int(r['price'] * scale)} {r['price']}"
        for r in rows
    ]
    chart = "\n".join(bars)
    return {"ascii": chart or "No products"}

workflow = StateGraph(State)
workflow.add_node("chart", fetch_and_chart)
workflow.add_edge(START, "chart")
workflow.add_edge("chart", END)

app = workflow.compile()

if __name__ == "__main__":
    result = asyncio.run(app.ainvoke({"ascii": ""}))
    print(result["ascii"])
