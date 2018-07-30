CREATE OR REPLACE FUNCTION BOOKS.InsertTransactionImportRule
	(FromAccount varchar(50),
	ToAccount varchar(50),
	Type VARCHAR(50),
	Details VARCHAR(50),
	Particulars VARCHAR(50),
	Code VARCHAR(50),
	Reference VARCHAR(50))
RETURNS void AS $$
BEGIN

	SET NOCOUNT ON;

	DECLARE @FromAccountId INT = (SELECT AccountId FROM BOOKS.Account WHERE [Description] = @FromAccount);
	DECLARE @ToAccountId INT = (SELECT AccountId FROM BOOKS.Account WHERE [Description] = @ToAccount);

	IF @FromAccountId IS NULL OR @ToAccountId IS NULL
	BEGIN
		RAISERROR('Unable to Insert Transaction Import rule because either @FromAccount %s or @ToAccount %s cannot be found', 15, 1, @FromAccount, @ToAccount) WITH NOWAIT;
		RETURN 1;
	END

	INSERT BOOKS.TransactionImportRules (FromAccountId, ToAccountId, [Type], [Details], Particulars, Code, Reference)
		VALUES (@FromAccountId, @ToAccountId, @Type, @Details, @Particulars, @Code, @Reference);
end;
$$ LANGUAGE plpgsql;