import graphy2

# Sample data
products = [
    {"name": "Product A", "price": 100},
    {"name": "Product B", "price": 150},
    {"name": "Product C", "price": 200},
    {"name": "Product D", "price": 75},
    {"name": "Product E", "price": 125}
]

# Extract product names and prices
product_names = [product["name"] for product in products]
product_prices = [product["price"] for product in products]

# Create an ASCII bar graph
graphy2.BarGraph(
    title="Product Prices",
    x_label="Products",
    y_label="Price",
    x_data=product_names,
    y_data=product_prices,
    bar_char="#",
    max_bar_length=20
).draw()