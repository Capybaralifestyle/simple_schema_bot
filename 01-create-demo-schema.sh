#!/usr/bin/env bash
set -e

DB_URI="postgresql://postgres:example@localhost:5432/postgres"

docker exec -i lg-pg-db-1 psql -U postgres -d postgres <<'SQL'
-- Extensions & enums
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TYPE order_status   AS ENUM ('pending','paid','shipped','completed','cancelled');
CREATE TYPE payment_method AS ENUM ('card','paypal','bank_transfer');

-- Roles
CREATE TABLE roles (
    id   SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

-- Users
CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username   TEXT UNIQUE NOT NULL,
    email      TEXT UNIQUE NOT NULL,
    password   TEXT NOT NULL,
    full_name  TEXT,
    role_id    INTEGER REFERENCES roles(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Products
CREATE TABLE products (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    description TEXT,
    price       NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock       INTEGER NOT NULL CHECK (stock >= 0),
    created_at  TIMESTAMP DEFAULT NOW()
);

-- Orders
CREATE TABLE orders (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID REFERENCES users(id),
    status     order_status DEFAULT 'pending',
    total      NUMERIC(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Order items
CREATE TABLE order_items (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id   UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    quantity   INTEGER NOT NULL CHECK (quantity > 0),
    price_each NUMERIC(10,2) NOT NULL
);

-- Payments
CREATE TABLE payments (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id    UUID REFERENCES orders(id) ON DELETE CASCADE,
    amount      NUMERIC(10,2) NOT NULL,
    method      payment_method NOT NULL,
    paid_at     TIMESTAMP DEFAULT NOW()
);

-- Reviews
CREATE TABLE reviews (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
    rating     INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment    TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Tags
CREATE TABLE tags (
    id   SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

-- Product-Tag relation
CREATE TABLE product_tags (
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    tag_id     INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, tag_id)
);
SQL
echo "✅ Schema created!"
