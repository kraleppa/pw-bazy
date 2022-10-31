/* Funkcje dotyczące kategorii i produktów */


create or replace function create_category(category_name text)
returns int
language plpgsql
as $$
declare 
	category_id int;
begin
	select id into category_id from categories where name like category_name;

	if category_id is null then
		insert into categories (name) values (category_name) returning id into category_id;
	end if;

	return category_id;
end
$$;

create or replace function create_subcategory(category_name text, subcategory_name text)
returns int
language plpgsql
as $$
declare 
	category_id int;
	subcategory_id int;
begin
	select create_category(category_name) into category_id;
	select id into subcategory_id from subcategories where name like subcategory_name;

	if subcategory_id is null then
		insert into subcategories (name, category_id) values (subcategory_name, category_id) returning id into subcategory_id;
	end if;

	return subcategory_id;
end
$$;

create or replace function create_product(category_name text, subcategory_name text, product_name text)
returns int
language plpgsql
as $$
declare 
	subcategory_id int;
	product_id int;
begin
	select create_subcategory(category_name, subcategory_name) into subcategory_id;
	select id into product_id from products where name like product_name;

	if product_id is null then
		insert into products (name, subcategory_id) values (product_name, subcategory_id) returning id into product_id;
	end if;

	return product_id;
end
$$;


/* Funckje związane z adresem */


create or replace function create_market(market_name text)
returns int
language plpgsql
as $$
declare 
	market_id int;
begin
	select id into market_id from markets where name like market_name;

	if market_id is null then
		insert into markets (name) values (market_name) returning id into market_id;
	end if;

	return market_id;
end
$$;

create or replace function create_country(market_name text, country_name text)
returns int
language plpgsql
as $$
declare 
	market_id int;
	country_id int;
begin
	select create_market(market_name) into market_id;
	select id into country_id from countries where name like country_name;

	if country_id is null then
		insert into countries (name, market_id) values (country_name, market_id) returning id into country_id;
	end if;

	return country_id;
end
$$;

create or replace function create_state(market_name text, country_name text, state_name text)
returns int
language plpgsql
as $$
declare 
	country_id int;
	state_id int;
begin
	select create_country(market_name, country_name) into country_id;
	select id into state_id from states where name like state_name;

	if state_id is null then
		insert into states (name, country_id) values (state_name, country_id) returning id into state_id;
	end if;

	return state_id;
end
$$;

create or replace function create_city(market_name text, country_name text, state_name text, city_name text, postal_code text)
returns int
language plpgsql
as $$
declare 
	state_id int;
	city_id int;
begin
	select create_state(market_name, country_name, state_name) into state_id;
	select id into city_id from cities where name like city_name;

	if city_id is null then
		insert into cities (name, postal_code, state_id) values (city_name, postal_code, state_id) returning id into city_id;
	end if;

	return city_id;
end
$$;

/* Funkcje związane z klientami */

create or replace function create_segment(segment_name text)
returns int
language plpgsql
as $$
declare 
	segment_id int;
begin
	select id into segment_id from segments where name like segment_name;

	if segment_id is null then
		insert into segments (name) values (segment_name) returning id into segment_id;
	end if;

	return segment_id;
end
$$;

create or replace function create_customer(segment_name text, customer_name text)
returns int
language plpgsql
as $$
declare 
	segment_id int;
	customer_id int;
begin
	select create_segment(segment_name) into segment_id;
	select id into customer_id from customers where name like customer_name;

	if customer_id is null then
		insert into customers (name, segment_id) values (customer_name, segment_id) returning id into customer_id;
	end if;

	return customer_id;
end
$$;


/* Ship modes */

create or replace function create_ship_mode(ship_mode_name text)
returns int
language plpgsql
as $$
declare 
	ship_mode_id int;
begin
	select id into ship_mode_id from ship_modes where name like ship_mode_name;

	if ship_mode_id is null then
		insert into ship_modes (name) values (ship_mode_name) returning id into ship_mode_id;
	end if;

	return ship_mode_id;
end
$$;

/* Procedury tworzące zamówienie */

create or replace procedure create_order_product(params json, order_id int) 
language plpgsql
as $$
declare
	product_id int;
begin
	
	select create_product(
		params->>'category',
		params->>'subcategory',
		params->>'name'
	) into product_id;

	insert into order_products (
		sales,
		quantity,
		discount,
		profit,
		shipping_cost,
		order_id,
		product_id 
	) values (
		cast (params->>'sales' as integer),
		cast (params->>'quantity' as integer),
		cast (params->>'discount' as float),
		cast (params->>'profit' as integer),
		cast (params->>'shipping_cost' as integer),
		order_id,
		product_id 
	);
end;
$$;


create or replace procedure create_order(params json)
language plpgsql
as $$
declare
	city_id int;
	customer_id int;
	ship_mode_id int;
	order_id int;

	product_element record;
begin
	
	select create_city(
		params->>'market',
		params->>'country',
		params->>'state',
		params->>'city',
		params->>'postal_code'
	) into city_id;
	
	select create_customer(
		params->>'segment',
		params->>'customer'
	) into customer_id;

	
	select create_ship_mode(
		params->>'ship_mode'
	) into ship_mode_id;


	insert into orders (
		order_date, 
		ship_date, 
		city_id, 
		customer_id, 
		ship_mode_id
	) values (
	
		to_date(params->>'order_date', 'YYYY-MM-DD'),
		to_date(params->>'ship_date', 'YYYY-MM-DD'),
		city_id,
		customer_id,
		ship_mode_id
	) returning id into order_id;

	for product_element in select * from json_array_elements(params->'products') 
	loop	
		call create_order_product(row_to_json(product_element)->'value', order_id);
	end loop;
	

	commit;
end;
$$;

/* Przykładowe wywołanie */

call create_order('
	{
		"market": "DACH",
		"country": "Germany",
		"state": "Bayern",
		"city": "Munchien",
		"postal_code": "00-012",

		"order_date": "2022-10-31",

		"segment": "IT",
		"customer": "Google",

		"ship_mode": "DPD",

		"products": [
			{
				"name": "Samsung Convoy 3",
				"category": "Technology",
				"subcategory": "Phones",
				
				"sales": 22198,
				"quantity": 2,
				"discount": 0.0,
				"profit": 6215,
				"shipping_cost": 4077
			},
			{
				"name": "Nokia Smart Phone, with Caller ID",
				"category": "Technology",
				"subcategory": "Phones",
				
				"sales": 517517,
				"quantity": 9,
				"discount": 0.1,
				"profit": 91997,
				"shipping_cost": 91549
			}

		]
	}
');




