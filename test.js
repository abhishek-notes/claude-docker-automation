const http = require('http');

function testImplementation() {
    console.log('Testing hello implementation...');
    
    // Test 1: Direct module execution
    console.log('\nTest 1: Direct execution');
    try {
        require('./hello.js');
        console.log('✓ Module loads successfully');
    } catch (error) {
        console.log('✗ Module failed to load:', error.message);
        return false;
    }
    
    // Test 2: HTTP server response
    console.log('\nTest 2: HTTP server response');
    const server = require('./hello.js');
    
    // Give server time to start
    setTimeout(() => {
        const req = http.request({
            hostname: 'localhost',
            port: 3000,
            path: '/',
            method: 'GET'
        }, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                if (data.trim() === 'hello') {
                    console.log('✓ Server responds with "hello"');
                } else {
                    console.log('✗ Server response incorrect:', data);
                }
                process.exit(0);
            });
        });
        
        req.on('error', (error) => {
            console.log('✗ HTTP request failed:', error.message);
            process.exit(1);
        });
        
        req.end();
    }, 1000);
    
    return true;
}

if (require.main === module) {
    testImplementation();
}