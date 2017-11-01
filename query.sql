CREATE DATABASE CourseWorkDB
GO

USE CourseWorkDB
GO

/* ======== ТАБЛИЦА - Видове потребители ========= */
CREATE TABLE UserType
(UserTypeCode int PRIMARY KEY IDENTITY(1,1) not null,
TypeName varchar(32) not null,
ModifDate datetime null)
GO
/*  Тригери  */
CREATE TRIGGER UserTypeModifDate
ON UserType
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DISABLE TRIGGER UserTypeChange ON UserType;
	UPDATE UserType
	SET ModifDate = convert(varchar(20),GETDATE())
	WHERE UserTypeCode IN (SELECT UserTypeCode FROM inserted);
	ENABLE TRIGGER dbo.UserTypeChange ON UserType;
END
GO


CREATE TRIGGER UserTypeChange
ON UserType
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @operation varchar(6)

	SET @operation = CASE
		WHEN EXISTS (SELECT * FROM inserted) AND
			 EXISTS (SELECT * FROM deleted)
			THEN 'Update'
		WHEN EXISTS (SELECT * FROM inserted)
			THEN 'Insert'
		WHEN EXISTS (SELECT * FROM deleted)
			THEN 'Delete'
		ELSE NULL
	END
	IF @operation = 'Delete'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues)
		SELECT GETDATE(), @operation, 'UserType',
			   convert(varchar(1),UserTypeCode) + ';' + TypeName AS OldValues
		FROM deleted
	IF @operation = 'Insert'
		INSERT INTO ModifyList(DateModify, Operation, TableName, NewValues)
		SELECT GETDATE(), @operation, 'UserType',
			   convert(varchar(1),UserTypeCode) + ';' + TypeName AS NewValues
		FROM inserted
	IF @operation = 'Update'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues, NewValues)
		SELECT GETDATE(), @operation, 'UserType',
			   convert(varchar(1),d.UserTypeCode) + ';' + d.TypeName AS OldValues,
			   convert(varchar(1),i.UserTypeCode + ';' + i.TypeName) AS NewValues
		FROM deleted d, inserted i
		WHERE d.UserTypeCode = i.UserTypeCode
END
GO
/*  Добавяне на данни  */
CREATE PROCEDURE InsertTypeUsers
@TypeName varchar(13)
AS
BEGIN
	DECLARE @message nvarchar(50)
	BEGIN TRY
		INSERT INTO UserType (TypeName)
		VALUES (@TypeName)
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде добавен!';
		THROW 50001, @message, 1
	END CATCH
END
GO

/* ======== ТАБЛИЦА - Потребители ========= */
CREATE TABLE Users
(UserID int PRIMARY KEY IDENTITY(1,1) not null,
UserType int FOREIGN KEY REFERENCES UserType(UserTypeCode) default(1) not null,
UserName varchar(20) not null,
UserPassword varchar(32) not null,
UserEmail varchar(50) not null,
ModifDate datetime null)
GO
/*  Тригери  */
CREATE TRIGGER UserModifDate
ON Users
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DISABLE TRIGGER UserChange ON Users;
	UPDATE Users
	SET ModifDate = convert(varchar(20),GETDATE())
	WHERE UserID IN (SELECT UserID FROM inserted);
	ENABLE TRIGGER dbo.UserChange ON Users;
END
GO

CREATE TRIGGER UserChange
ON Users
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @operation varchar(6)

	SET @operation = CASE
		WHEN EXISTS (SELECT * FROM inserted) AND
			 EXISTS (SELECT * FROM deleted)
			THEN 'Update'
		WHEN EXISTS (SELECT * FROM inserted)
			THEN 'Insert'
		WHEN EXISTS (SELECT * FROM deleted)
			THEN 'Delete'
		ELSE NULL
	END
	IF @operation = 'Delete'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues)
		SELECT GETDATE(), @operation, 'Users',
			   convert(varchar(3),UserID) + ';' + convert(varchar(1),UserType) + ';' + UserName + ';' +
			   UserPassword + ';' + UserEmail AS OldValues
		FROM deleted
	IF @operation = 'Insert'
		INSERT INTO ModifyList(DateModify, Operation, TableName, NewValues)
		SELECT GETDATE(), @operation, 'Users',
			   convert(varchar(3),UserID) + ';' + convert(varchar(1),UserType) + ';' + UserName + ';' +
			   UserPassword + ';' + UserEmail AS NewValues
		FROM inserted
	IF @operation = 'Update'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues, NewValues)
		SELECT GETDATE(), @operation, 'Users',
			   convert(varchar(3),d.UserID) + ';' + convert(varchar(1),d.UserType) + ';' + d.UserName + ';' +
			   d.UserPassword + ';' + d.UserEmail AS OldValues,
			   convert(varchar(3),i.UserID) + ';' + convert(varchar(1),i.UserType) + ';' + i.UserName + ';' +
			   i.UserPassword + ';' + i.UserEmail AS NewValues
		FROM deleted d, inserted i
		WHERE d.UserID = i.UserID
END
GO
/*  Добавяне на данни  */
CREATE PROCEDURE InsertUsers
@UserName varchar(20),
@UserPassword varchar(32) = null,
@UserEmail varchar(50) = null
AS
BEGIN
	DECLARE @message nvarchar(50)
	BEGIN TRY
		INSERT INTO Users(UserName,UserPassword,UserEmail)
		VALUES (@UserName, convert(varchar(32), HASHBYTES('MD5', @UserPassword), 2), @UserEmail)
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде добавен!';
		THROW 50002, @message, 1
	END CATCH
