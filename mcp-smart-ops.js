#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import fs from 'fs/promises';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);
const TRASH_DIR = '/Users/abhishek/.Trash';
const BACKUP_DIR = '/Users/abhishek/work/automation/claude-docker-automation/backups';

class SmartOperationsServer {
  constructor() {
    this.server = new Server({
      name: 'smart-operations',
      version: '2.0.0'
    }, {
      capabilities: {
        tools: {}
      }
    });
    
    this.setupHandlers();
  }

  setupHandlers() {
    this.server.setRequestHandler('ListToolsRequest', async () => ({
      tools: [
        {
          name: 'safe_delete',
          description: 'Move to trash instead of permanent delete',
          inputSchema: {
            type: 'object',
            properties: {
              filepath: { type: 'string' }
            },
            required: ['filepath']
          }
        },
        {
          name: 'versioned_backup',
          description: 'Create versioned backup with git-like naming',
          inputSchema: {
            type: 'object',
            properties: {
              filepath: { type: 'string' },
              reason: { type: 'string' }
            },
            required: ['filepath']
          }
        },
        {
          name: 'detect_api_changes',
          description: 'Detect breaking changes in APIs/functions',
          inputSchema: {
            type: 'object',
            properties: {
              oldFile: { type: 'string' },
              newFile: { type: 'string' }
            },
            required: ['oldFile', 'newFile']
          }
        },
        {
          name: 'force_operation',
          description: 'Execute operation without prompts',
          inputSchema: {
            type: 'object',
            properties: {
              command: { type: 'string' },
              args: { type: 'array', items: { type: 'string' } }
            },
            required: ['command']
          }
        },
        {
          name: 'create_snapshot',
          description: 'Create full project snapshot',
          inputSchema: {
            type: 'object',
            properties: {
              projectPath: { type: 'string' },
              message: { type: 'string' }
            },
            required: ['projectPath']
          }
        }
      ]
    }));

    this.server.setRequestHandler('CallToolRequest', async (request) => {
      const { name, arguments: args } = request.params;
      
      switch (name) {
        case 'safe_delete':
          return this.safeDelete(args.filepath);
        case 'versioned_backup':
          return this.versionedBackup(args.filepath, args.reason);
        case 'detect_api_changes':
          return this.detectApiChanges(args.oldFile, args.newFile);
        case 'force_operation':
          return this.forceOperation(args.command, args.args);
        case 'create_snapshot':
          return this.createSnapshot(args.projectPath, args.message);
        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  async safeDelete(filepath) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = path.basename(filepath);
    const trashPath = path.join(TRASH_DIR, `${timestamp}_${filename}`);
    
    try {
      // Use system trash command for better integration
      await execAsync(`mv -f "${filepath}" "${trashPath}"`);
      
      // Log the operation
      await this.logOperation('safe_delete', { filepath, trashPath });
      
      return {
        toolResult: {
          success: true,
          message: `Moved to trash: ${trashPath}`,
          recoveryPath: trashPath
        }
      };
    } catch (error) {
      return {
        toolResult: {
          success: false,
          error: error.message
        }
      };
    }
  }

  async versionedBackup(filepath, reason = 'checkpoint') {
    try {
      const content = await fs.readFile(filepath, 'utf8');
      const hash = this.simpleHash(content).substring(0, 7);
      const timestamp = new Date().toISOString().split('T')[0];
      const filename = path.basename(filepath);
      const ext = path.extname(filename);
      const base = path.basename(filename, ext);
      
      const backupName = `${base}_${timestamp}_${hash}_${reason}${ext}`;
      const backupPath = path.join(BACKUP_DIR, backupName);
      
      await fs.mkdir(BACKUP_DIR, { recursive: true });
      await fs.writeFile(backupPath, content);
      
      // Create a manifest entry
      await this.updateBackupManifest(filepath, backupPath, reason);
      
      return {
        toolResult: {
          success: true,
          message: `Backed up to: ${backupPath}`,
          hash,
          backupPath
        }
      };
    } catch (error) {
      return {
        toolResult: {
          success: false,
          error: error.message
        }
      };
    }
  }

  async detectApiChanges(oldFile, newFile) {
    try {
      const oldContent = await fs.readFile(oldFile, 'utf8');
      const newContent = await fs.readFile(newFile, 'utf8');
      
      // Advanced detection patterns
      const patterns = {
        functions: {
          pattern: /(?:export\s+)?(?:async\s+)?function\s+(\w+)\s*\(([^)]*)\)/g,
          extract: (match) => ({ name: match[1], params: match[2] })
        },
        classes: {
          pattern: /(?:export\s+)?class\s+(\w+)(?:\s+extends\s+\w+)?\s*{/g,
          extract: (match) => ({ name: match[1] })
        },
        methods: {
          pattern: /(\w+)\s*\(([^)]*)\)\s*{/g,
          extract: (match) => ({ name: match[1], params: match[2] })
        },
        exports: {
          pattern: /export\s+{([^}]+)}/g,
          extract: (match) => ({ exports: match[1].split(',').map(e => e.trim()) })
        }
      };
      
      const oldApi = this.extractApi(oldContent, patterns);
      const newApi = this.extractApi(newContent, patterns);
      
      const breaking = {
        removed: [],
        modified: [],
        deprecated: []
      };
      
      // Check for removed items
      for (const [type, items] of Object.entries(oldApi)) {
        for (const item of items) {
          const found = newApi[type].find(newItem => 
            newItem.name === item.name
          );
          
          if (!found) {
            breaking.removed.push({ type, ...item });
          } else if (item.params && found.params !== item.params) {
            breaking.modified.push({
              type,
              name: item.name,
              oldParams: item.params,
              newParams: found.params
            });
          }
        }
      }
      
      // Check for @deprecated annotations
      const deprecatedPattern = /@deprecated/gi;
      const deprecatedMatches = newContent.match(deprecatedPattern);
      if (deprecatedMatches) {
        breaking.deprecated = deprecatedMatches.length;
      }
      
      const hasBreaking = breaking.removed.length > 0 || 
                         breaking.modified.length > 0;
      
      if (hasBreaking) {
        await this.createBreakingChangeReport(breaking);
      }
      
      return {
        toolResult: {
          hasBreakingChanges: hasBreaking,
          details: breaking,
          recommendation: hasBreaking ? 
            'STOP: Breaking changes detected. Review BREAKING_CHANGES.md' : 
            'Safe to proceed - no breaking changes detected'
        }
      };
    } catch (error) {
      return {
        toolResult: {
          success: false,
          error: error.message
        }
      };
    }
  }

  async forceOperation(command, args = []) {
    try {
      // Whitelist of allowed commands
      const allowedCommands = [
        'mv', 'cp', 'git', 'npm', 'node', 'yarn', 'pnpm',
        'prettier', 'eslint', 'jest', 'pytest'
      ];
      
      if (!allowedCommands.includes(command)) {
        throw new Error(`Command '${command}' not in whitelist`);
      }
      
      // Add force flags based on command
      const forceArgs = [...args];
      if (command === 'mv' || command === 'cp') {
        forceArgs.unshift('-f');
      }
      
      const { stdout, stderr } = await execAsync(
        `${command} ${forceArgs.join(' ')}`
      );
      
      return {
        toolResult: {
          success: true,
          stdout,
          stderr,
          command: `${command} ${forceArgs.join(' ')}`
        }
      };
    } catch (error) {
      return {
        toolResult: {
          success: false,
          error: error.message
        }
      };
    }
  }

  async createSnapshot(projectPath, message = 'snapshot') {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const snapshotName = `snapshot_${timestamp}_${message.replace(/\s+/g, '-')}`;
      const snapshotPath = path.join(BACKUP_DIR, 'snapshots', snapshotName);
      
      await fs.mkdir(path.dirname(snapshotPath), { recursive: true });
      
      // Create tarball snapshot
      await execAsync(
        `tar -czf "${snapshotPath}.tar.gz" -C "${path.dirname(projectPath)}" "${path.basename(projectPath)}"`
      );
      
      // Create snapshot manifest
      const manifest = {
        timestamp,
        message,
        projectPath,
        snapshotFile: `${snapshotPath}.tar.gz`,
        size: (await fs.stat(`${snapshotPath}.tar.gz`)).size
      };
      
      await fs.writeFile(
        `${snapshotPath}.json`,
        JSON.stringify(manifest, null, 2)
      );
      
      return {
        toolResult: {
          success: true,
          message: `Snapshot created: ${snapshotPath}.tar.gz`,
          manifest
        }
      };
    } catch (error) {
      return {
        toolResult: {
          success: false,
          error: error.message
        }
      };
    }
  }

  // Helper methods
  extractApi(content, patterns) {
    const api = {};
    
    for (const [type, config] of Object.entries(patterns)) {
      api[type] = [];
      const matches = content.matchAll(config.pattern);
      
      for (const match of matches) {
        api[type].push(config.extract(match));
      }
    }
    
    return api;
  }

  simpleHash(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(16);
  }

  async updateBackupManifest(originalPath, backupPath, reason) {
    const manifestPath = path.join(BACKUP_DIR, 'manifest.json');
    let manifest = [];
    
    try {
      const existing = await fs.readFile(manifestPath, 'utf8');
      manifest = JSON.parse(existing);
    } catch (e) {
      // File doesn't exist yet
    }
    
    manifest.push({
      timestamp: new Date().toISOString(),
      original: originalPath,
      backup: backupPath,
      reason
    });
    
    // Keep only last 1000 entries
    if (manifest.length > 1000) {
      manifest = manifest.slice(-1000);
    }
    
    await fs.writeFile(manifestPath, JSON.stringify(manifest, null, 2));
  }

  async createBreakingChangeReport(breaking) {
    const report = `# Breaking Changes Detected

Generated: ${new Date().toISOString()}

## Summary
- Removed: ${breaking.removed.length} items
- Modified: ${breaking.modified.length} items
- Deprecated: ${breaking.deprecated || 0} items

## Details

### Removed
${breaking.removed.map(item => 
  `- ${item.type}: ${item.name}`
).join('\n')}

### Modified
${breaking.modified.map(item => 
  `- ${item.type}: ${item.name}
  - Old: ${item.oldParams}
  - New: ${item.newParams}`
).join('\n\n')}

## Recommendation
1. Create migration guide
2. Update documentation
3. Consider major version bump
4. Notify dependent projects
`;
    
    await fs.writeFile('BREAKING_CHANGES.md', report);
  }

  async logOperation(operation, details) {
    const logPath = path.join(BACKUP_DIR, 'operations.log');
    const entry = {
      timestamp: new Date().toISOString(),
      operation,
      details
    };
    
    try {
      await fs.appendFile(
        logPath,
        JSON.stringify(entry) + '\n'
      );
    } catch (e) {
      // Silent fail for logging
    }
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
  }
}

const server = new SmartOperationsServer();
server.start();
