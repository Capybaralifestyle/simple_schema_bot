#!/usr/bin/env bash
set -e

docker exec -i lg-pg-db-1 psql -U postgres -d postgres <<'SQL'
-- Insert roles
INSERT INTO roles (name) VALUES
  ('admin'),
  ('customer')
ON CONFLICT DO NOTHING;

-- Insert users
INSERT INTO users (username, email, password, full_name, role_id) VALUES
  ('alice',  'alice@example.com',  'hash123', 'Alice Smith', 2),
  ('bob',    'bob@example.com',    'hash456', 'Bob Johnson', 2),
  ('carol',  'carol@example.com',  'hash789', 'Carol Davis', 1)
ON CONFLICT DO NOTHING;

-- Insert products
INSERT INTO products (name, description, price, stock) VALUES
  ('Laptop',         '15-inch ultrabook',                 999.99, 10),
  ('Smartphone',     '5G flagship phone',                 699.99, 25),
  ('Headphones',     'Noise-cancelling over-ear',         149.99, 50),
  ('Keyboard',       'Mechanical RGB',                     89.99, 30),
  ('Mouse',          'Wireless ergonomic',                 49.99, 40)
ON CONFLICT DO NOTHING;

-- Insert tags
INSERT INTO tags (name) VALUES
  ('electronics'), ('sale'), ('gaming'), ('accessory'), ('mobile')
ON CONFLICT DO NOTHING;

-- Link tags to products
INSERT INTO product_tags (product_id, tag_id)
SELECT p.id, t.id
FROM products p
JOIN tags t ON
  (p.name = 'Laptop'      AND t.name IN ('electronics','sale')) OR
  (p.name = 'Smartphone'  AND t.name IN ('electronics','mobile')) OR
  (p.name = 'Headphones'  AND t.name IN ('electronics','accessory')) OR
  (p.name = 'Keyboard'    AND t.name IN ('gaming','accessory')) OR
  (p.name = 'Mouse'       AND t.name IN ('accessory','gaming'));

-- Insert orders
INSERT INTO orders (user_id, status, total)
SELECT u.id, 'completed', 1149.97
FROM users u WHERE u.username = 'alice';

-- Order items for Alice’s order
INSERT INTO order_items (order_id, product_id, quantity, price_each)
SELECT o.id, p.id, 1, p.price
FROM orders o
JOIN users u ON u.id = o.user_id AND u.username = 'alice'
JOIN products p ON p.name IN ('Laptop','Headphones');

-- Payment record
INSERT INTO payments (order_id, amount, method)
SELECT o.id, o.total, 'card'
FROM orders o
JOIN users u ON u.id = o.user_id AND u.username = 'alice';

-- Reviews
INSERT INTO reviews (product_id, user_id, rating, comment)
SELECT p.id, u.id, 5, 'Excellent build quality!'
FROM products p, users u
WHERE p.name = 'Laptop' AND u.username = 'alice'
ON CONFLICT DO NOTHING;
SQL
echo "✅ Sample data inserted!"
