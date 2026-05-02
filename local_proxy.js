const express = require('express');
const cors = require('cors');
const axios = require('axios');
const morgan = require('morgan');

const app = express();
const PORT = 3000;

// 1. Target URL (The Progres API)
const TARGET_API_URL = 'https://progres.mesrs.dz/api';

// 2. Middleware
app.use(morgan('dev')); // Logging
app.use(cors()); // Enable CORS for all origins
app.use(express.json()); // Parse JSON bodies

// 3. Proxy Logic
app.all('/api/*', async (req, res) => {
    // Extract the path after /api/
    const targetPath = req.url.replace('/api/', '');
    const fullUrl = `${TARGET_API_URL}/${targetPath}`;

    console.log(`[Proxy] ${req.method} ${fullUrl}`);

    try {
        const response = await axios({
            method: req.method,
            url: fullUrl,
            data: req.body,
            headers: {
                ...req.headers,
                host: 'progres.mesrs.dz', // Force the correct host header
            },
            // Important: Handle raw bytes if needed (e.g. for photos)
            responseType: 'arraybuffer',
            validateStatus: () => true, // Forward all status codes
        });

        // Forward the response
        res.status(response.status).send(response.data);
    } catch (error) {
        console.error(`[Proxy Error] ${error.message}`);
        res.status(500).json({
            error: 'Local Proxy Error',
            message: error.message
        });
    }
});

// 4. Start Server
app.listen(PORT, () => {
    console.log(`=================================================`);
    console.log(`🚀 LOCAL CORS PROXY RUNNING AT: http://localhost:${PORT}`);
    console.log(`🎯 TARGET: ${TARGET_API_URL}`);
    console.log(`=================================================`);
    console.log(`Instructions:`);
    console.log(`Run your Flutter app with:`);
    console.log(`flutter run -d chrome --dart-define=API_URL=http://localhost:${PORT}/api`);
    console.log(`=================================================`);
});
