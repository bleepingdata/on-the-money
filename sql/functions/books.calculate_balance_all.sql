DROP FUNCTION IF EXISTS books.calculate_balance_all;

 CREATE OR REPLACE FUNCTION books.calculate_balance_all () RETURNS TABLE
	( accountid_ret int, deposit_amount_total_ret numeric ( 16, 2 ), withdrawal_amount_total_ret numeric( 16, 2 )) AS $$ DECLARE var_r record;

 BEGIN /* 
 get the balance for an account or accounts, taking the opening balance into account
 */
FOR var_r IN( SELECT
	accountid
FROM
	books.account 
	ORDER BY accountid ASC) LOOP 
	
	accountid_ret := var_r.accountid;

	SELECT
		*
		INTO accountid_ret, deposit_amount_total_ret, withdrawal_amount_total_ret
	FROM
		books.calculate_balance( accountid_ret );

 RETURN next;


END LOOP;


END;

 $$ LANGUAGE plpgsql;