END
GO

ALTER PROCEDURE UpdateUsers
@UserID int = null,
@UserPassword varchar(32) = null,
@UserEmail varchar(50) = null
AS
BEGIN
	DECLARE @message nvarchar(50),
	@SQL varchar(max)
	BEGIN TRY
		UPDATE Users
		SET UserPassword = isnull(convert(varchar(32), @UserPassword),''+UserPassword+''),
		UserEmail = ISNULL(CONVERT(varchar(50), @UserEmail), ''+UserEmail+'')
		WHERE UserID = @UserID
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде добавен!';
		THROW 50002, @message, 1
	END CATCH
END
GO

/*  Изтриване на данни  */
CREATE PROCEDURE DeleteUser
@UserID int
AS
BEGIN
	DECLARE @message nvarchar(50),
	@exists int
	SELECT @exists = COUNT(*) FROM Users
	WHERE UserID = @UserID
		IF @exists = 0
		BEGIN
			SET @message = 'Записът не може да бъде намерен!';
			THROW 50010, @message, 1
			RETURN
		END
	BEGIN TRY
		DELETE FROM Users
		WHERE UserID = @UserID
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде изтрит!';
		THROW 50011, @message, 1
	END CATCH
END
GO

/* ======= ТАБЛИЦА - Клиенти ======== */
CREATE TABLE Customers
(CustomerID int PRIMARY KEY FOREIGN KEY REFERENCES Users(UserID) not null,
CustomerFirstName varchar(20) not null,
CustomerLastName varchar(30) not null,
CustomerAddress varchar(50) null,
CustomerCity varchar(20) not null,
CustomerFrom date not null,
CustomerPhone char(12) not null,
ModifDate datetime null)
GO
/*  Тригери  */
CREATE TRIGGER CustomerModifDate
ON Customers
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DISABLE TRIGGER CustomerChange ON Customers;
	UPDATE Customers
	SET ModifDate = convert(varchar(20),GETDATE())
	WHERE CustomerID IN (SELECT CustomerID FROM inserted);
	ENABLE TRIGGER dbo.CustomerChange ON Customers;
END
GO

CREATE TRIGGER CustomerChange
ON Customers
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @operation varchar(6)
	SET @operation = CASE
		WHEN EXISTS (SELECT * FROM inserted) AND
			 EXISTS (SELECT * FROM deleted)
			THEN 'Update'
		WHEN EXISTS (SELECT * FROM inserted)
			THEN 'Insert'
		WHEN EXISTS (SELECT * FROM deleted)
			THEN 'Delete'
		ELSE NULL
	END
	IF @operation = 'Delete'
		INSERT INTO ModifyList (DateModify, Operation, TableName, OldValues)
		SELECT GETDATE(), @operation, 'Customers',
			   convert(varchar(3),CustomerID) + ';' + CustomerFirstName + ';' + CustomerLastName + ';' +
			   isnull(CustomerAddress, '') + ';' + CustomerCity + ';' + convert(varchar(8), CustomerFrom) + ';' +
			   CustomerPhone AS OldValues
		FROM deleted
	IF @operation = 'Insert'
		INSERT INTO ModifyList (DateModify, Operation, TableName, NewValues)
		SELECT GETDATE(), @operation, 'Customers',
			   convert(varchar(3),CustomerID) + ';' + CustomerFirstName + ';' + CustomerLastName + ';' +
			   isnull(CustomerAddress, '') + ';' + CustomerCity + ';' + convert(varchar(8), CustomerFrom) + ';' +
			   CustomerPhone AS NewValues
		FROM inserted
	IF @operation = 'Update'
		INSERT INTO ModifyList (DateModify, Operation, TableName, OldValues, NewValues)
		SELECT GETDATE(), @operation, 'Customers',
			   convert(varchar(3),d.CustomerID) + ';' + d.CustomerFirstName + ';' + d.CustomerLastName + ';' +
			   isnull(d.CustomerAddress, '') + ';' + d.CustomerCity + ';' + convert(varchar(8), d.CustomerFrom) + ';' +
			   d.CustomerPhone AS OldValues,
			   convert(varchar(3),i.CustomerID) + '; ' + i.CustomerFirstName + '; ' + i.CustomerLastName + '; ' +
			   isnull(i.CustomerAddress, '') + ';' + i.CustomerCity + ';' + convert(varchar(8), i.CustomerFrom) + ';' +
			   i.CustomerPhone AS NewValues
		FROM deleted d, inserted i
		WHERE d.CustomerID = i.CustomerID
END
GO
/*  Добавяне на данни  */
CREATE PROCEDURE InsertCustomers
@UserID int = null,
@CustomerFirstName varchar(20) = null,
@CustomerLastName varchar(30) = null,
@CustomerAddress varchar(50) = null,
@CustomerCity varchar(20) = null,
@CustomerPhone char(12) = null
AS
BEGIN
	DECLARE @message2 nvarchar(50)
	BEGIN TRY
		INSERT INTO Customers (CustomerID, CustomerFirstName, CustomerLastName, CustomerAddress, CustomerCity,
		CustomerFrom, CustomerPhone)
		VALUES (@UserID,@CustomerFirstName,@CustomerLastName,@CustomerAddress,@CustomerCity,GETDATE(),@CustomerPhone)
	END TRY
	BEGIN CATCH
		SET @message2 = 'Записът не може да бъде добавен!';
		THROW 50003, @message2, 1
	END CATCH
