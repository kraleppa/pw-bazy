/* 1. Utworzenie procedury lub funkcji zwracającej wszystkie zamówienia z bieżącego miesiąca.
 * 
 * (wymagane kolumny wynikowe: order id, order date, product name, sales, quantity)
 */

create or replace function get_orders_from_current_month()
returns table(
	order_id integer,
	order_date date,
	product_name varchar(255),
	sales integer,
	quantity integer
)
language plpgsql
as $$
begin
	return query select o.id, o.order_date, p."name", op.sales, op.quantity from orders o
	inner join order_products op on op.order_id = o.id 
	inner join products p on op.product_id = p.id 
	where to_char(o.order_date, 'mm-yyyy') like to_char(current_date, 'mm-yyyy');
end 
$$;


select get_orders_from_current_month();

/* 2. Utworzenie zmaterializowanego widoku zwracającego wszystkich klientów, którzy złożyli co najmniej jedno zamówienie.
 * 
 * (wymagane kolumny: customer id, customer name, segment)
 */

create materialized view all_clients_with_at_least_one_order as 
	select c.id as customer_id, c."name" as customer_name, s."name" as segment from customers c 
	inner join orders o on o.customer_id = c.id 
	inner join segments s on s.id = c.segment_id;


select * from all_clients_with_at_least_one_order;

/* 3. Włączenie kompresji na dowolnej strukturze bazy 
 * 
 * Postgresql stricte nie posiada takich opcji jak kompresji jak np SQL Server (row-compression, page-compression), 
 * aczkolwiek posiada on własny mechanizm kompresji który jest automatycznie włączny
 * https://www.postgresql.org/docs/current/storage-toast.html
 * 
 * Uruchamia sie on w momemncie w którym krotka ma rozmiar większy niż TOAST_TUPLE_THRESHOLD (domyślnie 2kB)
 * 
 * Będzie on kompresował wartości pól dopóki docelowy poziom kompresji nie zostanie osiągnięty lub nic więcej nie będzie sie dało zrobić
 * 
 * Możemy zmnieszyć TOAST_TUPLE_THRESHOLD dla tabeli order_products - będzie posiadała ona bardzo dużo krotek o wielkości potencjalnie niższej niż 2kB.
 * Wynika to z tego że dla każdego produktu z nowego zamówienia będziemy tworzyć osobną krotkę która nie ma aż tak ciężkich kolumn
 * 
 * Dlatego być może warto wymusić wcześniejszą kompresje
 */

alter table order_products set (toast_tuple_target = 256)

/* 4. Włączenie partycjonowania
 * 
 * Zazwyczaj włącza się je dla dużych tabeli które stanowią potencjalny problem w wydajności, więc możemy je uruchomić dla tabeli orders
 * 
 * Można użyć metody partycjonowania range - z racji tego że użytkownicy najczęściej chcą uzyskiwać dostęp do zamówień najnowszych
 * moglibyśmy pratycjonować zamówienia pod względem order_date
 */

CREATE TABLE orders (
	id SERIAL,
	
	order_date DATE NOT NULL,
	ship_date DATE,
	
   	city_id INTEGER NOT NULL REFERENCES cities(id),
   	customer_id INTEGER NOT NULL REFERENCES customers(id),
   	ship_mode_id INTEGER NOT NULL REFERENCES ship_modes(id),
   	
   	PRIMARY KEY(id, order_date)
) PARTITION BY RANGE(order_date);


create table orders_old partition of orders for values from (minvalue) to ('2021-12-31');
create table orders_new partition of orders for values from ('2022-01-01') to (maxvalue);










