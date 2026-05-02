const axios = require('axios');

const proxies = [
    { host: '105.101.162.219', port: 80 },
    { host: '105.96.0.161', port: 8080 },
    { host: '41.111.137.218', port: 8080 },
    { host: '196.20.107.60', port: 80 },
    { host: '197.112.0.126', port: 80 }
];

async function testProxy(proxy) {
    console.log(`Testing Proxy: ${proxy.host}:${proxy.port}...`);
    try {
        const start = Date.now();
        const response = await axios.get('https://progres.mesrs.dz/api/authentication/v1/', {
            proxy: {
                host: proxy.host,
                port: proxy.port
            },
            timeout: 10000, // 10 seconds
            validateStatus: () => true // We just want to see if we get a response
        });
        
        const duration = Date.now() - start;
        console.log(`✅ SUCCESS! Status: ${response.status} (${duration}ms)`);
        return true;
    } catch (error) {
        console.log(`❌ FAILED: ${error.message}`);
        return false;
    }
}

async function runTests() {
    console.log('--- Algerian Proxy Tester ---');
    for (const proxy of proxies) {
        await testProxy(proxy);
        console.log('---------------------------');
    }
}

runTests();
