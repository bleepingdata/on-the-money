create sequence if not exists bank.import_identifier
    start with 1
    increment by 1
    minvalue 1
    no maxvalue
    cache 1;