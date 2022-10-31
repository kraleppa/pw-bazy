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

