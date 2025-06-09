#!/usr/bin/env node

// Parse Claude JSONL conversation files to readable format
// Usage: node parse-conversations.js <conversation-file.jsonl>

const fs = require('fs');
const path = require('path');

if (process.argv.length < 3) {
    console.log('Usage: node parse-conversations.js <conversation-file.jsonl>');
    console.log('Example: node parse-conversations.js /Users/abhishek/Work/claude-conversations-exports/046b5ee1-06f4-40d8-aabf-1ea30990a91c.jsonl');
    process.exit(1);
}

const filePath = process.argv[2];

if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    process.exit(1);
}

const content = fs.readFileSync(filePath, 'utf8');
const lines = content.trim().split('\n');

console.log(`📝 Parsing conversation from: ${path.basename(filePath)}`);
console.log(`📊 Found ${lines.length} messages`);
console.log('=' .repeat(80));

let messageCount = 0;

lines.forEach((line, index) => {
    try {
        const entry = JSON.parse(line);
        
        if (entry.message) {
            messageCount++;
            const timestamp = new Date(entry.timestamp).toLocaleString();
            const role = entry.message.role || 'unknown';
            
            console.log(`\n[${messageCount}] ${role.toUpperCase()} - ${timestamp}`);
            console.log('-'.repeat(60));
            
            let content = '';
            
            if (typeof entry.message.content === 'string') {
                content = entry.message.content;
            } else if (Array.isArray(entry.message.content)) {
                // Handle array format (Claude's response format)
                content = entry.message.content
                    .filter(item => item.type === 'text')
                    .map(item => item.text)
                    .join('\n');
            } else if (entry.message.content && typeof entry.message.content === 'object') {
                content = JSON.stringify(entry.message.content, null, 2);
            }
            
            if (content) {
                // Truncate very long messages for readability
                if (content.length > 2000) {
                    console.log(content.substring(0, 2000) + '\n... [truncated]');
                } else {
                    console.log(content);
                }
            }
        }
    } catch (error) {
        console.error(`Error parsing line ${index + 1}:`, error.message);
    }
});

console.log('\n' + '='.repeat(80));
console.log(`✅ Parsed ${messageCount} messages from conversation`);