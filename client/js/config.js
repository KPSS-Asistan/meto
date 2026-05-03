// Frontend Configuration
window.CONFIG = {
    // API URL of the backend server
    // Change this when deploying to a different server
    API_URL: window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' 
        ? 'http://localhost:8002' 
        : window.location.origin.replace(':8001', ':8002')
};
