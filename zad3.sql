/* 1. W postgresql dla każdego klucza głównego tworzony jest automatycznie indeks zgrupowany i rzadki */

/* 2. W postgresql dla każdego unikalnego pola tworzony jest automatycznie indeks niezgrupowany i gęsty */

/* 3. Indeks kolumnowy
 * Indeksów kolumnowych używa się zazwyczaj wtedy gdy query wyciąga często jakiś konkretny podzbiór kolumn
 * Wtedy indeksy kolumnowe znacząco przyśpieszają wykonanie zapytanie
 * 
 * W moim schemacie warto go użyć w tabeli Orders ponieważ posiada ona dużo kolumn które będą wyciągane często razem
 * 
 *  */

create index orders_columnstore_idx on "orders" using columnstore (
	"order_date",
	"ship_date",
	"city_id",
	"customer_id",
	"ship_mode_id"
);

/* 4. Utworzenie procedury lub funkcji zwracającej wszystkie zamówienia dla konkretnej podkategorii (subcategory) w konkretnym kraju (country)
 * 
 * wymagane kolumny wynikowe: order id, order date, ship date, product name, sales, quantity, profit
 */

create or replace function orders_for_given_subcategory_and_country(
	country_name varchar(255),
	subcategory_name varchar(255)
)
returns table(
	order_id integer,
	order_date date,
	ship_date date,
	product_name varchar(255),
	sales integer,
	quantity integer,
	profit integer
)
language plpgsql
as $$
begin
	return query select o.id, o.order_date, o.ship_date, p."name", op.sales, op.quantity, op.profit from order_products op 
	inner join products p on op.product_id = p.id 
	inner join subcategories s on p.subcategory_id = s.id 
	inner join orders o on op.order_id = o.id 
	inner join cities c on o.city_id = c.id 
	inner join states s2 on s2.id = c.state_id 
	inner join countries c2 on c2.id = s2.country_id 
	where c2."name" like country_name and s."name" like subcategory_name;
end 
$$;

select orders_for_given_subcategory_and_country('Germany', 'Phones');

/* 5. Utworzenie procedury lub funkcji zwracającej dwa najnowsze zamówienia dla każdego klienta w segmencie Consumer (segment = Consumer)
 * 
 *	wymagane kolumny wynikowe: order id, order date, product name, sales, customer name
 */

create or replace function get_two_latest_orders()
returns table(
	order_id integer,
	order_date date,
	product_name varchar(255),
	sales integer,
	customer_name varchar(255)
)
language plpgsql
as $$
declare
	iterator record;
begin
	for iterator in select c.id from customers c inner join segments s on c.segment_id = s.id where s."name" like 'Consumer'
		loop
			
			return query select o.id, o.order_date, p."name", op.sales, c."name"  from orders o 
			inner join order_products op on op.id = o.id 
			inner join products p on op.product_id = p.id 
			inner join customers c on c.id = o.customer_id 
			where o.customer_id = iterator.id
			order by o.order_date desc 
			limit 2;
			
		end loop;
end 
$$;

select get_two_latest_orders();
