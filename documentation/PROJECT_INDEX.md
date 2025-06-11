# Workspace Project Index

**Last Updated**: 2025-06-10 (Clean Directory Structure)  
**Purpose**: Master navigation file for Claude Code to understand project structure and locate codebases
**Location**: `/Users/abhishek/work/documentation/PROJECT_INDEX.md`

---

## 🏢 MAIN PROJECT: Palladio Software 25
**Business**: Jewelry E-commerce Platform with CRM Integration  
**Location**: `/Users/abhishek/work/palladio-software-25/`

### Core Components

#### 1. 🛒 **Backend (Palladio Store)**
- **Path**: `/Users/abhishek/work/palladio-software-25/palladio-store/`
- **Technology**: Medusa v2 E-commerce Platform
- **Purpose**: Core e-commerce backend with product, order, customer management
- **Key Features**: Salesforce sync, API endpoints, commerce modules
- **Git Status**: ✅ Active repository
- **Entry Points**: 
  - `medusa-config.ts` - Main configuration
  - `src/services/` - Business logic services
  - `src/subscribers/` - Event handling

#### 2. 🌐 **Frontend (Solution Medusa Starter)**
- **Path**: `/Users/abhishek/work/palladio-software-25/solace-medusa-starter/`  
- **Technology**: Next.js 14 + TypeScript
- **Purpose**: Customer-facing storefront
- **Key Features**: Product catalog, shopping cart, checkout
- **Git Status**: ✅ Active repository
- **Entry Points**:
  - `src/app/` - App router pages
  - `src/modules/` - UI components
  - `next.config.js` - Configuration

#### 3. 📝 **CMS (Strapi)**
- **Path**: `/Users/abhishek/work/palladio-software-25/palladio-store-strapi/`
- **Technology**: Strapi v4 Headless CMS
- **Purpose**: Content management for products and media
- **Key Features**: Admin panel, media upload, content types
- **Git Status**: ✅ Active repository
- **Entry Points**:
  - `src/api/` - API routes
  - `config/` - Configuration files

#### 4. 🔗 **CRM Integration (Pal Dev)**
- **Path**: `/Users/abhishek/work/palladio-software-25/Pal-dev/`
- **Technology**: Salesforce DX Project
- **Purpose**: CRM integration and customer management
- **Key Features**: Custom fields, sync workflows, metadata
- **Git Status**: ✅ Active repository
- **Entry Points**:
  - `force-app/main/` - Salesforce components
  - `config/project-scratch-def.json` - Org definition

#### 5. 🔌 **API Layer**
- **Path**: `/Users/abhishek/work/palladio-software-25/api-layer-2/`
- **Technology**: Node.js + TypeScript
- **Purpose**: Medusa-Salesforce integration bridge
- **Key Features**: Data sync, webhook handling, field mapping
- **Git Status**: ✅ Active repository
- **Entry Points**:
  - `src/services/salesforce.ts` - Salesforce service
  - `src/test-connection.ts` - Connection testing

---

## 📂 SUPPORTING PROJECTS

### Migration & Integration

#### **Aralco Salesforce Migration**
- **Path**: `/Users/abhishek/work/aralco-salesforce-migration/`
- **Purpose**: POS to Salesforce migration (150K+ records)
- **Status**: ✅ Completed migration project
- **Key Files**: `transform_data.py`, `exports/`

### Automation & Development Tools

#### **Claude Docker Automation**
- **Path**: `/Users/abhishek/work/automation/claude-docker-automation/`
- **Purpose**: Containerized Claude automation system
- **Key Files**: `claude-*.sh` scripts, `docker-compose.yml`

#### **Claude Automation**
- **Path**: `/Users/abhishek/work/automation/claude-automation/`
- **Purpose**: Multi-Claude collaboration system
- **Key Files**: `claude-*.sh` scripts, `dashboard/`

### Analysis & Documentation

#### **Spreadsheet Analysis**
- **Path**: `/Users/abhishek/work/Spreadsheets-analysed/`
- **Purpose**: Business data analysis tools
- **Key Files**: `analyze_spreadsheets.py`, demo data

---

## 🗂️ ARCHIVES & BACKUPS

### Active Archives
- **Archives/**: Old projects and demos
- **claude-*-backup-*/**: Session backups and conversation history
- **session-restore-info-*/**: Recovery information

---

## 🚀 QUICK START COMMANDS

### Palladio Software 25 Development
```bash
# Backend (Medusa)
cd /Users/abhishek/work/palladio-software-25/palladio-store/
npm run dev

# Frontend (Next.js)
cd /Users/abhishek/work/palladio-software-25/solace-medusa-starter/
npm run dev

# CMS (Strapi)
cd /Users/abhishek/work/palladio-software-25/palladio-store-strapi/
npm run develop

# API Layer
cd /Users/abhishek/work/palladio-software-25/api-layer-2/
npm run dev
```

### Testing & Validation
```bash
# Test Salesforce connection
cd /Users/abhishek/work/palladio-software-25/api-layer-2/
node test-connection-simple.js

# Run integration tests
cd /Users/abhishek/work/palladio-software-25/palladio-store/
npm test
```

---

## 📋 PROJECT STRUCTURE OVERVIEW

```
/Users/abhishek/work/
├── 🏢 palladio-software-25/    # MAIN PROJECT
│   ├── palladio-store/        # Backend (Medusa)
│   ├── solace-medusa-starter/ # Frontend (Next.js)
│   ├── palladio-store-strapi/ # CMS (Strapi)
│   ├── Pal-dev/              # CRM (Salesforce)
│   └── api-layer-2/          # Integration API
├── 🔄 aralco-salesforce-migration/ # Migration tools
├── 🤖 automation/              # AUTOMATION SYSTEMS + SCRIPTS
│   ├── claude-automation/     # Multi-Claude collaboration
│   ├── claude-docker-automation/ # Docker automation (task entry)
│   └── scripts/               # Utility scripts (70+)
├── 📊 Spreadsheets-analysed/   # Business data analysis
├── 📚 documentation/           # Guides, configs, PROJECT_INDEX.md
├── ⚙️ config/                  # Configuration files
├── 💾 backups/                 # All backups, exports, conversations
└── 📦 Archives/                # Historical projects
```

---

## 🎯 COMMON TASKS

### When working on Palladio Software 25:
1. **Product Management**: Work in `palladio-store/` backend
2. **UI/UX Changes**: Work in `solace-medusa-starter/` frontend  
3. **Content Updates**: Work in `palladio-store-strapi/` CMS
4. **CRM Integration**: Work in `Pal-dev/` and `api-layer-2/`
5. **Testing**: Use integration tests in respective folders

### For automation and tooling:
- **Claude Automation**: Use `automation/` folder systems
- **Utility Scripts**: Check `automation/scripts/` for helpful tools
- **Data Migration**: Reference `aralco-salesforce-migration/`
- **Business Analysis**: Use tools in `Spreadsheets-analysed/`
- **Documentation**: Reference guides in `documentation/`

---

**Note**: Always check Git status before making changes. Each main component has its own repository.