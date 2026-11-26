"""
Module: otm_incoming
Purpose: Finds, dispatches and archives bank files for the environment's incoming folders.

Each bank account in the environment's ``bankAccounts`` section has an incoming folder. New
files copied there are imported, then moved to a ``processed`` sub-folder of the same folder.
"""
import logging
import shutil
from datetime import datetime
from pathlib import Path
from typing import Optional

from otm_environment import BankAccountMapping, EnvironmentSettings

logger = logging.getLogger(__name__)

PROCESSED_FOLDER = "processed"
_FORMAT_BY_EXTENSION = {".ofx": "ofx", ".qfx": "ofx", ".xls": "anz_excel", ".xlsx": "anz_excel"}


def resolve_format(account: BankAccountMapping, file_path: Path) -> Optional[str]:
    """
    Returns the file format for a file: the account's configured format, else inferred from the extension.

    Returns:
        One of otm_environment.FILE_FORMATS, or None if the extension is not supported.
    """
    return account.file_format or _FORMAT_BY_EXTENSION.get(file_path.suffix.lower())


def pending_files(account: BankAccountMapping) -> list[Path]:
    """
    Lists importable files waiting in an account's incoming folder (not its sub-folders), by name.

    Args:
        account: The bank account mapping.

    Returns:
        Sorted list of file paths; the folder is created if missing.
    """
    account.incoming_folder.mkdir(parents=True, exist_ok=True)
    files = [p for p in account.incoming_folder.iterdir()
             if p.is_file() and resolve_format(account, p) is not None]
    return sorted(files, key=lambda p: p.name.lower())


def archive_file(file_path: Path, account: BankAccountMapping) -> Path:
    """
    Moves a processed file into the account's ``processed`` sub-folder.

    A timestamp is added to the name if a file with the same name was already archived.

    Returns:
        The archived file's path.
    """
    processed = account.incoming_folder / PROCESSED_FOLDER
    processed.mkdir(parents=True, exist_ok=True)
    target = processed / file_path.name
    if target.exists():
        target = processed / f"{file_path.stem}_{datetime.now():%Y%m%d%H%M%S}{file_path.suffix}"
    shutil.copy2(file_path, target)
    file_path.unlink()
    return target


def find_account_for_file(settings: EnvironmentSettings, file_path: Path) -> Optional[BankAccountMapping]:
    """Returns the mapped account whose incoming folder (or its processed sub-folder) holds the file."""
    resolved = file_path.resolve()
    for account in settings.bank_accounts:
        if account.incoming_folder in resolved.parents:
            return account
    return None


def locate_file(settings: EnvironmentSettings, file_name: str) -> Path:
    """
    Resolves a file given by path, or by bare name searched under the mapped incoming folders.

    Args:
        settings: Environment settings.
        file_name: Existing path, or a file name.

    Returns:
        The file's path.

    Raises:
        FileNotFoundError: If not found, or the name matches several files.
    """
    candidate = Path(file_name)
    if candidate.is_file():
        return candidate
    matches = [p for account in settings.bank_accounts if account.incoming_folder.is_dir()
               for p in account.incoming_folder.rglob(candidate.name) if p.is_file()]
    if len(matches) == 1:
        return matches[0]
    if len(matches) > 1:
        raise FileNotFoundError(f"'{file_name}' matches several files: {', '.join(str(m) for m in matches)}")
    raise FileNotFoundError(f"Unable to find file '{file_name}'")


def import_file(settings: EnvironmentSettings, file_path: Path, account: BankAccountMapping) -> None:
    """
    Imports one file into an account using the importer for its format.

    Importers are loaded on demand so only the libraries for the formats in use are needed.

    Raises:
        ValueError: If the format is unsupported.
    """
    file_format = resolve_format(account, file_path)
    if file_format == "ofx":
        from otm_import_ofx import import_ofx_file
        import_ofx_file(settings, file_path, account.description)
    elif file_format in ("anz_excel", "anz_mortgage_excel"):
        from otm_import_excel import import_anz_excel_file
        import_anz_excel_file(settings, file_path, account.description, mortgage=file_format == "anz_mortgage_excel")
    else:
        raise ValueError(f"Unsupported file type for '{file_path.name}'")
