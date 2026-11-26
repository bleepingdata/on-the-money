"""Verify that the API requires a session and CSRF token without a database."""

import importlib.util
import os
import runpy
import secrets
import sys
import types
import unittest
from pathlib import Path
from unittest import mock


class ApiAuthTests(unittest.TestCase):
    """Exercise login and protected routes with a mocked database connection.

    Attributes:
        app: Flask application under test.
        conn: Mocked PostgreSQL connection.

    Example:
        >>> # python -m unittest discover -s test -p test_api_auth.py
    """

    @classmethod
    def setUpClass(cls) -> None:
        """Load the Flask module without private configuration or PostgreSQL.

        Args:
            None
        Returns:
            None
        Raises:
            ImportError: If API dependencies are unavailable.
        Example:
            >>> ApiAuthTests.setUpClass()
        """
        api_path = Path(__file__).resolve().parents[1] / 'otm-api' / 'otm-api.py'
        config = types.ModuleType('connection_strings')
        config.s_databasename = 'test'
        config.s_username = 'test'
        config.s_password = 'test'
        config.s_host = 'localhost'
        config.n_port = 5432
        summary = types.ModuleType('otm_summary')
        with mock.patch.dict(sys.modules, {'connection_strings': config, 'otm_summary': summary}), \
                mock.patch.dict(os.environ, {
                    'OTM_API_PASSWORD': 'test-password',
                    'OTM_API_SECRET_KEY': secrets.token_urlsafe(48),
                }), mock.patch('psycopg2.connect') as connect:
            spec = importlib.util.spec_from_file_location('otm_api_auth_test', api_path)
            module = importlib.util.module_from_spec(spec)
            with mock.patch.dict(sys.modules, {'otm_api_auth_test': module}):
                spec.loader.exec_module(module)
            cls.app = module.app
            cls.conn = connect.return_value
        cls.app.config['TESTING'] = True

    def setUp(self) -> None:
        """Create a fresh browser session for each case.

        Args:
            None
        Returns:
            None
        Raises:
            None
        Example:
            >>> case.setUp()
        """
        self.client = self.app.test_client()
        self.conn.reset_mock()

    def login(self) -> str:
        """Log in and return the session's CSRF token.

        Args:
            None
        Returns:
            str: The CSRF token for the current browser session.
        Raises:
            AssertionError: If login fails.
        Example:
            >>> token = case.login()
        """
        response = self.client.post('/login', json={'password': 'test-password'})
        self.assertEqual(response.status_code, 200)
        return response.get_json()['csrf_token']

    def test_requires_login_on_all_financial_routes(self) -> None:
        """Reject reads and writes before any database access.

        Args:
            None
        Returns:
            None
        Raises:
            AssertionError: If an unauthenticated request reaches a route.
        Example:
            >>> case.test_requires_login_on_all_financial_routes()
        """
        for path in ('/rules/list', '/accounts/bank', '/accounts/books',
                     '/accounts/bank/balances', '/accounts/bank/summary'):
            with self.subTest(path=path):
                self.assertEqual(self.client.get(path).status_code, 401)
        for method, path in (('put', '/summary/populate'),
                             ('post', '/rules/expense'), ('delete', '/rules/1')):
            with self.subTest(path=path):
                self.assertEqual(getattr(self.client, method)(path).status_code, 401)
        for path in ('/', '/rules', '/bank-accounts'):
            with self.subTest(path=path):
                self.assertEqual(self.client.get(path).status_code, 302)
        self.conn.cursor.assert_not_called()

    def test_login_and_csrf_protect_mutations(self) -> None:
        """Allow reads after login but reject invalid CSRF headers.

        Args:
            None
        Returns:
            None
        Raises:
            AssertionError: If login, CSRF, or logout behavior differs.
        Example:
            >>> case.test_login_and_csrf_protect_mutations()
        """
        self.assertEqual(self.client.get('/login').status_code, 200)
        self.assertEqual(self.client.post('/login', json={'password': ''}).status_code, 401)
        self.assertEqual(self.client.post('/login', json={}).status_code, 400)
        token = self.login()
        for path in ('/', '/rules', '/bank-accounts'):
            with self.subTest(page=path):
                page = self.client.get(path)
                self.assertEqual(page.status_code, 200)
                self.assertIn(token.encode('ascii'), page.data)
                self.assertIn(b'X-CSRF-Token', page.data)
        self.conn.cursor.return_value.fetchall.return_value = []
        self.assertEqual(self.client.get('/rules/list').status_code, 200)
        for method, path in (('put', '/summary/populate'),
                             ('post', '/rules/expense'), ('delete', '/rules/1'),
                             ('post', '/logout')):
            with self.subTest(path=path):
                self.assertEqual(getattr(self.client, method)(path).status_code, 403)
                self.assertEqual(getattr(self.client, method)(
                    path, headers={'X-CSRF-Token': 'wrong'}).status_code, 403)
        self.assertEqual(self.client.post('/logout', headers={
            'X-CSRF-Token': token}).status_code, 200)
        self.assertEqual(self.client.get('/rules/list').status_code, 401)

    def test_login_rotates_session_token(self) -> None:
        """Invalidate a prior token when a new login replaces the session.

        Args:
            None
        Returns:
            None
        Raises:
            AssertionError: If the old token remains valid.
        Example:
            >>> case.test_login_rotates_session_token()
        """
        first = self.login()
        second = self.login()
        self.assertNotEqual(first, second)
        self.assertEqual(self.client.post('/logout', headers={
            'X-CSRF-Token': first}).status_code, 403)
        self.assertEqual(self.client.post('/logout', headers={
            'X-CSRF-Token': second}).status_code, 200)

    def test_missing_secrets_prevent_startup(self) -> None:
        """Refuse to start when either authentication secret is missing.

        Args:
            None
        Returns:
            None
        Raises:
            AssertionError: If startup continues without both secrets.
        Example:
            >>> case.test_missing_secrets_prevent_startup()
        """
        api_path = Path(__file__).resolve().parents[1] / 'otm-api' / 'otm-api.py'
        config = types.ModuleType('connection_strings')
        config.s_databasename = config.s_username = config.s_password = config.s_host = 'test'
        config.n_port = 5432
        summary = types.ModuleType('otm_summary')
        for password, key in (('', secrets.token_urlsafe(48)), ('test-password', '')):
            with self.subTest(password_present=bool(password), key_present=bool(key)), \
                    mock.patch.dict(os.environ, {
                        'OTM_API_PASSWORD': password, 'OTM_API_SECRET_KEY': key
                    }), mock.patch.dict(sys.modules, {
                        'connection_strings': config, 'otm_summary': summary
                    }), mock.patch('psycopg2.connect') as connect:
                with self.assertRaises(RuntimeError):
                    runpy.run_path(str(api_path))
                connect.assert_not_called()


if __name__ == '__main__':
    unittest.main()
