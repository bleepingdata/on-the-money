DROP FUNCTION IF EXISTS bank.get_bank_transactions(int, int, int);

-- ============================================================
-- Function : bank.get_bank_transactions(int, int, int)
-- ============================================================
-- Purpose  : Returns the transaction history of one bank account,
--            newest first, with every descriptive field the bank supplied.
--            Paged so large histories can be loaded in batches.
--
-- Parameters
--   n_bank_account_id  (int) : Bank account primary key (bank.account).
--   n_limit            (int) : Maximum rows to return, 1 to 1000. Defaults to 200.
--   n_offset           (int) : Rows to skip, 0 or more. Defaults to 0.
--
-- Returns  : TABLE
--              transaction_id                   bigint  : Transaction primary key.
--              transaction_date                 date    : Date the transaction occurred.
--              processed_date                   date    : Date the bank processed it, may be NULL.
--              amount                           numeric : Transaction amount as supplied by the bank.
--              balance                          numeric : Account balance after the transaction, may be NULL.
--              bank_account_number              varchar : Account number on the bank record, may be NULL.
--              other_party_bank_account_number  varchar : Counterparty account number, may be NULL.
--              transaction_type                 varchar : Bank transaction type, may be NULL.
--              details                          varchar : Bank details field, may be NULL.
--              particulars                      varchar : Bank particulars field, may be NULL.
--              code                             varchar : Bank code field, may be NULL.
--              reference                        varchar : Bank reference field, may be NULL.
--              ofx_name                         varchar : OFX name field, may be NULL.
--              ofx_memo                         varchar : OFX memo field, may be NULL.
--              matched_import_rule_id           int     : Import rule that categorised it, NULL when none.
--
-- Usage
--   SELECT * FROM bank.get_bank_transactions(1);
--   SELECT * FROM bank.get_bank_transactions(1, 200, 200);
--
-- Dependencies
--   Tables    : bank.account, bank.transaction
-- ============================================================
CREATE OR REPLACE FUNCTION bank.get_bank_transactions(
    n_bank_account_id int,
    n_limit int DEFAULT 200,
    n_offset int DEFAULT 0
)
RETURNS TABLE (
    transaction_id bigint,
    transaction_date date,
    processed_date date,
    amount numeric,
    balance numeric,
    bank_account_number varchar,
    other_party_bank_account_number varchar,
    transaction_type varchar,
    details varchar,
    particulars varchar,
    code varchar,
    reference varchar,
    ofx_name varchar,
    ofx_memo varchar,
    matched_import_rule_id int
) AS $$
BEGIN
    -- Validate required parameters
    IF n_bank_account_id IS NULL THEN
        RAISE EXCEPTION 'n_bank_account_id must not be NULL';
    END IF;

    IF n_limit IS NULL OR n_limit < 1 OR n_limit > 1000 THEN
        RAISE EXCEPTION 'n_limit must be between 1 and 1000, received: %', n_limit
            USING HINT = 'Request smaller pages and use n_offset to read further rows';
    END IF;

    IF n_offset IS NULL OR n_offset < 0 THEN
        RAISE EXCEPTION 'n_offset must be 0 or more, received: %', n_offset;
    END IF;

    -- ERRCODE P0002 (no_data_found) lets callers tell a missing account from other failures
    IF NOT EXISTS (SELECT 1 FROM bank.account AS a WHERE a.bank_account_id = n_bank_account_id) THEN
        RAISE EXCEPTION 'Bank account not found: %', n_bank_account_id
            USING ERRCODE = 'P0002',
                  HINT = 'Check that the account exists in bank.account';
    END IF;

    RETURN QUERY
    SELECT
        bt.transaction_id,
        bt.transaction_date,
        bt.processed_date,
        bt.amount::numeric,
        bt.balance::numeric,
        bt.bank_account_number::varchar,
        bt.other_party_bank_account_number::varchar,
        bt.type::varchar,
        bt.details::varchar,
        bt.particulars::varchar,
        bt.code::varchar,
        bt.reference::varchar,
        bt.ofx_name::varchar,
        bt.ofx_memo::varchar,
        bt.matched_import_rule_id
    FROM bank.transaction AS bt
    WHERE bt.bank_account_id = n_bank_account_id
    -- transaction_id breaks ties so paging is stable for same-day transactions
    ORDER BY bt.transaction_date DESC, bt.transaction_id DESC
    LIMIT n_limit
    OFFSET n_offset;
END;
$$ LANGUAGE plpgsql;
