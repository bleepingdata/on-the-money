drop
	function if exists books.calculate_balance_all;

 create
or replace
function books.calculate_balance_all () returns table
	( accountid_ret int, deposit_amount_total_ret numeric ( 16, 2 ), withdrawal_amount_total_ret numeric( 16, 2 )) as $$ declare var_r record;

 begin /* 
 get the balance for an account or accounts, taking the opening balance into account
 */
for var_r in( select
	accountid
from
	books.account 
	order by accountid asc) loop 
	
	accountid_ret := var_r.accountid;

	select
		*
		into accountid_ret, deposit_amount_total_ret, withdrawal_amount_total_ret
	from
		books.calculate_balance( accountid_ret );

 return next;


end loop;


end;

 $$ language plpgsql;