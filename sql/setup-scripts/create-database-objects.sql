Use OnTheMoney
GO

CREATE SCHEMA BOOKS AUTHORIZATION DBO
GO

CREATE TABLE BOOKS.AccountType
(
AccountTypeId SMALLINT NOT NULL IDENTITY(1,1) CONSTRAINT PK_BOOKS_AccountType PRIMARY KEY CLUSTERED,
Description NVARCHAR(50) NOT NULL CONSTRAINT UQ_BOOKS_AccountType_Description UNIQUE
)
GO
SET IDENTITY_INSERT BOOKS.AccountType ON;
GO
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (0, 'Unknown Account Type');
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (1, 'Cash');
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (2, 'Bank');
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (3, 'Stock');
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (4, 'Mutual Fund');
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (5, 'Accounts Receivable');
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (6, 'Other Assets');
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (7, 'Equity');
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (8, 'Income');
INSERT BOOKS.AccountType(AccountTypeId, Description) VALUES (9, 'Expense');
SET IDENTITY_INSERT BOOKS.AccountType OFF;
GO

CREATE TABLE BOOKS.Account
(
AccountId INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_BOOKS_Account PRIMARY KEY CLUSTERED,
[AccountTypeId] SMALLINT NOT NULL CONSTRAINT FK_BOOKS_Account_AccountType FOREIGN KEY REFERENCES BOOKS.AccountType(AccountTypeId),
[AccountCode] CHAR(10) NOT NULL CONSTRAINT UQ_BOOKS_Account_AccountCode UNIQUE,
Description NVARCHAR(50) NOT NULL CONSTRAINT UQ_BOOKS_Account_Description UNIQUE,
[BankAccountNumber] NVARCHAR(56) NULL CONSTRAINT UQ_BOOKS_Account_BankAccountNumber UNIQUE,
[OpeningBalance] MONEY NOT NULL,
[OpeningBalanceDate] DATE NOT NULL,
[Balance] MONEY NOT NULL CONSTRAINT DF_BOOKS_Account_Balance DEFAULT(0)
)
GO
SET IDENTITY_INSERT BOOKS.Account ON;
GO
INSERT BOOKS.Account (AccountId, AccountTypeId, AccountCode, Description, OpeningBalance, OpeningBalanceDate, Balance)
	VALUES (0, 0, '0', 'Unknown Account', 0, '1900-01-01', 0);

SET IDENTITY_INSERT BOOKS.Account OFF;
GO

CREATE TABLE [BOOKS].[LoadImportFile]
(
[LoadImportFileId] BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BOOKS_LoadImportFile PRIMARY KEY CLUSTERED,
[Transaction Date] [varchar](50) NULL,
[Processed Date] [varchar](50) NULL,
[Type] [varchar](50) NULL,
[Details] [varchar](50) NULL,
[Particulars] [varchar](50) NULL,
[Code] [varchar](50) NULL,
[Reference] [varchar](50) NULL,
[Amount] [varchar](50) NULL,
[Balance] [varchar](50) NULL,
[To/From Account Number] [varchar](50) NULL,
[Conversion Charge] [varchar](50) NULL,
[Foreign Currency Amount] [varchar](50) NULL
) ON [PRIMARY]
GO


CREATE TABLE BOOKS.[Transaction]
(
TransactionId BIGINT IDENTITY (1,1) NOT NULL CONSTRAINT PK_BOOKS_Transaction PRIMARY KEY CLUSTERED,
TransactionDate DATE NOT NULL,
TransactionXML XML NOT NULL,
Amount MONEY NOT NULL,
ImportDatetime DATETIME2 NOT NULL CONSTRAINT DF_BOOKS_Transaction_ImportDatetime DEFAULT(SYSDATETIME()),
ImportUniqueIdentifier UNIQUEIDENTIFIER NOT NULL,
IsProcessed BIT NOT NULL CONSTRAINT DF_BOOKS_Transaction DEFAULT (0),
ProcessedDatetime DATETIME2 NULL
);
GO
CREATE TABLE BOOKS.[TransactionLine]
(
TransactionLineId BIGINT IDENTITY (1,1) NOT NULL CONSTRAINT PK_BOOKS_TransactionLine PRIMARY KEY CLUSTERED,
TransactionId BIGINT NOT NULL CONSTRAINT FK_BOOKS_TransactionLine_TransactionId FOREIGN KEY REFERENCES BOOKS.[Transaction](TransactionId),
AccountId INT NULL CONSTRAINT FK_BOOKS_TransactionLine_AccountId FOREIGN KEY REFERENCES BOOKS.Account(AccountId),
DepositAmount MONEY NULL,
WithdrawalAmount MONEY NULL
);
GO