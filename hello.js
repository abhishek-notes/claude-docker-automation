const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send('hello');
});

app.get('/api/hello', (req, res) => {
    res.json({ message: 'hello' });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log('Response: hello');
});

if (require.main === module) {
    console.log('hello');
}