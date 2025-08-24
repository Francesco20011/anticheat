// Main JavaScript for the anti‑cheat dashboard. This file can be
// used to share functionality between different pages (e.g.
// authentication handling). At present no shared logic is
// implemented here because each page includes its own inline
// scripts.

// Example helper: parse JWT token (not used in this example). It
// returns the decoded payload object or null on failure. The
// function is defined in the global scope because modules are not
// used in this basic dashboard.
function parseJwt (token) {
    try {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));
        return JSON.parse(jsonPayload);
    } catch (e) {
        return null;
    }
}