END
GO

ALTER PROCEDURE UpdateCustomers
@UserID int = null,
@CustomerFirstName varchar(20) = null,
@CustomerLastName varchar(30) = null,
@CustomerAddress varchar(50) = null,
@CustomerCity varchar(20) = null,
@CustomerPhone char(12) = null
AS
BEGIN
	DECLARE @message2 nvarchar(50)
	DECLARE @SQL varchar(max)
	BEGIN TRY
		UPDATE Customers
		SET CustomerFirstName = isnull(convert(varchar(20),@CustomerFirstName),''),
		CustomerLastName = isnull(convert(varchar(20),@CustomerLastName),''),
		CustomerAddress = isnull(convert(varchar(50),@CustomerAddress),''),
		CustomerCity = isnull(convert(varchar(20),@CustomerCity),''),
		CustomerPhone = isnull(convert(varchar(12),@CustomerPhone),'')
		WHERE CustomerID = (convert(int,@UserID))
	END TRY
	BEGIN CATCH
		SET @message2 = 'Записът не може да бъде редактиран!';
		THROW 50003, @message2, 1
	END CATCH
END
GO

EXEC UpdateCustomers 11,'Горанис','Кръстев','България','Пловдив',''

/*  Изтриване на данни  */
CREATE PROCEDURE DeleteCustomer
@CustomerID int
AS
BEGIN
	DECLARE @message nvarchar(50),
	@exists int
	SELECT @exists = COUNT(*) FROM Customers
	WHERE CustomerID = @CustomerID
		IF @exists = 0
		BEGIN
			SET @message = 'Записът не може да бъде намерен!';
			THROW 50012, @message, 1
			RETURN
		END
	BEGIN TRY
		DELETE FROM Customers
		WHERE CustomerID = @CustomerID

		DELETE FROM Users
		WHERE UserID = @CustomerID
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде изтрит!';
		THROW 50013, @message, 1
	END CATCH
END
GO

/* ====== ТАБЛИЦА - Служители ======== */
CREATE TABLE Employees
(EmployeeID int PRIMARY KEY FOREIGN KEY REFERENCES Users(UserID) not null,
EmployeeFirstName varchar(20) not null,
EmployeeLastName varchar(30) not null,
HireDate date null,
Salary money null,
ModifDate datetime null)
GO
/*  Тригери  */
CREATE TRIGGER EmployeeModifDate
ON Employees
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DISABLE TRIGGER EmployeeChange ON Employees;
	UPDATE Employees
	SET ModifDate = convert(varchar(20),GETDATE())
	WHERE EmployeeID IN (SELECT EmployeeID FROM inserted);
	ENABLE TRIGGER dbo.EmployeeChange ON Employees;
END
GO

ALTER TRIGGER EmployeeChange
ON Employees
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @operation varchar(6)

	SET @operation = CASE
		WHEN EXISTS (SELECT * FROM inserted) AND
			 EXISTS (SELECT * FROM deleted)
			THEN 'Update'
		WHEN EXISTS (SELECT * FROM inserted)
			THEN 'Insert'
		WHEN EXISTS (SELECT * FROM deleted)
			THEN 'Delete'
		ELSE NULL
	END
	IF @operation = 'Delete'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues)
		SELECT GETDATE(), @operation, 'Employees',
			   convert(varchar(3),EmployeeID) + ';' + EmployeeFirstName + ';' + EmployeeLastName + ';' +
			   isnull(convert(varchar(8), HireDate), '') + ';' + isnull(convert(nvarchar(8),Salary), '') AS OldValues
		FROM deleted
	IF @operation = 'Insert'
		INSERT INTO ModifyList(DateModify, Operation, TableName, NewValues)
		SELECT GETDATE(), @operation, 'Employees',
			   convert(varchar(3),EmployeeID) + ';' + EmployeeFirstName + ';' + EmployeeLastName + ';' +
			   isnull(convert(varchar(8), HireDate), '') + ';' + isnull(convert(nvarchar(8),Salary), '') AS NewValues
		FROM inserted
	IF @operation = 'Update'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues, NewValues)
		SELECT GETDATE(), @operation, 'Employees',
			   convert(varchar(3),d.EmployeeID) + ';' + d.EmployeeFirstName + ';' + d.EmployeeLastName + ';' +
			   isnull(convert(varchar(8), d.HireDate), '') + ';' + isnull(convert(nvarchar(8),d.Salary), '') AS OldValues,
			   convert(varchar(3),i.EmployeeID) + ';' + i.EmployeeFirstName + ';' + i.EmployeeLastName + ';' +
			   isnull(convert(varchar(8), i.HireDate), '') + ';' + isnull(convert(nvarchar(8),i.Salary), '') AS NewValues
		FROM deleted d, inserted i
		WHERE d.EmployeeID = i.EmployeeID
