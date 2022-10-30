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

INSERT INTO markets("name") values('test market 1');
INSERT INTO countries("name", "market_id") values('test country 1', 1);
INSERT INTO states("name", "country_id") values('test state 1', 1);
INSERT INTO cities("name", "postal_code", "state_id") values('test city 1', '31-072', 1);


/* Tabele związane z kategoriami */


CREATE TABLE categories (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) UNIQUE NOT NULL
);


CREATE TABLE subcategories (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	
   	category_id INTEGER NOT NULL REFERENCES categories(id)
);


/* Dane testowe */

INSERT INTO categories("name") values('test category 1');
INSERT INTO subcategories("name", "category_id") values('test subcat 1', 1);

