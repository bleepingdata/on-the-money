create
or replace
function books.prepare_import ( nBankAccountNumber varchar( 56 ) = null, nBankAccountDescription varchar( 50 ) = null ) returns void as $$ declare nBankAccountId int;

 begin
	 
 begin
	 -- truncate the table that will hold the imported data
 	delete from books.loadimportfile where 1=1;

 
 	truncate table BOOKS.LoadImportFile_Excel_ANZMortgage;
 EXCEPTION
 WHEN OTHERS THEN
 END;
 
-- Process a bank file from ANZ. The file contents must already exist in BOOKS.LoadImportFile table. Parameters determine which account the
-- transactions will be recorded against
-- get the bank account id
 select
	AccountId into
		nBankAccountId
	from
		BOOKS.Account
	where
		BankAccountNumber = coalesce( rtrim( nBankAccountNumber ), BankAccountNumber )
		and Description = coalesce( rtrim( nBankAccountDescription ), Description )
		and ( nBankAccountNumber is not null
		or nBankAccountDescription is not null );

	
 if nBankAccountId is null then 
 	raise exception 'Unable to find BOOKS.Account entry for bank account %, description %',	nBankAccountNumber,	nBankAccountDescription;
 end if;
 


 delete
from
	BOOKS.TransactionLineStaging
where
	1 = 1;

 delete
from
	BOOKS.TransactionStaging
where
	1 = 1;

 return;


end;

 $$ language plpgsql;