END
GO
/*  Добавяне на данни  */
ALTER PROCEDURE InsertEmployees
@UserID int = null,
@EmployeeFirstName varchar(20) = null,
@EmployeeLastName varchar(30) = null,
@Salary money = null
AS
BEGIN
	DECLARE @message nvarchar(50)
	BEGIN TRY
		INSERT INTO Employees (EmployeeID, EmployeeFirstName, EmployeeLastName, HireDate, Salary)
		VALUES (@UserID, @EmployeeFirstName, @EmployeeLastName, GETDATE(), @Salary)
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде добавен!';
		THROW 50004, @message, 1
	END CATCH
END
GO

CREATE PROCEDURE UpdateEmployee
@EmployeeID int = null,
@EmployeeFirstName varchar(20) = null,
@EmployeeLastName varchar(30) = null,
@Salary money = null
AS
BEGIN
	DECLARE @message nvarchar(50)
	BEGIN TRY
		UPDATE Employees
		SET EmployeeFirstName = ISNULL(CONVERT(varchar(20), @EmployeeFirstName),''),
		EmployeeLastName = ISNULL(CONVERT(varchar(30), @EmployeeLastName),''),
		Salary = ISNULL(convert(money, @Salary),'')
		WHERE EmployeeID = convert(int,@EmployeeID)
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде редактиран!';
		THROW 50005, @message, 1
	END CATCH
END

/*  Изтриване на данни  */
CREATE PROCEDURE DeleteEmployee
@EmployeeID int
AS
BEGIN
	DECLARE @message nvarchar(50),
	@exists int
	SELECT @exists = COUNT(*) FROM Employees
	WHERE EmployeeID = @EmployeeID
		IF @exists = 0
		BEGIN
			SET @message = 'Записът не може да бъде намерен!';
			THROW 50014, @message, 1
			RETURN
		END
	BEGIN TRY
		DELETE FROM Employees
		WHERE EmployeeID = @EmployeeID

		DELETE FROM Users
		WHERE UserID = @EmployeeID
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде изтрит!';
		THROW 50015, @message, 1
	END CATCH
END
GO

/* ======= ТАБЛИЦА - Продукти ======== */
CREATE TABLE Products
(ProductID int PRIMARY KEY IDENTITY(1,1) not null,
ProductName varchar(50) not null,
Price money not null,
ModifDate datetime null)
GO
/*  Тригери  */
CREATE TRIGGER ProductModifDate
ON Products
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DISABLE TRIGGER ProductChange ON Products;
	UPDATE Products
	SET ModifDate = convert(varchar(20),GETDATE())
	WHERE ProductID IN (SELECT ProductID FROM inserted);
	ENABLE TRIGGER dbo.ProductChange ON Products;
END
GO

CREATE TRIGGER ProductChange
ON Products
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @operation varchar(6)

	SET @operation = CASE
		WHEN EXISTS (SELECT * FROM inserted) AND
			 EXISTS (SELECT * FROM deleted)
			THEN 'Update'
		WHEN EXISTS (SELECT * FROM inserted)
			THEN 'Insert'
		WHEN EXISTS (SELECT * FROM deleted)
			THEN 'Delete'
		ELSE NULL
	END
	IF @operation = 'Delete'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues)
		SELECT GETDATE(), @operation, 'Products',
			   convert(varchar(3),ProductID) + ';' + ProductName + ';' + convert(varchar(10),Price) AS OldValues
		FROM deleted
	IF @operation = 'Insert'
		INSERT INTO ModifyList(DateModify, Operation, TableName, NewValues)
		SELECT GETDATE(), @operation, 'Products',
			   convert(varchar(3),ProductID) + ';' + ProductName + ';' + convert(varchar(10),Price) AS NewValues
		FROM inserted
	IF @operation = 'Update'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues, NewValues)
		SELECT GETDATE(), @operation, 'Products',
			   convert(varchar(3),d.ProductID) + ';' + d.ProductName + ';' + convert(varchar(10),d.Price) AS OldValues,
			   convert(varchar(3),i.ProductID) + ';' + i.ProductName + ';' + convert(varchar(10),i.Price) AS NewValues
		FROM deleted d, inserted i
		WHERE d.ProductID = i.ProductID
END
GO
/*  Добавяне на данни  */
CREATE PROCEDURE InsertProducts
@ProductName varchar(50) null,
@Price money null
AS
BEGIN
	DECLARE @message nvarchar(50)
	BEGIN TRY
		INSERT INTO Products (ProductName, Price)
		VALUES (@ProductName, @Price)
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде добавен!';
		THROW 50006, @message, 1
	END CATCH
END
GO
InsertProducts 'aaa',2
/*  Изтриване на данни  */
CREATE PROCEDURE DeleteProduct
@ProductID int
AS
BEGIN
	DECLARE @message nvarchar(50),
	@exists int
	SELECT @exists = COUNT(*) FROM Products
	WHERE ProductID = @ProductID
		IF @exists = 0
		BEGIN
			SET @message = 'Записът не може да бъде намерен!';
			THROW 50018, @message, 1
			RETURN
		END
	BEGIN TRY
		DELETE FROM Products
		WHERE ProductID = @ProductID
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде изтрит!';
		THROW 50019, @message, 1
	END CATCH
END
GO

