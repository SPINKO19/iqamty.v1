const axios = require('axios');

module.exports = async (req, res) => {
  // 1. Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
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

  // 2. Define the target URL
  const TARGET_API_URL = process.env.TARGET_API_URL || 'https://progres.mesrs.dz/api';

  const targetPath = req.url.startsWith('/api/') ? req.url.replace('/api/', '') : req.url;
  const fullUrl = `${TARGET_API_URL.endsWith('/') ? TARGET_API_URL.slice(0, -1) : TARGET_API_URL}/${targetPath.startsWith('/') ? targetPath.slice(1) : targetPath}`;

  try {
    const targetUrl = new URL(fullUrl);
    const targetHost = targetUrl.hostname;

    // 3. Spoofing Headers (Trick #1)
    // We make the request look like it's coming from a real Chrome browser
    const spoofedHeaders = {
      ...req.headers,
      'host': targetHost,
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'accept': 'application/json, text/plain, */*',
      'accept-language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
      'origin': 'https://progres.mesrs.dz',
      'referer': 'https://progres.mesrs.dz/webtu/',
      'sec-ch-ua': '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
    };

    // 4. Forward the request with a longer timeout
    const response = await axios({
      method: req.method,
      url: fullUrl,
      data: req.body,
      headers: spoofedHeaders,
      responseType: 'arraybuffer',
      timeout: 25000, // 25s timeout for slow gov servers
      validateStatus: () => true,
    });

    res.status(response.status).send(response.data);
  } catch (error) {
    console.error('Proxy Error:', error.message);
    res.status(500).json({ 
      error: 'Proxy Connection Failed', 
      message: 'The target server is not responding. This usually means the IP is blocked or the server is down.',
      tip: 'Try using a local proxy or a different region.'
    });
  }
};
