# Environments

An environment is a named deploy target (for example `sample_environment`). Every `deploy.ps1` run needs one: `.\deploy.ps1 -Environment <name>`.

Two places hold an environment's configuration, each with a single job:

| What | Where | In git? |
|------|-------|---------|
| Pointer: environment `name` and `privatePath` | `environments\*.json` (this folder; sub-folders allowed; file name is free) | **No** - `environments/*.json` is git-ignored |
| Everything private: connection details (`connection_strings.py`), init SQL, bank exports, notes | the folder at `privatePath`, outside the repo | **No** |

Connection details (database, host, port, user, password) exist only in `connection_strings.py`, which is also the file the Flask API imports. Only this README and [environment.json.example](environment.json.example) are tracked.

## Environment file fields

- `name`: what you pass to `-Environment`. Lowercase letters, digits, underscores, starting with a letter. Optional; defaults to the file name without `.json`. Must be unique across all files.
- `privatePath`: the private folder. `~` and `%ENV_VARS%` are expanded. Must be outside the repo.
- `bankAccounts` (optional): maps bank accounts to incoming folders for `python/ImportBankFiles.py`. Each entry:
  - `description`: the account's description in `bank.account`
  - `incomingFolder`: folder (relative to `privatePath`) where new bank files are copied; `init-environment.ps1` creates it
  - `format` (optional): `ofx`, `anz_excel` or `anz_mortgage_excel`. Default is inferred from the file extension (`.ofx`/`.qfx` is OFX, `.xls`/`.xlsx` is `anz_excel`); set `anz_mortgage_excel` for mortgage accounts

## Create a new environment

1. Copy the template and edit it:

   ```powershell
   Copy-Item environments\environment.json.example environments\my_env.json
   ```

2. Scaffold the private folder (never overwrites existing files):

   ```powershell
   .\init-environment.ps1 -Environment my_env -Database otm_my_env
   ```

   Optional `-DbHost`, `-DbPort`, `-DbUser`. This creates `privatePath` containing `connection_strings.py`, `init\` (psql scripts), `bank-exports\`, `notes\` and a README.

3. Edit `connection_strings.py` in the private folder. Set `s_password`, or leave `CHANGE_ME` to be prompted once on deploy.
   Edit `init\01_bank.accounts.sql` with your accounts.

4. Deploy (creates the database if missing):

   ```powershell
   .\deploy.ps1 -Environment my_env
   ```

   Deploy runs the SQL folders, then `init\*.sql` from the private folder, copies `connection_strings.py` next to `otm-api.py` in `-AppPath`, and copies the `environments\*.json` pointers to `<AppPath>\environments` so the import scripts can resolve `-e`.

## Importing bank files

Copy files into an account's incoming folder, then run:

```powershell
python python/ImportBankFiles.py -e my_env                          # all accounts
python python/ImportBankFiles.py -e my_env -a "My Current Account"  # one account
python python/ImportBankFiles.py -e my_env -f statement.ofx         # one specific file (re-import)
```

Each imported file is moved to a `processed` sub-folder of its incoming folder. Connection details come only from the environment; there are no `-db`/`-u`/`-p` flags.

## Keeping this up to date

Any change to the environment file fields, `otm-environment.ps1`, `python/otm_environment.py`, `python/otm_incoming.py`, `python/ImportBankFiles.py`, `init-environment.ps1`, or the `deploy.ps1` parameters/private-data steps must update this file, `environment.json.example`, and the Setup section of the root README.