/* ======= ТАБЛИЦА - Складове ======= */
CREATE TABLE Warehouses
(WarehouseID int PRIMARY KEY IDENTITY(1,1) not null,
WarehouseCode char(2) not null,
WarehouseAddress varchar(50) not null,
ModifDate datetime null)
GO
/*  Тригери  */
CREATE TRIGGER WarehouseModifDate
ON Warehouses
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DISABLE TRIGGER WarehouseChange ON Warehouses;
	UPDATE Warehouses
	SET ModifDate = convert(varchar(20),GETDATE())
	WHERE WarehouseID IN (SELECT WarehouseID FROM inserted);
	ENABLE TRIGGER dbo.WarehouseChange ON Warehouses;
END
GO

CREATE TRIGGER WarehouseChange
ON Warehouses
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @operation varchar(6)

	SET @operation = CASE
		WHEN EXISTS (SELECT * FROM inserted) AND
			 EXISTS (SELECT * FROM deleted)
			THEN 'Update'
		WHEN EXISTS (SELECT * FROM inserted)
			THEN 'Insert'
		WHEN EXISTS (SELECT * FROM deleted)
			THEN 'Delete'
		ELSE NULL
	END
	IF @operation = 'Delete'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues)
		SELECT GETDATE(), @operation, 'Warehouses',
			   convert(varchar(3),WarehouseID) + ';' + convert(varchar(2),WarehouseCode) + ';' + WarehouseAddress AS OldValues
		FROM deleted
	IF @operation = 'Insert'
		INSERT INTO ModifyList(DateModify, Operation, TableName, NewValues)
		SELECT GETDATE(), @operation, 'Warehouses',
			   convert(varchar(3),WarehouseID) + ';' + convert(varchar(2),WarehouseCode) + ';' + WarehouseAddress AS NewValues
		FROM inserted
	IF @operation = 'Update'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues, NewValues)
		SELECT GETDATE(), @operation, 'Warehouses',
			   convert(varchar(3),d.WarehouseID) + ';' + convert(varchar(2),d.WarehouseCode) + ';' + d.WarehouseAddress AS OldValues,
			   convert(varchar(3),i.WarehouseID) + ';' + convert(varchar(2),i.WarehouseCode) + ';' + i.WarehouseAddress AS NewValues
		FROM deleted d, inserted i
		WHERE d.WarehouseID = i.WarehouseID
END
GO
/*  Добавяне на данни  */
CREATE PROCEDURE InsertWarehouse
@WarehouseCode char(2) = null,
@WarehouseAddress varchar(50) = null
AS
BEGIN
	DECLARE @message nvarchar(50)
	BEGIN TRY
		INSERT INTO Warehouses(WarehouseCode, WarehouseAddress)
		VALUES (@WarehouseCode, @WarehouseAddress)
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде добавен!';
		THROW 50005, @message, 1
	END CATCH
END
GO

/*  Изтриване на данни  */
CREATE PROCEDURE DeleteWarehouse
@WarehouseCode char(2)
AS
BEGIN
	DECLARE @message nvarchar(50),
	@exists int
	SELECT @exists = COUNT(*) FROM Warehouses
	WHERE WarehouseCode = @WarehouseCode
		IF @exists = 0
		BEGIN
			SET @message = 'Записът не може да бъде намерен!';
			THROW 50016, @message, 1
			RETURN
		END
	BEGIN TRY
		DELETE FROM Warehouses
		WHERE WarehouseCode = @WarehouseCode
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде изтрит!';
		THROW 50017, @message, 1
	END CATCH
END
GO

/* ======= ТАБЛИЦА - Наличности ===========*/
CREATE TABLE Stocks
(Warehouse int FOREIGN KEY REFERENCES Warehouses(WarehouseID) not null,
ProductID int FOREIGN KEY REFERENCES Products(ProductID) not null,
Quantity smallint null,
ModifDate datetime null,
PRIMARY KEY(Warehouse, ProductID))
GO
/*  Тригери  */
CREATE TRIGGER StockModifDate
ON Stocks
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DISABLE TRIGGER StocksChange ON Stocks;
	UPDATE Stocks
	SET ModifDate = convert(varchar(20),GETDATE())
	WHERE Warehouse IN (SELECT Warehouse FROM inserted) AND
	ProductID IN (SELECT ProductID FROM inserted);
	ENABLE TRIGGER dbo.StocksChange ON Stocks;
END
GO

CREATE TRIGGER StocksChange
ON Stocks
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @operation varchar(6)

	SET @operation = CASE
		WHEN EXISTS (SELECT * FROM inserted) AND
			 EXISTS (SELECT * FROM deleted)
			THEN 'Update'
		WHEN EXISTS (SELECT * FROM inserted)
			THEN 'Insert'
		WHEN EXISTS (SELECT * FROM deleted)
			THEN 'Delete'
		ELSE NULL
	END
	IF @operation = 'Delete'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues)
		SELECT GETDATE(), @operation, 'Stocks',
			   convert(varchar(3),Warehouse) + ';' + convert(varchar(3),ProductID) + ';' + convert(varchar(6),Quantity) AS OldValues
		FROM deleted
	IF @operation = 'Insert'
		INSERT INTO ModifyList(DateModify, Operation, TableName, NewValues)
		SELECT GETDATE(), @operation, 'Stocks',
			   convert(varchar(3),Warehouse) + ';' + convert(varchar(3),ProductID) + ';' + convert(varchar(6),Quantity) AS NewValues
		FROM inserted
	IF @operation = 'Update'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues, NewValues)
		SELECT GETDATE(), @operation, 'Stocks',
			   convert(varchar(3),d.Warehouse) + ';' + convert(varchar(3),d.ProductID) + ';' + convert(varchar(6),d.Quantity) AS OldValues,
			   convert(varchar(3),i.Warehouse) + ';' + convert(varchar(3),i.ProductID) + ';' + convert(varchar(6),i.Quantity) AS NewValues
		FROM deleted d, inserted i
		WHERE d.Warehouse = i.Warehouse AND d.ProductID = i. ProductID
