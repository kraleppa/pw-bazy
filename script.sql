/* Wykorzystywany silnik baz danych to postgresql 13 */

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO public;


/* Tabele (związane z adresowaniem) */


CREATE TABLE markets (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE countries (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL,
	
   	market_id INTEGER NOT NULL REFERENCES markets(id)
);

CREATE TABLE states (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	
 	country_id INTEGER NOT NULL REFERENCES countries(id)
);

CREATE TABLE cities (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	postal_code VARCHAR(255),
	
 	state_id INTEGER NOT NULL REFERENCES states(id)
);

/* Dane testowe */

INSERT INTO markets("name") VALUES('test market 1');
INSERT INTO countries("name", "market_id") VALUES('test country 1', 1);
INSERT INTO states("name", "country_id") VALUES('test state 1', 1);
INSERT INTO cities("name", "postal_code", "state_id") VALUES('test city 1', '31-072', 1);


/* Tabele związane z produktami */


CREATE TABLE categories (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL
);


CREATE TABLE subcategories (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	
   	category_id INTEGER NOT NULL REFERENCES categories(id)
);

CREATE TABLE products (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	
   	subcategory_id INTEGER NOT NULL REFERENCES subcategories(id)
);


/* Dane testowe */

INSERT INTO categories("name") VALUES('test category 1');
INSERT INTO subcategories("name", "category_id") VALUES('test subcat 1', 1);
INSERT INTO products("name", "subcategory_id") VALUES('test product 1', 1);


/* Tabele związane z klientami */


CREATE TABLE segments (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL
);


CREATE TABLE customers (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	
   	segment_id INTEGER NOT NULL REFERENCES segments(id)
);

/* Dane testowe */

INSERT INTO segments("name") VALUES('test segment 1');
INSERT INTO customers("name", "segment_id") VALUES('test customer 1', 1);


/* Ship modes */


CREATE TABLE ship_modes (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL
);

/* Dane testowe */

INSERT INTO ship_modes("name") VALUES('test shipmode 1');


/* Tabele związane z zamówieniami */


CREATE TABLE orders (
	id SERIAL PRIMARY KEY,
	
	order_date DATE NOT NULL,
	ship_date DATE,
	
   	city_id INTEGER NOT NULL REFERENCES cities(id),
   	customer_id INTEGER NOT NULL REFERENCES customers(id),
   	ship_mode_id INTEGER NOT NULL REFERENCES ship_modes(id)
);

/* Z racji na to że korzystam z postgresql zdecydowałem sie reprezentować
 * wartości "pieniężne" jako integer, gdzie zamiast liczby dolarów przetrzymuje
 * liczbę centów. Jest to powszechna metoda która zmniejsza problem
 * nieprecyzjnej reprezentacji liczb zmiennoprzecinkowych a zarazem najprosztsza
 * 
 * Tak więc, zapis w bazie jeżeli wartość pola profit wynosi 6215
 * To zsyk tak naprawdę wyniósł 62,15$
 * 
 * Jeżeli w bazie będzie 3000 to tak naprawdę będzie to 30,00$
 * Itd
 * */
CREATE TABLE order_products (
	id SERIAL PRIMARY KEY,
	
	sales INTEGER NOT NULL,
	quantity INTEGER NOT NULL CHECK(quantity > 0),
	discount FLOAT NOT NULL CHECK(discount >= 0),
	profit INTEGER NOT NULL,
	shipping_cost INTEGER NOT NULL,

	
   	order_id INTEGER NOT NULL REFERENCES orders(id),
   	product_id INTEGER NOT NULL REFERENCES products(id)
);

INSERT INTO orders("order_date", "ship_date", "city_id", "customer_id", "ship_mode_id") 
VALUES('2022-07-20', '2022-07-25', 1, 1, 1);

INSERT INTO order_products("sales", "quantity", "discount", "profit", "shipping_cost", "order_id", "product_id") 
VALUES(22198, 2, 0.0, 6215, 4077, 1, 1);









