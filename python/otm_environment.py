"""
Module: otm_environment
Purpose: Resolves a named environment into database connection settings and the bank-account
    incoming folders used by the bank file import scripts.

An environment is a git-ignored ``environments/*.json`` file with ``name``, ``privatePath`` and
an optional ``bankAccounts`` list. Connection details are read from ``connection_strings.py`` in
the private folder, which is parsed with ``ast`` and never executed. See environments/README.md.
"""
import ast
import getpass
import json
import logging
import os
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

_NAME_PATTERN = re.compile(r"^[a-z][a-z0-9_]{0,62}$")
_PLACEHOLDER_PASSWORD = "CHANGE_ME"
FILE_FORMATS = ("ofx", "anz_excel", "anz_mortgage_excel")


@dataclass
class BankAccountMapping:
    """Maps a bank.account description to the folder where its new bank files are dropped."""
    description: str
    incoming_folder: Path
    file_format: Optional[str] = None


@dataclass
class EnvironmentSettings:
    """Database connection settings and bank account folders for one environment."""
    name: str
    database: str
    username: str
    password: str
    host: str
    port: int
    private_path: Path
    bank_accounts: list[BankAccountMapping] = field(default_factory=list)


def _environment_roots() -> list[Path]:
    """
    Returns the folders that may contain environment JSON files.

    The repository layout (python/../environments) and the deployed layout
    (<AppPath>/environments, copied by deploy.ps1) are both supported.
    """
    here = Path(__file__).resolve().parent
    return [here.parent / "environments", here / "environments"]


def _find_environment_file(name: str) -> Path:
    """
    Finds the environment JSON file whose ``name`` (or file stem) matches.

    Args:
        name: Environment name.

    Returns:
        Path to the matching JSON file.

    Raises:
        ValueError: If no file or more than one file matches.
    """
    matches: list[Path] = []
    available: list[str] = []
    for root in _environment_roots():
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.json")):
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid JSON in '{path}': {exc}") from exc
            env_name = str(data.get("name") or path.stem)
            available.append(env_name)
            if env_name == name:
                matches.append(path)

    if not matches:
        raise ValueError(
            f"No environment '{name}' found. Available: {', '.join(sorted(set(available))) or '(none)'}. "
            "See environments/README.md."
        )
    if len(matches) > 1:
        raise ValueError(f"Environment '{name}' is ambiguous: {', '.join(str(m) for m in matches)}")
    return matches[0]


def _read_python_assignments(path: Path) -> dict[str, object]:
    """Reads simple ``name = literal`` assignments from a Python file without executing it."""
    values: dict[str, object] = {}
    for node in ast.parse(path.read_text(encoding="utf-8")).body:
        if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
            try:
                values[node.targets[0].id] = ast.literal_eval(node.value)
            except ValueError:
                continue
    return values


def _parse_bank_accounts(config_path: Path, entries: list[dict], private_path: Path) -> list[BankAccountMapping]:
    """Validates the ``bankAccounts`` section and resolves folders relative to the private path."""
    mappings: list[BankAccountMapping] = []
    for entry in entries:
        description = entry.get("description")
        folder = entry.get("incomingFolder")
        file_format = entry.get("format")
        if not description or not folder:
            raise ValueError(f"Each bankAccounts entry in '{config_path}' needs 'description' and 'incomingFolder'.")
        if file_format is not None and file_format not in FILE_FORMATS:
            raise ValueError(f"Invalid format '{file_format}' in '{config_path}'. Use one of: {', '.join(FILE_FORMATS)}.")
        incoming = (private_path / str(folder)).resolve()
        if private_path.resolve() not in incoming.parents:
            raise ValueError(f"incomingFolder '{folder}' in '{config_path}' must be inside the private path.")
        mappings.append(BankAccountMapping(str(description), incoming, file_format))
    return mappings


def load_environment(name: str) -> EnvironmentSettings:
    """
    Resolves an environment name to its settings.

    Args:
        name: Environment name (lowercase letters, digits, underscores).

    Returns:
        EnvironmentSettings. The password is empty if it is unset or the CHANGE_ME placeholder.

    Raises:
        ValueError: If the environment, its private folder or its connection file is invalid.

    Example:
        >>> settings = load_environment("sample_environment")
    """
    if not _NAME_PATTERN.match(name):
        raise ValueError(f"Invalid environment name '{name}'.")

    config_path = _find_environment_file(name)
    config = json.loads(config_path.read_text(encoding="utf-8"))
    if not config.get("privatePath"):
        raise ValueError(f"Environment file '{config_path}' must define 'privatePath'.")
    private_path = Path(os.path.expandvars(str(config["privatePath"]))).expanduser().resolve()

    connection_file = private_path / "connection_strings.py"
    if not connection_file.is_file():
        raise ValueError(f"Missing '{connection_file}'. Run init-environment.ps1 -Environment {name}.")

    values = _read_python_assignments(connection_file)
    if not values.get("s_databasename"):
        raise ValueError(f"'{connection_file}' must define s_databasename.")

    password = str(values.get("s_password") or "")
    return EnvironmentSettings(
        name=name,
        database=str(values["s_databasename"]),
        username=str(values.get("s_username") or "postgres"),
        password="" if password == _PLACEHOLDER_PASSWORD else password,
        host=str(values.get("s_host") or "localhost"),
        port=int(values.get("n_port") or 5432),
        private_path=private_path,
        bank_accounts=_parse_bank_accounts(config_path, config.get("bankAccounts") or [], private_path),
    )


def ensure_password(settings: EnvironmentSettings) -> None:
    """Prompts for the database password when the environment does not store one."""
    if not settings.password:
        settings.password = getpass.getpass(f"Password for user {settings.username}: ")
