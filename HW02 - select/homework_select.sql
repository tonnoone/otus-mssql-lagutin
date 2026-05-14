/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

Select I.StockItemID, I.StockItemName
From Warehouse.StockItems as I
Where I.StockItemName Like '%urgent%' OR I.StockItemName Like 'Animal%';


/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

Select S.SupplierID, S.SupplierName, O.SupplierID
From Purchasing.Suppliers as S
Left Join Purchasing.PurchaseOrders as O
ON S.SupplierID = O.SupplierID
Where O.SupplierID is Null;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

Select O.OrderID, 
	FORMAT(O.OrderDate, 'd', 'ru-RU') as ODate, 
	DateName(MONTH, O.OrderDate) as OrderMonth, 
	DATEPART(QUARTER, O.OrderDate) as OrderQuarter, 
	L.UnitPrice, 
	L.Quantity,
	C.CustomerName,
	CASE 
		When DATEPART(MONTH, O.OrderDate) >= 1 And DATEPART(MONTH, O.OrderDate) <= 4 Then 1
		When DATEPART(MONTH, O.OrderDate) >= 5 And DATEPART(MONTH, O.OrderDate) <= 8 Then 2
		When DATEPART(MONTH, O.OrderDate) >= 9 And DATEPART(MONTH, O.OrderDate) <= 12 Then 3
	End As Third
From Sales.Orders as O
Left Join Sales.Customers as C
	ON O.CustomerID = C.CustomerID
Left Join Sales.OrderLines as L
	ON O.OrderID = L.OrderID
	AND L.PickingCompletedWhen Is Not Null
Where L.UnitPrice > 100 OR L.Quantity > 20;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

Select P.ExpectedDeliveryDate,
	S.SupplierName,
	C.FullName,
	D.DeliveryMethodName
From Purchasing.PurchaseOrders as P
Left Join Purchasing.Suppliers as S
	ON P.SupplierID = S.SupplierID
Left Join Application.People as C
	ON P.ContactPersonID = C.PersonID
Left Join Application.DeliveryMethods as D
	ON P.DeliveryMethodID = D.DeliveryMethodID
Where (P.ExpectedDeliveryDate Between CAST('20130101' as date) And CAST('20130131' as date))
	And D.DeliveryMethodName In ('Air Freight', 'Refrigerated Air Freight')
	And P.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

Select Top(10) C.CustomerName,
	P.FullName
From Sales.Invoices As I
Left Join Sales.Customers As C
	ON I.CustomerID = C.CustomerID
Left Join Application.People As P
	ON I.SalespersonPersonID = P.PersonID
Order by I.InvoiceDate Desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select Distinct C.CustomerID,
	C.CustomerName,
	C.PhoneNumber,
	C.FaxNumber
From Sales.InvoiceLines as L
Inner Join Warehouse.StockItems as S
	ON L.StockItemID = S.StockItemID
	And S.StockItemName = N'Chocolate frogs 250g'
Left Join Sales.Invoices As I
	ON L.InvoiceID = I.InvoiceID
Left Join Sales.Customers As C
	ON I.CustomerID = C.CustomerID

