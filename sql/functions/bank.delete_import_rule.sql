DROP FUNCTION IF EXISTS bank.delete_import_rule(int4);

CREATE OR REPLACE FUNCTION bank.delete_import_rule(n_import_rule_id int4)
RETURNS void AS $$
BEGIN
    -- Block delete if any transaction or GL entry references this rule
    IF EXISTS (
        SELECT 1 FROM bank.transaction
        WHERE matched_import_rule_id = n_import_rule_id
    ) OR EXISTS (
        SELECT 1 FROM books.general_ledger
        WHERE matched_import_rule_id = n_import_rule_id
    ) THEN
        RAISE EXCEPTION 'Cannot delete rule %: it is referenced by existing transactions or GL entries. Re-categorise those transactions first.', n_import_rule_id;
    END IF;

    DELETE FROM bank.import_rule_fields_to_match
    WHERE import_rule_id = n_import_rule_id;

    DELETE FROM bank.import_rule_gl_matrix
    WHERE import_rule_id = n_import_rule_id;

    DELETE FROM bank.import_rule
    WHERE import_rule_id = n_import_rule_id;
END;
$$ LANGUAGE plpgsql;
