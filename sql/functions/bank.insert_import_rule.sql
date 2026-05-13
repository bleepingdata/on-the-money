DROP FUNCTION IF EXISTS bank.insert_import_rule;

CREATE OR REPLACE FUNCTION bank.insert_import_rule(
    s_import_rule_type varchar(50),
    n_priority smallint DEFAULT 0
)
RETURNS int
AS $$
DECLARE
    n_import_rule_type_id smallint;
    n_import_rule_id int;
BEGIN
    SELECT import_rule_type_id INTO n_import_rule_type_id
    FROM bank.import_rule_type
    WHERE import_rule_type = s_import_rule_type;

    INSERT INTO bank.import_rule (import_rule_type_id, priority)
    VALUES (n_import_rule_type_id, n_priority)
    returning import_rule_id INTO n_import_rule_id;

    RETURN n_import_rule_id;
END;
$$ LANGUAGE plpgsql;