END
GO
/*  Добавяне на данни  */
CREATE PROCEDURE InsertStocks
@Warehouse int = null,
@ProductID int = null,
@Quantity smallint = null
AS
BEGIN
	DECLARE @message nvarchar(50)
	BEGIN TRY
		INSERT INTO Stocks (Warehouse,ProductID,Quantity)
		VALUES (@Warehouse, @ProductID, @Quantity)
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде добавен!';
		THROW 50007, @message, 1
	END CATCH
END
GO

/* ======= ТАБЛИЦА - Статус ======== */
CREATE TABLE [Status]
(StatusCode smallint PRIMARY KEY IDENTITY(1,1) not null,
StatusName varchar(12) not null,
ModifDate datetime null)
GO
/*  Тригери  */
CREATE TRIGGER StatusModifDate
ON [Status]
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DISABLE TRIGGER StatusChange ON [Status];
	UPDATE [Status]
	SET ModifDate = convert(varchar(20),GETDATE())
	WHERE StatusCode IN (SELECT StatusCode FROM inserted);
	ENABLE TRIGGER dbo.StatusChange ON [Status];
END
GO

CREATE TRIGGER StatusChange
ON [Status]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @operation varchar(6)

	SET @operation = CASE
		WHEN EXISTS (SELECT * FROM inserted) AND
			 EXISTS (SELECT * FROM deleted)
			THEN 'Update'
		WHEN EXISTS (SELECT * FROM inserted)
			THEN 'Insert'
		WHEN EXISTS (SELECT * FROM deleted)
			THEN 'Delete'
		ELSE NULL
	END
	IF @operation = 'Delete'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues)
		SELECT GETDATE(), @operation, 'Status',
			   convert(varchar(1),StatusCode) + ';' + StatusName AS OldValues
		FROM deleted
	IF @operation = 'Insert'
		INSERT INTO ModifyList(DateModify, Operation, TableName, NewValues)
		SELECT GETDATE(), @operation, 'Status',
			   convert(varchar(1),StatusCode) + ';' + StatusName AS NewValues
		FROM inserted
	IF @operation = 'Update'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues, NewValues)
		SELECT GETDATE(), @operation, 'Products',
			   convert(varchar(1),d.StatusCode) + ';' + d.StatusName AS OldValues,
			   convert(varchar(1),i.StatusCode) + ';' + i.StatusName AS NewValues
		FROM deleted d, inserted i
		WHERE d.StatusCode = i.StatusCode
END
GO
/*  Добавяне на данни  */
CREATE PROCEDURE InsertStatus
@StatusName varchar(12)
AS
BEGIN
	DECLARE @message nvarchar(50)
	BEGIN TRY
		INSERT INTO Status (StatusName)
		VALUES (@StatusName)
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде добавен!';
		THROW 50008, @message, 1
	END CATCH
END
GO

/* ======== ТАБЛИЦА - Поръчки ======== */
CREATE TABLE Orders
(OrderID int PRIMARY KEY IDENTITY(1,1) not null,
CustomerID int FOREIGN KEY REFERENCES Customers(CustomerID) not null,
EmployeeID int FOREIGN KEY REFERENCES Employees(EmployeeID) null,
WarehouseID int FOREIGN KEY REFERENCES Warehouses(WarehouseID) not null,
ProductID int FOREIGN KEY REFERENCES Products(ProductID) not null,
Quantity smallint not null,
TotalPrice money not null,
[Status] smallint FOREIGN KEY REFERENCES Status(StatusCode) default(1) not null,
ModifDate datetime null)
GO
/*  Тригери  */
ALTER TRIGGER OrderModifDate
ON Orders
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	DISABLE TRIGGER OrderChange ON Orders;
	UPDATE Orders
	SET ModifDate = convert(varchar(20),GETDATE())
	WHERE OrderID IN (SELECT OrderID FROM inserted i);

END
GO


