# ICICI Direct Historical Data Fetching System - Analysis & Documentation

## Overview
This folder contains code for fetching historical market data from ICICI Direct using their Breeze API. The implementation includes both Python and Node.js versions, with capabilities to fetch historical data for stocks, futures, and options from NSE, BSE, NFO, and MCX exchanges.

## Folder Structure
```
icici-ticks/
├── icici-direct/                    # Node.js implementation
│   ├── package.json                 # Dependencies: axios, breezeconnect, crypto
│   ├── README.md                    # Basic project README (minimal)
│   ├── login-session.js             # HMAC checksum calculation for authentication
│   ├── hist-icici.js                # Raw HTTP request example for historical data
│   ├── hist-data-resp.js            # Large JSON response file (~262KB)
│   ├── new_login_try.js             # Main working Node.js implementation
│   └── node_modules/                # Installed dependencies
│
└── icici-direct-py/                 # Python implementation
    ├── breeze_venv/                 # Virtual environment (with pandas, breeze_connect)
    └── scripts/
        ├── main.py                  # Basic Python example
        └── main_new.py              # Advanced Python implementation with credentials
```

## Code Analysis by File

### Node.js Implementation

#### 1. `new_login_try.js` ⭐ **WORKING**
- **Status**: Functional - successfully fetches data
- **Purpose**: Main implementation using breezeconnect library
- **Key Features**:
  - Uses BreezeConnect SDK wrapper
  - Fetches Bank Nifty options data (CNXBAN)
  - Configurable intervals: 1second, 1minute, 5minute, 30minute, 1day
  - Saves response to `hist-data-resp.js`
  - Includes fund balance checking
- **Data Retrieved**: Successfully fetched tick-by-tick options data from Feb 2023
- **API Call Example**:
  ```javascript
  breeze.getHistoricalDatav2({
    interval: "1second",
    fromDate: "2023-02-10T07:00:00.000Z",
    toDate: "2023-02-23T03:00:00.000Z",
    stockCode: "CNXBAN",
    exchangeCode: "NFO",
    productType: "options",
    expiryDate: "2023-03-02T07:00:00.000Z",
    right: "call",
    strikePrice: "40500"
  })
  ```

#### 2. `hist-icici.js` ⭐ **WORKING** 
- **Status**: Functional - raw HTTP implementation
- **Purpose**: Direct HTTP API calls without SDK
- **Key Features**:
  - Manual HTTP request construction
  - Uses axios for HTTP calls
  - Demonstrates raw API structure
  - Includes authentication headers (X-Checksum, X-Timestamp, X-AppKey, X-SessionToken)
- **Example**: Fetches ITC stock data from NSE

#### 3. `login-session.js` ⭐ **WORKING**
- **Status**: Functional - authentication helper
- **Purpose**: Generates HMAC-SHA256 checksum for API authentication
- **Key Features**:
  - Crypto-based signature generation
  - Required for manual HTTP requests
  - Demonstrates authentication mechanism

#### 4. `hist-data-resp.js` ⭐ **DATA CONFIRMED**
- **Status**: Contains real market data (~262KB)
- **Purpose**: Actual response from successful API call
- **Content**: Bank Nifty call options tick data
- **Data Format**: 
  ```json
  {
    "Error": null,
    "Status": 200,
    "Success": [
      {
        "close": "292.05",
        "datetime": "2023-02-22 14:52:34",
        "exchange_code": "NFO",
        "expiry_date": "02-MAR-2023",
        "high": "292.05",
        "low": "292.05",
        "open": "292.05",
        "open_interest": 514550,
        "product_type": "Options",
        "right": "Call",
        "stock_code": "CNXBAN",
        "strike_price": "40500",
        "volume": 0
      }
    ]
  }
  ```

### Python Implementation

#### 1. `main_new.py` ⚠️ **NEEDS CREDENTIALS UPDATE**
- **Status**: Code structure is correct but credentials exposed
- **Purpose**: Advanced Python implementation with real credentials
- **Key Features**:
  - Uses breeze_connect library (v1.0.35 installed)
  - Includes URL encoding for special characters in API key
  - Fetches ICICI Bank futures data
- **Issues**: 
  - Hardcoded API credentials (need to be replaced)
  - Session token might be expired

#### 2. `main.py` ⚠️ **TEMPLATE ONLY**
- **Status**: Template code - needs credentials
- **Purpose**: Basic example showing API structure
- **Key Features**:
  - Fetches both options and index data
  - Saves data to CSV files
  - Missing pandas import statement
  - Template placeholders for credentials

## Working Status Summary

### ✅ **WORKING COMPONENTS**:
1. **Node.js Implementation**: Fully functional
   - `new_login_try.js` - Main working script
   - `hist-icici.js` - Raw HTTP approach
   - `login-session.js` - Authentication helper
   - Dependencies properly installed

2. **Data Retrieval Confirmed**: 
   - Successfully fetched Bank Nifty options tick data
   - Response saved in `hist-data-resp.js` (262KB)
   - Data format validated and contains OHLCV + Open Interest

### ⚠️ **REQUIRES ATTENTION**:
1. **Python Implementation**: 
   - Environment setup: ✅ (pandas, breeze_connect installed)
   - Code structure: ✅ (correct API calls)
   - Credentials: ❌ (hardcoded/expired)
   - Missing import: ❌ (pandas import in main.py)

2. **Security Issues**:
   - API credentials exposed in multiple files
   - Session tokens hardcoded

## Technical Specifications

### Supported Markets & Instruments:
- **Exchanges**: NSE, BSE, NFO, NDX, MCX
- **Product Types**: cash, futures, options
- **Options Rights**: call, put, others
- **Time Intervals**: 1second, 1minute, 5minute, 30minute, 1day

### Authentication Method:
- HMAC-SHA256 checksum generation
- Time-based signature validation
- Session token required

### Data Fields Available:
- OHLCV (Open, High, Low, Close, Volume)
- Open Interest (for F&O)
- DateTime stamps
- Exchange/Symbol information
- Strike Price & Expiry (for options)

## Recommendations for Usage

### Immediate Use (Node.js):
1. Update API credentials in `new_login_try.js:4-5, 17`
2. Obtain fresh session token from ICICI Direct
3. Modify parameters for desired instrument/timeframe
4. Run: `node new_login_try.js`

### Python Setup Required:
1. Fix virtual environment paths or recreate environment
2. Add `import pandas as pd` to main.py:3
3. Replace placeholder credentials
4. Test with: `python main_new.py`

### Security Improvements Needed:
1. Move credentials to environment variables
2. Implement secure session management
3. Add error handling for expired tokens
4. Remove hardcoded credentials from git history

## API Rate Limits & Considerations
- Check ICICI Direct documentation for current rate limits
- Session tokens have expiration times
- Historical data availability may be limited by subscription
- Some data may require additional permissions

## Next Steps for Implementation
1. Secure credential management
2. Error handling improvement
3. Data validation and cleaning
4. Automated data collection scheduling
5. Database storage integration