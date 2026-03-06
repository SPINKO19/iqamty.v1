const axios = require('axios');

module.exports = async (req, res) => {
  // 1. Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*'); // In production, replace '*' with your app's domain
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // 2. Define the target URL from Environment Variables (Pro Practice)
  const API_URL = process.env.TARGET_API_URL || 'https://progres.mesrs.dz/api';

  // Construct the full target path (/api/something -> https://progres.mesrs.dz/api/something)
  // The 'vercel.json' rewrite passes the relative path after /api/
  const targetPath = req.url.startsWith('/api/') ? req.url.replace('/api/', '') : req.url;
  const fullUrl = `${API_URL}/${targetPath}`;

  try {
    // 3. Forward the request
    const response = await axios({
      method: req.method,
      url: fullUrl,
      data: req.body,
      headers: {
        ...req.headers,
        host: 'progres.mesrs.dz', // Required by some servers to prevent rejection
      },
      // Important: Don't decode the response, pass it back as-is
      responseType: 'arraybuffer',
      validateStatus: () => true, // Forward all status codes (404, 500, etc.)
    });

    // 4. Send back the response
    res.status(response.status).send(response.data);
  } catch (error) {
    console.error('Proxy Error:', error.message);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
};