ALTER TRIGGER OrderChange
ON Orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @operation varchar(6)

	SET @operation = CASE
		WHEN EXISTS (SELECT * FROM inserted) AND
			 EXISTS (SELECT * FROM deleted)
			THEN 'Update'
		WHEN EXISTS (SELECT * FROM inserted)
			THEN 'Insert'
		WHEN EXISTS (SELECT * FROM deleted)
			THEN 'Delete'
		ELSE NULL
	END
	IF @operation = 'Delete'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues)
		SELECT GETDATE(), @operation, 'Orders',
			   convert(varchar(3),OrderID) + ';' + convert(varchar(3),CustomerID) + ';' + isnull(convert(varchar(3),EmployeeID), '') + ';' +
			   convert(varchar(3),WarehouseID) + ';' + convert(varchar(3),ProductID) + ';' + convert(varchar(6),Quantity) + ';'
			   + convert(nvarchar(10),TotalPrice) + ';' + convert(varchar(1),[Status]) AS OldValues
		FROM deleted
	IF @operation = 'Insert'
		INSERT INTO ModifyList(DateModify, Operation, TableName, NewValues)
		SELECT GETDATE(), @operation, 'Orders',
		convert(varchar(3),OrderID) + ';' + convert(varchar(3),CustomerID) + ';' + isnull(convert(varchar(3),EmployeeID), '') + ';' +
			   convert(varchar(3),WarehouseID) + ';' + convert(varchar(3),ProductID) + ';' + convert(varchar(6),Quantity) + ';' +
				convert(nvarchar(10),TotalPrice) + ';' + convert(varchar(1),[Status]) AS NewValues
		FROM inserted
	IF @operation = 'Update'
		INSERT INTO ModifyList(DateModify, Operation, TableName, OldValues, NewValues)
		SELECT GETDATE(), @operation, 'Orders',
			   convert(varchar(3),d.OrderID) + ';' + convert(varchar(3),d.CustomerID) + ';' + isnull(convert(varchar(3),d.EmployeeID), '') + ';' +
			   convert(varchar(3),d.WarehouseID) + ';' + convert(varchar(3),d.ProductID) + ';' + convert(varchar(6),d.Quantity) + ';'
			   + convert(nvarchar(10),d.TotalPrice) + ';' + convert(varchar(1),d.[Status]) AS OldValues,
			   convert(varchar(3),i.OrderID) + ';' + convert(varchar(3),i.CustomerID) + ';' + isnull(convert(varchar(3),i.EmployeeID), '') + ';' +
			   convert(varchar(3),i.WarehouseID) + ';' + convert(varchar(3),i.ProductID) + ';' + convert(varchar(6),i.Quantity) + ';'
			   + convert(nvarchar(10),i.TotalPrice) + ';' + convert(varchar(1),i.[Status]) AS NewValues
		FROM deleted d, inserted i
		WHERE d.OrderID = i.OrderID

		
END
GO
/*  Добавяне на данни  */
CREATE PROCEDURE InsertOrder
@CustomerID int = null,
@WarehouseID int = null,
@ProductID int = null,
@Quantity smallint = null
AS
BEGIN
	DECLARE @message nvarchar(50)
	BEGIN TRY
		INSERT INTO Orders (CustomerID, WarehouseID, ProductID, Quantity, TotalPrice)
		SELECT @CustomerID, @WarehouseID, @ProductID, @Quantity, (@Quantity*Price) FROM Products
		WHERE ProductID = @ProductID
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде добавен!';
		THROW 50009, @message, 1
	END CATCH
END
GO

/*  Изтриване на данни  */
CREATE PROCEDURE DeleteOrder
@OrderID int
AS
BEGIN
	DECLARE @message nvarchar(50),
	@exists bit
	SELECT @exists = COUNT(*) FROM Orders
	WHERE OrderID = @OrderID
		IF @exists = 0
		BEGIN
			SET @message = 'Записът не може да бъде намерен!';
			THROW 50019, @message, 1
			RETURN
		END
	BEGIN TRY
		DELETE FROM Orders
		WHERE OrderID = @OrderID
	END TRY
	BEGIN CATCH
		SET @message = 'Записът не може да бъде изтрит!';
		THROW 50020, @message, 1
	END CATCH
END
GO

/* ====== ТАБЛИЦА - Журнал ======== */
CREATE TABLE ModifyList
(DateModify datetime2 PRIMARY KEY,
Operation varchar(6) not null,
[TableName] varchar(30) not null,
OldValues varchar(max) null,
NewValues varchar(max) null)
GO

/* ======= ФУНКЦИЯ - ПОТРЕБИТЕЛ И ПАРОЛА ========= */

CREATE FUNCTION CheckUser (@UserName varchar(20), @UserPassword varchar(15))
RETURNS nvarchar(50)
AS
BEGIN
	DECLARE @result nvarchar(50)
	IF EXISTS (SELECT UserName, UserPassword
			   FROM Users
			   WHERE UserName = @UserName COLLATE SQL_Latin1_General_CP1_CS_AS 
			   AND UserPassword = CONVERT(varchar(32), HASHBYTES('MD5',@UserPassword), 2))
	   SET @result = 'Потребителското име и парола съвпадат!';
	ELSE
	   SET @result = 'Потребителското име и парола не съвпадат!';
	RETURN @result
END
GO

/* =========== СПРАВКИ ========= */
/* 1. */
CREATE VIEW StocksDataView
AS
SELECT w.WarehouseCode, w.WarehouseAddress, s.Quantity, p.ProductID, p.ProductName, p.Price
FROM Warehouses w INNER JOIN Stocks s ON w.WarehouseID = s.Warehouse
				  INNER JOIN Products p ON s.ProductID = p.ProductID
GO

CREATE PROCEDURE StocksList
@WarehouseCode varchar(2) = null,
@ProductName varchar(50) = null,
@FromPrice varchar(2) = null,
@ToPrice varchar(2) = null
AS
BEGIN
	DECLARE @SQLstring varchar(max)
	SET @SQLstring = 
	'SELECT * FROM StocksDataView
	WHERE 1=1'
	IF @WarehouseCode IS NOT NULL 
		SET @SQLstring = @SQLstring + ' AND WarehouseCode = '''+ @WarehouseCode +''''
	IF @ProductName IS NOT NULL
		SET @SQLstring = @SQLstring + ' AND ProductName LIKE ''%'+ @ProductName +'%'''
	IF (@FromPrice IS NOT NULL) AND (@ToPrice IS NOT NULL)
		SET @SQLstring = @SQLstring + ' AND Price BETWEEN 
		'''+ @FromPrice + ''' AND '''+ @ToPrice +''';'
	EXEC(@SQLstring)
