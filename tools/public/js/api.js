/**
 * KPSS Question Editor - API Client v3.0
 * 
 * Modern, typed-style API client with:
 * - Centralized error handling
 * - Request/Response interceptors
 * - Loading state management
 * - Retry logic for network errors
 */

const API_URL = 'http://localhost:3456';

/**
 * API Configuration
 */
const API_CONFIG = {
    baseUrl: API_URL,
    timeout: 30000,
    retries: 2,
    retryDelay: 1000
};

/**
 * Custom API Error class
 */
class APIError extends Error {
    constructor(message, status, data = null) {
        super(message);
        this.name = 'APIError';
        this.status = status;
        this.data = data;
    }
}

/**
 * Sleep utility for retry delays
 */
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Core fetch wrapper with error handling and retries
 */
const fetchWithRetry = async (url, options = {}, retries = API_CONFIG.retries) => {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), API_CONFIG.timeout);

    try {
        const response = await fetch(url, {
            ...options,
            signal: controller.signal
        });

        clearTimeout(timeoutId);

        // Parse response
        const data = await response.json().catch(() => ({}));

        // Check for errors
        if (!response.ok) {
            throw new APIError(
                data.error || `HTTP Error: ${response.status}`,
                response.status,
                data
            );
        }

        return data;

    } catch (error) {
        clearTimeout(timeoutId);

        // Handle abort/timeout
        if (error.name === 'AbortError') {
            throw new APIError('İstek zaman aşımına uğradı', 408);
        }

        // Retry on network errors
        if (retries > 0 && (error.name === 'TypeError' || error.name === 'NetworkError')) {
            console.warn(`[API] Retrying... (${retries} left)`);
            await sleep(API_CONFIG.retryDelay);
            return fetchWithRetry(url, options, retries - 1);
        }

        // Re-throw API errors
        if (error instanceof APIError) {
            throw error;
        }

        // Wrap other errors
        throw new APIError(error.message || 'Network error', 0);
    }
};

/**
 * Base request function
 */
const request = async (endpoint, options = {}) => {
    const url = `${API_CONFIG.baseUrl}${endpoint}`;

    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json'
        }
    };

    const mergedOptions = {
        ...defaultOptions,
        ...options,
        headers: {
            ...defaultOptions.headers,
            ...options.headers
        }
    };

    console.log(`[API] ${options.method || 'GET'} ${endpoint}`);

    return fetchWithRetry(url, mergedOptions);
};

/**
 * API Methods
 */
const API = {
    /**
     * Get all topics with question counts
     * @returns {Promise<Array>} List of topics
     */
    async getTopics() {
        return request('/topics');
    },

    /**
     * Detect topic from questions using AI
     * @param {Array} questions - Questions to analyze
     * @returns {Promise<Object>} Detection result
     */
    async detectTopic(questions) {
        return request('/detect', {
            method: 'POST',
            body: JSON.stringify({ questions })
        });
    },

    /**
     * Generate questions using AI
     * @param {string} topic - Topic name
     * @param {string} context - Additional context
     * @param {number} count - Number of questions to generate
     * @returns {Promise<Object>} Generated questions
     */
    async generateQuestions(topic, context, count) {
        return request('/ai-generate', {
            method: 'POST',
            body: JSON.stringify({ topic, context, count })
        });
    },

    /**
     * Validate questions
     * @param {string} topicId - Topic ID
     * @param {Array} questions - Questions to validate
     * @returns {Promise<Object>} Validation results
     */
    async validate(topicId, questions) {
        return request('/validate', {
            method: 'POST',
            body: JSON.stringify({ topicId, questions })
        });
    },

    /**
     * Fix question with AI
     * @param {Object} question - Question to fix
     * @param {Array} errors - Errors to fix
     * @returns {Promise<Object>} Fixed question
     */
    async fixQuestion(question, errors) {
        const result = await request('/ai-fix', {
            method: 'POST',
            body: JSON.stringify({ question, errors })
        });
        return result.fixed;
    },

    /**
     * Generate auto IDs for questions
     * @param {string} topicId - Topic ID
     * @param {Array} questions - Questions needing IDs
     * @returns {Promise<Object>} Questions with IDs
     */
    async generateAutoIds(topicId, questions) {
        return request('/auto-id', {
            method: 'POST',
            body: JSON.stringify({ topicId, questions })
        });
    },

    /**
     * Save questions to file
     * @param {string} topicId - Topic ID
     * @param {Array} questions - Questions to save
     * @returns {Promise<Object>} Save result
     */
    async saveToFile(topicId, questions) {
        return request('/add', {
            method: 'POST',
            body: JSON.stringify({ topicId, questions })
        });
    },

    /**
     * Check server health
     * @returns {Promise<boolean>} Server status
     */
    async healthCheck() {
        try {
            await request('/topics');
            return true;
        } catch {
            return false;
        }
    }
};

// Expose to window for global access
window.API = API;
window.APIError = APIError;
