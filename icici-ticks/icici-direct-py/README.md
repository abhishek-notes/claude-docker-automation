# ICICI Direct Historical Data Fetcher (Python)

A Python implementation for fetching historical market data from ICICI Direct using the Breeze Connect library. This system provides a Pythonic interface to retrieve market data for stocks, futures, and options from Indian exchanges.

## 🚀 Quick Start

### Prerequisites
- Python 3.8 or higher
- ICICI Direct trading account with API access
- Valid API credentials from ICICI Direct

### Installation

#### Option 1: Use Existing Virtual Environment (Recommended)
```bash
# Activate existing environment (if paths work)
source breeze_venv/bin/activate

# Or create new environment if paths are broken
python3 -m venv new_env
source new_env/bin/activate
pip install breeze_connect pandas
```

#### Option 2: System-wide Installation
```bash
pip install breeze_connect pandas
```

### Get API Credentials
1. Login to ICICI Direct
2. Visit: `https://api.icicidirect.com/apiuser/login?api_key=YOUR_API_KEY`
3. Note: If your API key has special characters, URL encode it:
   ```python
   import urllib.parse
   encoded_key = urllib.parse.quote_plus("your_api_key")
   print(f"https://api.icicidirect.com/apiuser/login?api_key={encoded_key}")
   ```

## 📁 Files Overview

### 🟢 `scripts/main_new.py` - **Advanced Implementation**
Complete Python implementation with real API integration.

**Features:**
- ✅ Full breeze_connect integration
- ✅ URL encoding for special characters in API keys
- ✅ Example with ICICI Bank futures data
- ⚠️ Contains real credentials (needs updating)

**Usage:**
```bash
cd scripts
python main_new.py
```

**Code Structure:**
```python
from breeze_connect import BreezeConnect
import urllib

# Initialize with API key
breeze = BreezeConnect(api_key="your_api_key")

# Generate session
breeze.generate_session(api_secret="your_secret", session_token="your_token")

# Fetch historical data
data = breeze.get_historical_data(
    interval="1minute",
    from_date="2022-08-15T07:00:00.000Z",
    to_date="2022-08-17T07:00:00.000Z",
    stock_code="ICIBAN",
    exchange_code="NFO",
    product_type="futures",
    expiry_date="2022-08-25T07:00:00.000Z",
    right="others",
    strike_price="0"
)
```

### ⚠️ `scripts/main.py` - **Basic Template**
Basic template showing data fetching and CSV export functionality.

**Features:**
- ✅ Dual data fetching (options + index)
- ✅ CSV export functionality
- ⚠️ Missing pandas import
- ⚠️ Template credentials only

**Usage (after fixing imports):**
```bash
cd scripts
python main.py
```

**What it does:**
- Fetches NIFTY put options data
- Fetches NIFTY index data
- Saves both to CSV files

## 🔧 Environment Setup

### Current Environment Status
The existing `breeze_venv` contains:
- ✅ `breeze_connect-1.0.35`
- ✅ `pandas-2.0.0`
- ⚠️ Broken Python paths (needs fixing)

### Fix Existing Environment
```bash
# Method 1: Fix Python path
export PYTHONPATH="/workspace/icici-ticks/icici-direct-py/breeze_venv/lib/python3.10/site-packages:$PYTHONPATH"

# Method 2: Create new environment
cd icici-direct-py
python3 -m venv new_env
source new_env/bin/activate
pip install breeze_connect pandas
```

### Test Environment
```bash
python3 -c "import breeze_connect; import pandas; print('All imports successful!')"
```

## 🎯 Supported Operations

### Market Data Types
```python
# Stock/Index Data
product_type="cash"
exchange_code="NSE"  # or "BSE"

# Futures Data  
product_type="futures"
exchange_code="NFO"  # or "MCX"

# Options Data
product_type="options"
exchange_code="NFO"
right="call"  # or "put"
```

### Exchanges & Instruments
| Exchange | Product Types | Python Code |
|----------|---------------|-------------|
| NSE | Cash | `exchange_code="NSE"` |
| BSE | Cash | `exchange_code="BSE"` |
| NFO | Futures, Options | `exchange_code="NFO"` |
| MCX | Futures | `exchange_code="MCX"` |

### Time Intervals
```python
interval="1minute"    # 1-minute OHLCV
interval="5minute"    # 5-minute OHLCV
interval="30minute"   # 30-minute OHLCV
interval="1day"       # Daily OHLCV
```

## 📊 Data Processing