END
GO

EXEC StocksList @ProductName = 'дом', @FromPrice=1, @toPrice=12

/* 2. */
CREATE VIEW CustomerOrdersDataView
AS
SELECT c.CustomerFirstName + ' ' + c.CustomerLastName as CustomerNames, c.CustomerCity, c.CustomerPhone,
o.OrderID, o.Quantity, o.TotalPrice, s.StatusCode, s.StatusName, p.ProductName, p.Price, o.ModifDate
FROM Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID
				 INNER JOIN [Status] s ON o.[Status] = s.StatusCode
				 INNER JOIN Products p ON o.ProductID = p.ProductID
GO

CREATE PROCEDURE CustomerOrdersList
@StatusCode varchar(1) = null,
@ProductName varchar(50) = null,
@FromTotalPrice varchar(3) = null,
@ToTotalPrice varchar(3) = null
AS
BEGIN
	DECLARE @SQLquery varchar(max)
	SET @SQLquery = 'SELECT * FROM CustomerOrdersDataView
	WHERE 1=1'
	IF @StatusCode IS NOT NULL
		SET @SQLquery = @SQLquery + ' AND StatusCode = '+ @StatusCode +''
	IF @ProductName IS NOT NULL
		SET @SQLquery = @SQLquery + ' AND ProductName LIKE ''%'+ @ProductName +'%'''
	IF (@FromTotalPrice IS NOT NULL) AND (@ToTotalPrice IS NOT NULL)
		SET @SQLquery = @SQLquery + ' AND TotalPrice BETWEEN '''+ @FromTotalPrice +'''
		AND '''+ @ToTotalPrice +''';'
	EXEC (@SQLquery)
END
GO


EXEC CustomerOrdersList @Productname = 'дом', @FromTotalPrice = 300, @ToTotalPrice = 600

EXEC CustomerOrdersList @StatusCode = 1, @FromTotalPrice = 0, @ToTotalPrice = 250

EXEC CustomerOrdersList @StatusCode = 1, @FromTotalPrice = 250, @ToTotalPrice = 500

/* 3. */
CREATE VIEW EmployeeOrderDataView
AS
SELECT e.EmployeeID, e.EmployeeFirstName + ' ' + e.EmployeeLastName as EmployeeNames, e.HireDate, e.Salary,
p.ProductName, o.Quantity, o.TotalPrice, o.[Status], o.ModifDate
FROM Employees e INNER JOIN Orders o ON e.EmployeeID = o.EmployeeID
				 INNER JOIN Products p ON o.ProductID = p.ProductID
WHERE o.[Status] = 2
GO

CREATE PROCEDURE EmployeeOrderList
@EmployeeName varchar(50) = null,
@FromYear smallint = null,
@ToYear smallint = null,
@FromMonth smallint = null,
@ToMonth smallint = null
AS
BEGIN
	DECLARE @SQLquery varchar(max)
	SET @SQLquery = 'SELECT * FROM EmployeeOrderDataView
	WHERE 1=1'
	IF @EmployeeName IS NOT NULL
		SET @SQLquery = @SQLquery + ' AND EmployeeNames LIKE ''%'+ @EmployeeName +'%''' 
	IF (@FromYear IS NOT NULL) AND (@ToYear IS NOT NULL)
		SET @SQLquery = @SQLquery + ' AND year(ModifDate) BETWEEN '''+ CAST(@FromYear as varchar)  +'''
		AND '''+ CAST(@ToYear as varchar) +''''
	IF (@FromMonth IS NOT NULL) AND (@ToMonth IS NOT NULL)
		SET @SQLquery = @SQLquery + ' AND month(ModifDate) BETWEEN '''+ CAST(@FromMonth as varchar) + '''
		AND '''+ CAST(@ToMonth as varchar) + ''';'
	EXEC (@SQLquery)
END
GO

UPDATE Orders
SET Status = 2,
EmployeeID = 7
WHERE OrderID = 2

EXEC EmployeeOrderList @FromYear = 2015, @ToYear = 2016, @FromMonth = 6, @ToMonth = 11

EXEC EmployeeOrderList @FromYear=2014, @toyear=2016

EXEC EmployeeOrderList @FromMonth=3, @ToMonth = 12

EXEC EmployeeOrderList 'георги'





EXEC InsertUsers 'genco','qweasd','gen@abv.bg'
EXEC InsertCustomers 11,'Горан','Кръстев','България','Пловдив','359878564832'
EXEC InsertWarehouse 60, 'Варна'
EXEC InsertStocks 6, 2, 500
EXEC InsertStocks 6, 1, 550
EXEC InsertOrder 11, 6, 2, 40

EXEC CustomerOrdersList 2, 'ман', 230, 240

PRINT dbo.CheckUser('genco','qweasd')


UPDATE Orders
SET [Status]=2,
EmployeeID = 8
WHERE OrderID = 18


/* 4. */
