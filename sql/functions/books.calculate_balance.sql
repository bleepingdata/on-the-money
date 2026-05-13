DROP FUNCTION IF EXISTS books.calculate_balance;

CREATE OR REPLACE FUNCTION books.calculate_balance(n_accountid int)
RETURNS TABLE (
    accountid_ret int,
    deposit_amount_total_ret numeric(16,2),
    withdrawal_amount_total_ret numeric(16,2)
)
AS $$
DECLARE
    d_deposit_amount_total numeric(16,2);
    d_withdrawal_amount_total numeric(16,2);
BEGIN
    /*
     get the balance for an account or accounts, taking the opening balance into account
     */

    SELECT SUM(depositamount)
    INTO d_deposit_amount_total
    FROM books.transaction t
        INNER JOIN books.transactionline tl ON t.transactionid = tl.transactionid
        INNER JOIN books.account a ON tl.accountid = a.accountid
    WHERE tl.accountid = n_accountid
        AND COALESCE(t.bankprocesseddate, '2100-01-01') >= a.openingbalancedate;

    SELECT SUM(withdrawalamount)
    INTO d_withdrawal_amount_total
    FROM books.transaction t
        INNER JOIN books.transactionline tl ON t.transactionid = tl.transactionid
        INNER JOIN books.account a ON tl.accountid = a.accountid
    WHERE tl.accountid = n_accountid
        AND COALESCE(t.bankprocesseddate, '2100-01-01') >= a.openingbalancedate;

    UPDATE books.account
    SET balance = (COALESCE(d_deposit_amount_total, 0) - COALESCE(d_withdrawal_amount_total, 0))
    WHERE accountid = n_accountid;

    RETURN QUERY
    SELECT n_accountid,
        COALESCE(d_deposit_amount_total, 0),
        COALESCE(d_withdrawal_amount_total, 0);
END;
$$ LANGUAGE plpgsql;