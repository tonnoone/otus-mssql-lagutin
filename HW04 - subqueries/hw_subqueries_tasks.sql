/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

Select P.PersonID,
	P.FullName
From Application.People As P
Where P.IsSalesperson = 1
And P.PersonID Not In (Select I.SalespersonPersonID From Sales.Invoices AS I Where I.InvoiceDate = '20150704') ;

-- другой вариант
Select P.PersonID,
	P.FullName
From Application.People As P
Left Join Sales.Invoices As I
	On I.SalespersonPersonID = P.PersonID
	And I.InvoiceDate = '20150704'
Where P.IsSalesperson = 1
	And I.InvoiceDate Is Null;

-- вариант с CTE
;With InvoiceCTE As (
	Select Distinct I.SalespersonPersonID
	From Sales.Invoices As I
	Where I.InvoiceDate = '20150704'
	)
Select P.PersonID,
	P.FullName
From Application.People As P
Left Join InvoiceCTE As I
	ON P.PersonID = I.SalespersonPersonID
Where P.IsSalesperson = 1 And I.SalespersonPersonID IS Null;


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

Select I.Description,
	I.StockItemID,
	Min(I.UnitPrice)
From Sales.InvoiceLines As I
Where I.StockItemID In (
	Select W.StockItemID 
	From Warehouse.StockItems As W
	)
Group By I.StockItemID, I.Description;

--другой вариант
;With PriceCTE As (
	Select I.StockItemID, Min(I.UnitPrice) As Price 
	From Sales.InvoiceLines I
	Group by I.StockItemID
)
Select W.StockItemID,
	W.StockItemName,
	I.Price
From Warehouse.StockItems As W
Left Join PriceCTE As I
	On W.StockItemID = I.StockItemID
Order by W.StockItemID;

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

Select Top(5) S.CustomerID,
	Max(S.TransactionAmount)
From Sales.CustomerTransactions As S
Group by S.CustomerID
Order by Max(S.TransactionAmount) Desc;

--другой вариант
;With Trans As (
	Select Top(5) T.CustomerID,
		T.TransactionAmount
	From Sales.CustomerTransactions As T
	Order by T.TransactionAmount Desc)
Select S.CustomerName,
	T.CustomerID,
	T.TransactionAmount
From Sales.Customers As S
Join Trans As T
	On S.CustomerID = T.CustomerID


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

select * from sys.all_columns where name = N'PackedByPersonID'
select * from sys.objects where object_id = 2018106230


Select A.CityID,
	A.CityName,
	P.FullName as [Person Who packed Items]
From Sales.InvoiceLines As L
Left Join Sales.Invoices As I
	On L.InvoiceID = I.InvoiceID
Left Join Sales.Customers As C
	On I.CustomerID = C.CustomerID
Left Join Application.Cities As A
	On C.DeliveryCityID = A.CityID
Left Join Application.People As P
	On P.PersonID = I.PackedByPersonID
Where L.StockItemID In (
	Select Top(3) With Ties S.StockItemID
		--S.StockItemName,
		--S.UnitPrice
	From Warehouse.StockItems As S
	Order by S.UnitPrice Desc)


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
