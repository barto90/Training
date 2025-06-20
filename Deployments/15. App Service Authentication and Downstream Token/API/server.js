const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// CORS configuration for cross-origin requests from the web app
app.use((req, res, next) => {
    // Allow requests from any Azure websites subdomain
    const origin = req.headers.origin;
    if (origin && origin.includes('azurewebsites.net')) {
        res.header('Access-Control-Allow-Origin', origin);
    }
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-MS-CLIENT-PRINCIPAL, X-MS-CLIENT-PRINCIPAL-NAME, X-MS-CLIENT-PRINCIPAL-ID');
    res.header('Access-Control-Allow-Credentials', 'true');
    
    if (req.method === 'OPTIONS') {
        res.sendStatus(200);
    } else {
        next();
    }
});

app.use(express.json());

app.get('/', (req, res) => {
    res.json({
        message: 'API is running with App Service Easy Auth',
        timestamp: new Date().toISOString(),
        authenticated: !!req.headers['x-ms-client-principal'],
        status: 'healthy',
        version: '3.0.0',
        authentication: 'App Service Easy Auth with Bearer token support'
    });
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development'
    });
});

app.get('/api/welcome', (req, res) => {
    try {
        const clientPrincipal = req.headers['x-ms-client-principal'];
        
        let userInfo = null;
        if (clientPrincipal) {
            const decoded = Buffer.from(clientPrincipal, 'base64').toString('utf-8');
            userInfo = JSON.parse(decoded);
        }

        const response = {
            message: "🎉 API CALL SUCCESSFUL WITH EASY AUTH!",
            timestamp: new Date().toISOString(),
            authenticated: !!clientPrincipal,
            user: userInfo ? {
                userId: userInfo.userId,
                userDetails: userInfo.userDetails,
                identityProvider: userInfo.identityProvider,
                claims: userInfo.claims
            } : null
        };

        res.json(response);
    } catch (error) {
        res.status(500).json({
            message: "Error processing authenticated request",
            timestamp: new Date().toISOString(),
            authenticated: !!req.headers['x-ms-client-principal'],
            error: error.message
        });
    }
});

app.get('/api/auth-info', (req, res) => {
    const authHeaders = {};
    
    // Extract all x-ms-* headers
    Object.keys(req.headers).forEach(key => {
        if (key.startsWith('x-ms-')) {
            authHeaders[key] = req.headers[key];
        }
    });

    let decodedUser = null;
    const clientPrincipal = req.headers['x-ms-client-principal'];
    if (clientPrincipal) {
        try {
            const decoded = Buffer.from(clientPrincipal, 'base64').toString('utf-8');
            decodedUser = JSON.parse(decoded);
        } catch (error) {
            decodedUser = { error: 'Failed to decode user info' };
        }
    }

    res.json({
        message: "Authentication information from App Service Easy Auth",
        timestamp: new Date().toISOString(),
        authHeaders: authHeaders,
        decodedUser: decodedUser,
        hasBearer: !!req.headers.authorization
    });
});

app.use((err, req, res, next) => {
    res.status(500).json({
        message: 'Internal server error',
        timestamp: new Date().toISOString()
    });
});

app.use((req, res) => {
    res.status(404).json({
        message: 'Endpoint not found',
        path: req.path,
        timestamp: new Date().toISOString(),
        availableEndpoints: [
            'GET / - Health check',
            'GET /health - Health status',
            'GET /api/welcome - Main API endpoint (Easy Auth protected)',
            'GET /api/auth-info - Authentication headers info (Easy Auth protected)'
        ]
    });
});

app.listen(port, () => {
    console.log(`API server running on port ${port}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Authentication: App Service Easy Auth enabled`);
    console.log(`Endpoints available:`);
    console.log(`  GET / - Health check`);
    console.log(`  GET /health - Health status`);
    console.log(`  GET /api/welcome - Main API endpoint (Easy Auth)`);
    console.log(`  GET /api/auth-info - Authentication headers info (Easy Auth)`);
}); 