### Working with Retrieved Data
```python
import pandas as pd

# Get data
data = breeze.get_historical_data(...)

# Convert to DataFrame
df = pd.DataFrame(data["Success"])

# Save to CSV
df.to_csv('market_data.csv', index=False)

# Basic analysis
print(f"Records: {len(df)}")
print(f"Date range: {df['datetime'].min()} to {df['datetime'].max()}")
print(f"Price range: {df['low'].min()} to {df['high'].max()}")
```

### Data Fields Available
```python
# Standard OHLCV fields
df['open']     # Opening price
df['high']     # High price  
df['low']      # Low price
df['close']    # Closing price
df['volume']   # Volume traded

# Additional fields
df['datetime']        # Timestamp
df['open_interest']   # For F&O (futures & options)
df['strike_price']    # For options
df['expiry_date']     # For derivatives
df['exchange_code']   # Exchange identifier
```

## 🔐 Security Configuration

### Current Issues
⚠️ **Security Alert**: Both scripts contain hardcoded credentials

### Recommended Setup
1. **Create `.env` file:**
   ```
   ICICI_API_KEY=your_api_key
   ICICI_API_SECRET=your_api_secret
   ICICI_SESSION_TOKEN=your_session_token
   ```

2. **Use environment variables:**
   ```python
   import os
   from dotenv import load_dotenv
   
   load_dotenv()
   
   api_key = os.getenv('ICICI_API_KEY')
   api_secret = os.getenv('ICICI_API_SECRET') 
   session_token = os.getenv('ICICI_SESSION_TOKEN')
   ```

3. **Add to `.gitignore`:**
   ```
   .env
   *.pyc
   __pycache__/
   ```

## 🚨 Current Status

| Component | Status | Notes |
|-----------|---------|-------|
| breeze_connect | ✅ Installed | Version 1.0.35 available |
| pandas | ✅ Installed | Version 2.0.0 available |
| Environment | ⚠️ Broken Paths | Need to fix or recreate |
| main_new.py | ✅ Ready | Complete implementation |
| main.py | ⚠️ Missing Import | Need to add pandas import |
| Credentials | ⚠️ Expired | Need fresh session token |

## 🔧 Troubleshooting

### Common Issues

1. **ImportError: No module named 'breeze_connect'**
   ```bash
   # Solution: Fix environment or install packages
   pip install breeze_connect pandas
   ```

2. **ImportError: No module named 'pandas'**
   ```bash
   # Add missing import to main.py
   import pandas as pd
   ```

3. **Authentication Errors**
   - Get fresh session token from ICICI Direct
   - Verify API key and secret are correct
   - Check URL encoding for special characters

4. **Empty Data Response**
   - Verify market hours and trading days
   - Check instrument codes and exchange mapping
   - Ensure date range is valid

### Testing Setup
```bash
# Test environment
python3 -c "import breeze_connect; print('breeze_connect OK')"
python3 -c "import pandas; print('pandas OK')"

# Test with minimal script
python3 -c "
from breeze_connect import BreezeConnect
import pandas as pd
print('All imports successful!')
"
```

## 📈 Example Usage

### Fetch NIFTY Data
```python
from breeze_connect import BreezeConnect
import pandas as pd

# Initialize
breeze = BreezeConnect(api_key="your_api_key")
breeze.generate_session(api_secret="your_secret", session_token="your_token")

# Get NIFTY index data
data = breeze.get_historical_data(
    interval="1day",
    from_date="2024-01-01T07:00:00.000Z",
    to_date="2024-01-31T07:00:00.000Z",
    stock_code="NIFTY",
    exchange_code="NSE",
    product_type="cash"
)

# Process data
df = pd.DataFrame(data["Success"])
df.to_csv('nifty_jan_2024.csv', index=False)
print(f"Fetched {len(df)} records")
```

### Fetch Options Data
```python
# Get NIFTY call options
options_data = breeze.get_historical_data(
    interval="1minute",
    from_date="2024-01-25T07:00:00.000Z",
    to_date="2024-01-25T18:00:00.000Z",
    stock_code="NIFTY",
    exchange_code="NFO",
    product_type="options",
    expiry_date="2024-01-25T07:00:00.000Z",
    right="call",
    strike_price="21500"
)
```

## 🔄 Next Steps

1. **Fix Environment**: Set up working Python environment
2. **Update Credentials**: Get fresh API credentials
3. **Test Basic Call**: Start with simple data fetch
4. **Add Error Handling**: Improve robustness
5. **Automate Collection**: Set up scheduled data collection

## 📞 Support

- **ICICI Direct API**: Official documentation and support
- **Breeze Connect**: Python library documentation
- **Pandas**: Data manipulation library docs

## ⚖️ License

Open source - check individual package licenses for breeze_connect and pandas.