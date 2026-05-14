// Frontend Configuration
window.CONFIG = {
    // API URL of the backend server
    // Change this when deploying to a different server
    API_URL: (() => {
        // Detected via global variable (set by deployment script or server)
        // Default to hostname detection if APP_ENV is not set
        const env = window.APP_ENV || (window.location.hostname === 'localhost' ? 'dev' : 'prod');
        const hostname = window.location.hostname;

        console.log(`🌐 Environment: ${env}`);

        // Development
        if (env === 'dev' || hostname === 'localhost' || hostname === '127.0.0.1') {
            return 'http://localhost:8001';
        }

        // Stage
        if (env === 'stage') {
            // Adjust this to your stage backend IP/Hostname
            return `http://${hostname}:8001`;
        }

        // Production - env.js ile set edilmiş backend URL varsa onu kullan
        if (window.BACKEND_URL) {
            return window.BACKEND_URL;
        }
        return window.location.origin;
    })()
};
