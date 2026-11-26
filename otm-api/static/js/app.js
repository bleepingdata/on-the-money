// Shared browser helpers for every On The Money page.
(function () {
    const csrfMeta = document.querySelector('meta[name="csrf-token"]');
    const csrfToken = csrfMeta ? csrfMeta.content : '';

    const money = new Intl.NumberFormat(undefined, { style: 'currency', currency: 'NZD' });

    // Add the CSRF header to requests that change data
    function csrfHeaders(extra) {
        return Object.assign({ 'X-CSRF-Token': csrfToken }, extra || {});
    }

    async function fetchJson(url) {
        const response = await fetch(url);
        const data = await response.json();
        if (!response.ok) throw new Error(data.error || response.statusText);
        return data;
    }

    // Show a message in a status element, styled by kind ('success', 'error' or '')
    function setStatus(element, message, kind) {
        element.textContent = message;
        element.className = kind ? 'status status--' + kind : 'status';
    }

    async function logout() {
        const response = await fetch('/logout', { method: 'POST', headers: csrfHeaders() });
        if (response.ok) window.location.assign('/login');
    }

    async function runMonthlyPopulation(button) {
        const status = document.getElementById('globalStatus');
        const menu = button.closest('.nav-menu');
        if (menu) menu.removeAttribute('open');
        button.disabled = true;
        setStatus(status, 'Running monthly population...', '');
        try {
            const response = await fetch('/summary/populate', { method: 'PUT', headers: csrfHeaders() });
            const text = await response.text();
            setStatus(status, response.ok ? text : 'Error: ' + text, response.ok ? 'success' : 'error');
        } catch (err) {
            setStatus(status, 'Network Error: ' + err.message, 'error');
        } finally {
            button.disabled = false;
        }
    }

    window.otm = { csrfHeaders, fetchJson, setStatus, money };

    document.addEventListener('DOMContentLoaded', () => {
        const logoutButton = document.getElementById('btnLogout');
        if (logoutButton) logoutButton.addEventListener('click', logout);

        const populateButton = document.getElementById('btnPopulate');
        if (populateButton) populateButton.addEventListener('click', () => runMonthlyPopulation(populateButton));
    });

    // Close any open dropdown menu when clicking elsewhere
    document.addEventListener('click', event => {
        document.querySelectorAll('.nav-menu[open]').forEach(menu => {
            if (!menu.contains(event.target)) menu.removeAttribute('open');
        });
    });
})();
