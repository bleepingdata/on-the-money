"""
Script: ImportBankFiles.py
Purpose: Single entry point for importing bank files (OFX and ANZ Excel) for an environment.

Usage:
    python ImportBankFiles.py -e <environment>                      # all new files for all mapped accounts
    python ImportBankFiles.py -e <environment> -a "<account>"       # new files for one account
    python ImportBankFiles.py -e <environment> -f <file> [-a "<account>"]   # one specific file

Connection details and the account-to-folder mapping come from the environment
(see environments/README.md). New files copied to an account's incoming folder are imported,
then moved to its ``processed`` sub-folder. A file named with -f is imported again as given
(use this to re-import a file); it is only moved if it is waiting in an incoming folder.
"""
import logging
import sys
from argparse import ArgumentParser

from otm_environment import ensure_password, load_environment
from otm_incoming import (archive_file, find_account_for_file, import_file, locate_file,
                          pending_files)

logger = logging.getLogger(__name__)


def main() -> int:
    """
    Runs the import.

    Returns:
        Process exit code: 0 on success, 1 if any file failed.
    """
    parser = ArgumentParser(description="Import bank files (OFX and ANZ Excel) for an environment.")
    parser.add_argument("-e", "--environment", required=True, help="environment name")
    parser.add_argument("-a", "--account", help="bank account description (limits the run to this account)")
    parser.add_argument("-f", "--file", help="import this one file: a path, or a file name found under the incoming folders")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(message)s")
    try:
        settings = load_environment(args.environment)
    except ValueError as exc:
        parser.error(str(exc))

    accounts = settings.bank_accounts
    if args.account:
        accounts = [a for a in accounts if a.description.lower() == args.account.lower()]
        if not accounts:
            known = ", ".join(a.description for a in settings.bank_accounts) or "(none)"
            parser.error(f"Account '{args.account}' is not mapped in this environment. Mapped: {known}")
    if not accounts:
        parser.error("No bankAccounts are mapped in this environment. See environments/README.md.")

    ensure_password(settings)
    failures = 0

    if args.file:
        try:
            file_path = locate_file(settings, args.file)
        except FileNotFoundError as exc:
            parser.error(str(exc))
        account = accounts[0] if args.account else find_account_for_file(settings, file_path)
        if account is None:
            parser.error("Cannot tell which account this file is for; add -a \"<account>\".")
        try:
            logger.info("Importing %s into '%s'", file_path.name, account.description)
            import_file(settings, file_path, account)
            if file_path.resolve().parent == account.incoming_folder:
                archive_file(file_path, account)
        except Exception as exc:
            logger.error("FAILED %s: %s", file_path.name, exc)
            failures += 1
    else:
        for account in accounts:
            files = pending_files(account)
            logger.info("%s: %d file(s) waiting in %s", account.description, len(files), account.incoming_folder)
            for file_path in files:
                try:
                    logger.info("  Importing %s", file_path.name)
                    import_file(settings, file_path, account)
                    archive_file(file_path, account)
                except Exception as exc:
                    logger.error("  FAILED %s: %s", file_path.name, exc)
                    failures += 1
                    break  # later files for this account may depend on this one

    logger.info("Done%s", f" with {failures} failure(s)" if failures else "")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
