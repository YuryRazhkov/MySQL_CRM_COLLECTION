drop database  IF EXISTS crm_collection2;
create database crm_collection2;

use crm_collection2;

DROP TABLE IF EXISTS debtor_type; 
CREATE TABLE debtor_type ( -- вид должника
	id SERIAL PRIMARY KEY, 
    type VARCHAR(30)
);  
		

DROP TABLE IF EXISTS corporats; -- должники-юридические лица
create table corporats (
id SERIAL PRIMARY KEY,
name VARCHAR(250), -- наименование
form VARCHAR(250), -- организационно правовая форма (ЧП, ОАО итд)
reg_number VARCHAR(250), -- регистрационный номер
reg_date date,
email VARCHAR(120),
phone BIGINT UNSIGNED, 
legal_adress VARCHAR(250),
fact_adress VARCHAR(250),
boss_name VARCHAR(250),
notice TEXT(1000) -- вносится любое примечание
);

DROP TABLE IF EXISTS individuals; -- должники-физические лица
create table individuals (
id SERIAL PRIMARY KEY,
firstname VARCHAR(250), 
surname VARCHAR(250), 
lastname VARCHAR(250), 
unique_number VARCHAR(250), -- регистрационный номер
num_passport VARCHAR(250), -- номер ДУЛ
date_passport DATE, -- дата выдачи выдачи ДУЛ
adm_passport VARCHAR(250), -- орган выдачи ДУЛ
birght_date DATE,
birght_place VARCHAR(250),
email VARCHAR(120) UNIQUE,
phone BIGINT UNSIGNED,
legal_adress VARCHAR(250),
fact_adress VARCHAR(250),
notice TEXT(1000) -- вносится любое примечание

);

DROP TABLE IF EXISTS debtors; 
CREATE TABLE debtors ( -- вид должника
   id SERIAL PRIMARY KEY, 
   debtor_type BIGINT UNSIGNED NOT NULL, 
   id_individuals BIGINT UNSIGNED,
   id_corporats BIGINT UNSIGNED,
   
   FOREIGN KEY (id_individuals) REFERENCES individuals(id),
   FOREIGN KEY (debtor_type) REFERENCES debtor_type(id),
   FOREIGN KEY (id_corporats) REFERENCES corporats(id)
   );


DROP TABLE IF EXISTS currency;
CREATE TABLE currency ( 
id SERIAL PRIMARY KEY,
currency varchar(3))
;

DROP TABLE IF EXISTS users;
CREATE TABLE users ( -- пользовтели базы
	id SERIAL PRIMARY KEY, 
    login VARCHAR(50),
    name VARCHAR(50), -- Фамилия, инициалы
 	password_hash VARCHAR(100), 
	phone BIGINT UNSIGNED,
	email VARCHAR(120),
    INDEX users_name_idx(name)
);
 
DROP TABLE IF EXISTS stage; 
CREATE TABLE stage ( -- этап взыскания. традиционно 3 этапа: soft, hard, legal
	id SERIAL PRIMARY KEY, 
    stage_name VARCHAR(10)
);  
		

DROP TABLE IF EXISTS contracts; 
CREATE TABLE contracts ( 
id SERIAL PRIMARY KEY,
number VARCHAR(250), 
conclusion_date DATE,
debtor BIGINT UNSIGNED NOT NULL,
sum_contract DECIMAL(10, 2),
currency BIGINT UNSIGNED NOT NULL,

FOREIGN KEY (debtor) REFERENCES debtors(id),
FOREIGN KEY (currency) REFERENCES currency(id)
);

DROP TABLE IF EXISTS garant_type;
CREATE TABLE garant_type ( 
id SERIAL PRIMARY KEY,
type VARCHAR(100)
);  


DROP TABLE IF EXISTS guarants_contracts;
CREATE TABLE guarants_contracts ( 
id SERIAL PRIMARY KEY,
number VARCHAR(250), 
conclusion_date DATE,
contract_type BIGINT UNSIGNED NOT NULL,
garant BIGINT UNSIGNED NOT NULL,

FOREIGN KEY (garant) REFERENCES debtors(id),
FOREIGN KEY (contract_type) REFERENCES garant_type(id)
);

DROP TABLE IF EXISTS cases;
CREATE TABLE cases ( 
id SERIAL PRIMARY KEY,
user BIGINT UNSIGNED NOT NULL,
debtor BIGINT UNSIGNED NOT NULL,
sum_debt DECIMAL(10, 2), -- сумма долга
pay_debt DECIMAL(10, 2), -- сумма погашения 
balance_debt DECIMAL(10, 2), -- сумма остатка
currency BIGINT UNSIGNED NOT NULL,
contract BIGINT UNSIGNED NOT NULL,
stage BIGINT UNSIGNED NOT NULL,
notice TEXT(1000), -- вносится любое примечание
force_doc_num VARCHAR(250), -- решение суда, исполнительная надпись иное
force_doc_date date, -- решение суда, исполнительная надпись иное
guarant_case BIGINT UNSIGNED,



FOREIGN KEY (debtor) REFERENCES debtors(id),
FOREIGN KEY (user) REFERENCES users(id),
FOREIGN KEY (currency) REFERENCES currency(id),
FOREIGN KEY (contract) REFERENCES contracts(id),
FOREIGN KEY (stage) REFERENCES stage(id)

);

