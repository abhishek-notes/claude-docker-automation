#!/usr/bin/env node

// Task API Server - Connects web frontend to Claude automation
const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3456;

app.use(cors());
app.use(express.json());
app.use(express.static('web'));

// Store active sessions
const activeSessions = new Map();

// Serve the web interface
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'web', 'task-launcher.html'));
});

// Also serve task launcher at /launcher
app.get('/launcher', (req, res) => {
    res.sendFile(path.join(__dirname, 'web', 'task-launcher.html'));
});

// API endpoint to launch automated task
app.post('/api/launch-task', async (req, res) => {
    try {
        const { projectPath, taskContent, sessionId } = req.body;
        
        if (!projectPath || !taskContent) {
            return res.status(400).json({ 
                error: 'Missing required fields: projectPath and taskContent' 
            });
        }
        
        // Validate project path exists
        try {
            await fs.access(projectPath);
        } catch (error) {
            return res.status(400).json({ 
                error: `Project path does not exist: ${projectPath}` 
            });
        }
        
        // Create task file in project directory
        const taskFilePath = path.join(projectPath, 'CLAUDE_TASKS.md');
        await fs.writeFile(taskFilePath, taskContent);
        
        // Start the automated Claude session
        const session = await launchClaudeSession(projectPath, sessionId);
        
        // Store session
        activeSessions.set(sessionId, session);
        
        res.json({ 
            success: true, 
            sessionId: sessionId,
            message: 'Task launched successfully',
            projectPath: projectPath
        });
        
    } catch (error) {
        console.error('Error launching task:', error);
        res.status(500).json({ 
            error: 'Failed to launch task',
            details: error.message 
        });
    }
});

// API endpoint to get session status
app.get('/api/session/:sessionId/status', (req, res) => {
    const sessionId = req.params.sessionId;
    const session = activeSessions.get(sessionId);
    
    if (!session) {
        return res.status(404).json({ error: 'Session not found' });
    }
    
    res.json({
        sessionId: sessionId,
        status: session.status,
        output: session.output,
        startTime: session.startTime,
        endTime: session.endTime
    });
});

// API endpoint to get session logs
app.get('/api/session/:sessionId/logs', (req, res) => {
    const sessionId = req.params.sessionId;
    const session = activeSessions.get(sessionId);
    
    if (!session) {
        return res.status(404).json({ error: 'Session not found' });
    }
    
    res.json({
        sessionId: sessionId,
        logs: session.logs || []
    });
});

// API endpoint to stop session
app.post('/api/session/:sessionId/stop', (req, res) => {
    const sessionId = req.params.sessionId;
    const session = activeSessions.get(sessionId);
    
    if (!session) {
        return res.status(404).json({ error: 'Session not found' });
    }
    
    if (session.process) {
        session.process.kill('SIGTERM');
        session.status = 'stopped';
        session.endTime = new Date().toISOString();
    }
    
    res.json({ 
        success: true, 
        message: 'Session stopped',
        sessionId: sessionId
    });
});

// API endpoint to get session results
app.get('/api/session/:sessionId/results', async (req, res) => {
    try {
        const sessionId = req.params.sessionId;
        const session = activeSessions.get(sessionId);
        
        if (!session) {
            return res.status(404).json({ error: 'Session not found' });
        }
        
        const projectPath = session.projectPath;
        const results = {
            sessionId: sessionId,
            projectPath: projectPath,
            files: {},
            gitStatus: null,
            gitCommits: []
        };
        
        // Check for result files
        const resultFiles = ['PROGRESS.md', 'SUMMARY.md', 'ISSUES.md'];
        
        for (const file of resultFiles) {
            const filePath = path.join(projectPath, file);
            try {
                const content = await fs.readFile(filePath, 'utf8');
                results.files[file] = content;
            } catch (error) {
                results.files[file] = null;
            }
        }
        
        res.json(results);
        
    } catch (error) {
        console.error('Error getting results:', error);
        res.status(500).json({ 
            error: 'Failed to get results',
            details: error.message 
        });
    }
});

// Launch Claude session
async function launchClaudeSession(projectPath, sessionId) {
    return new Promise((resolve, reject) => {
        const session = {
            sessionId: sessionId,
            projectPath: projectPath,
            status: 'starting',
            output: '',
            logs: [],
            startTime: new Date().toISOString(),
            endTime: null,
            process: null
        };
        
        // Launch terminal with Claude automation
        const scriptPath = path.join(__dirname, 'claude-terminal-launcher.sh');
        const childProcess = spawn(scriptPath, [projectPath, 'CLAUDE_TASKS.md'], {
            cwd: __dirname,
            env: { ...process.env },
            stdio: ['pipe', 'pipe', 'pipe'],
            detached: true
        });
        
        session.process = childProcess;
        
        // Handle stdout
        childProcess.stdout.on('data', (data) => {
            const output = data.toString();
            session.output += output;
            session.logs.push({
                type: 'stdout',
                message: output.trim(),
                timestamp: new Date().toISOString()
            });
        });
        
        // Handle stderr
        childProcess.stderr.on('data', (data) => {
            const output = data.toString();
            session.output += output;
            session.logs.push({
                type: 'stderr',
                message: output.trim(),
                timestamp: new Date().toISOString()
            });
        });
        
        // Handle process completion
        childProcess.on('close', (code) => {
            session.status = 'terminal_launched';
            session.endTime = new Date().toISOString();
            session.logs.push({
                type: 'system',
                message: `Terminal launched successfully. Claude is running in Terminal.app`,
                timestamp: new Date().toISOString()
            });
        });
        
        // Handle process errors
        childProcess.on('error', (error) => {
            session.status = 'error';
            session.endTime = new Date().toISOString();
            session.logs.push({
                type: 'error',
                message: error.message,
                timestamp: new Date().toISOString()
            });
        });
        
        // Update status to running
        setTimeout(() => {
            session.status = 'running';
        }, 1000);
        
        resolve(session);
    });
}

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'ok',
        timestamp: new Date().toISOString(),
        activeSessions: activeSessions.size
    });
});

// List all sessions
app.get('/api/sessions', (req, res) => {
    const sessions = Array.from(activeSessions.entries()).map(([id, session]) => ({
        sessionId: id,
        status: session.status,
        projectPath: session.projectPath,
        startTime: session.startTime,
        endTime: session.endTime
    }));
    
    res.json({ sessions });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Claude Task API Server running on http://localhost:${PORT}`);
    console.log(`📱 Web Interface: http://localhost:${PORT}`);
    console.log(`⚡ API Endpoints:`);
    console.log(`   POST /api/launch-task - Launch automated task`);
    console.log(`   GET  /api/session/:id/status - Get session status`);
    console.log(`   GET  /api/session/:id/logs - Get session logs`);
    console.log(`   POST /api/session/:id/stop - Stop session`);
    console.log(`   GET  /api/session/:id/results - Get results`);
    console.log(`   GET  /api/sessions - List all sessions`);
    console.log(`   GET  /api/health - Health check`);
});

// Cleanup on exit
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down server...');
    
    // Stop all active sessions
    for (const [sessionId, session] of activeSessions) {
        if (session.process) {
            session.process.kill('SIGTERM');
        }
    }
    
    process.exit(0);
});