# ICICI Direct Repositories

This ICICI Direct implementation is split across multiple repositories for better organization:

## 📁 Repository Structure

### 1. **Node.js Implementation** 
- **Repository**: [abhishek-notes/icici-direct](https://github.com/abhishek-notes/icici-direct)
- **Language**: JavaScript/Node.js
- **Status**: ✅ **Fully working** (with credential updates)
- **Features**: Complete SDK implementation with authentication
- **Last Updated**: July 14, 2025

### 2. **Python Implementation** 
- **Repository**: This repository (`icici-ticks/icici-direct-py/`)
- **Language**: Python
- **Status**: ⚠️ **Needs environment setup**
- **Features**: breeze_connect library integration

### 3. **Documentation**
- **Repository**: This repository (`icici-ticks/`)
- **Files**: 
  - `ICICI_DIRECT_DOCUMENTATION.md` - Comprehensive technical documentation
  - `TESTING_STATUS.md` - Testing results and status
  - `REPOSITORIES.md` - This file

## 🚀 Quick Links

| Implementation | Repository | Status | Action |
|---------------|------------|---------|---------|
| **Node.js** | [icici-direct](https://github.com/abhishek-notes/icici-direct) | ✅ Ready | Update credentials & run |
| **Python** | `icici-direct-py/` | ⚠️ Setup needed | Fix environment |
| **Documentation** | `icici-ticks/` | ✅ Complete | Reference material |

## 📖 Getting Started

1. **For Node.js** (Recommended):
   ```bash
   git clone https://github.com/abhishek-notes/icici-direct.git
   cd icici-direct
   npm install
   # Update credentials in new_login_try.js
   node new_login_try.js
   ```

2. **For Python**:
   ```bash
   cd icici-ticks/icici-direct-py
   python3 -m venv venv
   source venv/bin/activate
   pip install breeze_connect pandas
   # Update credentials in scripts/main_new.py
   python scripts/main_new.py
   ```

## 🔄 Sync Status

- **Node.js Repo**: ✅ **Fully backed up** on GitHub
- **Python Code**: ✅ **Backed up** in this repository
- **Documentation**: ✅ **Backed up** in this repository

Both implementations are now safely backed up on GitHub with comprehensive documentation.