DROP TABLE IF EXISTS actions_type; 
CREATE TABLE actions_type ( 
id SERIAL PRIMARY KEY,
actions_type varchar(250))
;



DROP TABLE IF EXISTS actions; -- фиксация мероприятий
CREATE TABLE actions ( 
id SERIAL PRIMARY KEY,
user BIGINT UNSIGNED NOT NULL,
actions_type BIGINT UNSIGNED NOT NULL,
date timestamp default now(),
body TEXT(1000), -- пользователь пишет что именно он делал
case_id BIGINT UNSIGNED NOT NULL,


FOREIGN KEY (user) REFERENCES users(id),
FOREIGN KEY (case_id) REFERENCES cases(id),
FOREIGN KEY (actions_type) REFERENCES actions_type(id))
;


DROP TABLE IF EXISTS payment; -- фиксация сумм погашения
CREATE TABLE payment ( 
id SERIAL PRIMARY KEY,
case_id BIGINT UNSIGNED NOT NULL,
amount DECIMAL(10, 2), 
date_payment date,
num_doc_pay varchar(250),

FOREIGN KEY (case_id) REFERENCES cases(id)
);

DROP TABLE IF EXISTS guarant_cases; -- кейсы обеспечения
CREATE TABLE guarant_cases (
id SERIAL PRIMARY KEY,
debtor BIGINT UNSIGNED NOT NULL,
sum_guarant DECIMAL(10, 2),
currency BIGINT UNSIGNED NOT NULL,
garant_type BIGINT UNSIGNED NOT NULL,
guarants_contract BIGINT UNSIGNED NOT NULL,
specificatinon TEXT(1000), -- описывается содержание обеспечения
case_id BIGINT UNSIGNED NOT NULL,


FOREIGN KEY (garant_type) REFERENCES garant_type(id),
FOREIGN KEY (case_id) REFERENCES cases(id),
FOREIGN KEY (debtor) REFERENCES debtors(id),
FOREIGN KEY (currency) REFERENCES currency(id),
FOREIGN KEY (guarants_contract) REFERENCES guarants_contracts(id)
);



DROP TABLE IF EXISTS to_do; -- фиксация запланированных мероприятий
CREATE TABLE to_do ( 
id SERIAL PRIMARY KEY,
date date,
body TEXT(1000), -- пользователь пишет что именно он делал
case_id BIGINT UNSIGNED NOT NULL,
done bool default 0,

FOREIGN KEY (case_id) REFERENCES cases(id));

 ALTER TABLE crm_collection2.cases
 ADD FOREIGN KEY (guarant_case) REFERENCES guarant_cases(id) ;
 
 
 -- ПРЕДСТАВЛЕНИЯ

 -- 1. Представление, содержащее ключевую информацию о кейсах юр.лиц в расшифрованном виде
create or replace view corp_cases as 
select case_id, users.name as user_name, form, corporats.name as deb_name, legal_adress, reg_number, boss_name, 
sum_debt, pay_debt, balance_debt, currency.currency, stage_name
from (select cases.id as case_id, sum_debt, pay_debt, balance_debt, user, currency as val, debtor, 
stage, id_corporats from cases 
join debtors on debtor=debtors.id where debtor_type = 2) as c
join corporats on id_corporats=corporats.id
join users on user=users.id
join stage on stage=stage.id
join currency on val=currency.id;

select * from corp_cases; 

-- 2. Представление для отображения кейсов с переплатой для урегулирования
create or replace view bad_balance as 
select case_id, currency.currency, sum_debt, total_pay, balance_debt   
from (select sum(amount) as total_pay,case_id from payment group by case_id order by  case_id)  as a
join cases on case_id=cases.id
join currency on cases.currency=currency.id
where balance_debt <= 0
order by balance_debt;

-- ТРИГГЕРЫ

-- Триггер для обновления суммы погашенной задолженности и получения остатка задолженности 
-- в таблице 'cases' в случае добавления платежа в таблицу 'payment'
drop trigger if exists case_pay_update;
delimiter //
create trigger case_pay_update after insert on payment
for each row
begin
update cases set cases.pay_debt = cases.pay_debt + (select amount from payment ORDER BY id DESC LIMIT 1) 
where cases.id = (select case_id from payment ORDER BY id DESC LIMIT 1);
update cases set cases.balance_debt = cases.sum_debt - cases.pay_debt
where cases.id = (select case_id from payment ORDER BY id DESC LIMIT 1);
end 
//
delimiter ;

-- ПРОЦЕДУРА
-- Процедура 'belif_inform_to_do' предназначена для автоматического добавления в таблицу 'to_do' 
-- контрольнго мероприятия по направлению сообщения о погашении задолженности по кейсамaм 
--  по которым зпдолженность <= 0 

delimiter //
drop procedure if exists belif_inform_to_do;
create procedure belif_inform_to_do ()
begin
	DECLARE i INT DEFAULT  (select (select count(id) from (select id from cases where stage =3 and balance_debt <= 0) as a) -1);
	while i > 0 DO
		set @i = i;
		select @case_id := (select id from cases where stage =3 and balance_debt <= 0 limit 1 offset i) as case_id;
        
		insert into to_do (date, body, case_id) value 
			(CURDATE() + 3, 'проинформировать органы принудительно исполнения о погашении задолженности', @case_id);
		SET i = i - 1;
      END WHILE;

END//
delimiter ;

