# 🚀 Getting Started with Fresh ICICI Direct API Access

## Current Situation
Your old API key is expired ("Public Key does not exist" error). This guide will get you back up and running with fresh credentials.

## 📋 **Step 1: Get New API Credentials**

### **Method A: ICICI Direct Website**
1. **Login** → [ICICI Direct](https://www.icicidirect.com)
2. **Navigate** → Trading → API → Breeze API
3. **Apply/Reactivate** API access
4. **Download** new credentials

### **Method B: Customer Service** 
1. **Call**: ICICI Direct customer service
2. **Request**: "Breeze API access reactivation"  
3. **Mention**: "Need API for algorithmic trading/data analysis"
4. **Get**: New API Key + Secret

### **Method C: Branch Visit**
If online doesn't work:
1. Visit ICICI Direct branch
2. Request API access form
3. Submit required documents
4. Get credentials within 2-3 days

## 🔧 **Step 2: Set Up Secure Configuration**

### **A. Create Environment File**
```bash
cd /workspace/icici-ticks/icici-direct
cp .env.template .env
```

### **B. Add Your Credentials**
Edit `.env` file with your new credentials:
```
ICICI_API_KEY=your_new_api_key_here
ICICI_API_SECRET=your_new_api_secret_here  
ICICI_USER_ID=your_user_id_here
ICICI_SESSION_TOKEN=temporary_placeholder
```

### **C. Get Session Token**
1. **Open URL**: `https://api.icicidirect.com/apiuser/login?api_key=YOUR_NEW_API_KEY`
2. **Login** with your ICICI credentials
3. **Copy** the session token from response
4. **Update** `ICICI_SESSION_TOKEN` in `.env` file

## 🧪 **Step 3: Test the Setup**

### **Run Secure Script**
```bash
node new_login_secure.js
```

### **Expected Output**
```
🔑 Credentials loaded successfully
📊 Initializing ICICI Direct connection...
🌐 Session token URL: https://api.icicidirect.com/apiuser/login?api_key=...
✅ Session generated successfully!
📈 Testing API calls...
💰 Funds API Response: { ... }
📊 Fetching sample historical data...
✅ Data Points: 375
💾 Full data saved to: nifty_data_2025-07-14.json
```

## 🔍 **Troubleshooting**

### **Error: "Public Key does not exist"**
- ❌ API key is still invalid
- ✅ **Solution**: Get fresh API key from ICICI

### **Error: "Invalid Session Token"**  
- ❌ Session token expired (they expire quickly)
- ✅ **Solution**: Get fresh session token from login portal

### **Error: "Authentication Failed"**
- ❌ API secret is wrong
- ✅ **Solution**: Double-check API secret from ICICI portal

### **Error: "Rate Limit Exceeded"**
- ❌ Too many requests
- ✅ **Solution**: Wait 1-2 minutes and retry

## 📊 **What Data Can You Get?**

Once working, you can fetch:

### **Stock Data**
```javascript
stockCode: "RELIANCE", "TCS", "INFY"
exchangeCode: "NSE" or "BSE"  
productType: "cash"
```

### **Index Data**
```javascript
stockCode: "NIFTY", "BANKNIFTY", "SENSEX"
exchangeCode: "NSE"
productType: "cash"
```

### **Options Data**
```javascript
stockCode: "NIFTY", "BANKNIFTY"
exchangeCode: "NFO"
productType: "options"
right: "call" or "put"
strikePrice: "21000", "21500", etc.
```

### **Futures Data**  
```javascript
stockCode: "NIFTY", "BANKNIFTY"
exchangeCode: "NFO"
productType: "futures"
```

## ⏰ **Time Intervals Available**
- `1second` - Tick data (high frequency)
- `1minute` - 1-minute OHLCV
- `5minute` - 5-minute OHLCV
- `30minute` - 30-minute OHLCV  
- `1day` - Daily OHLCV

## 📅 **Market Hours**
- **Equity**: 9:15 AM - 3:30 PM
- **F&O**: 9:15 AM - 3:30 PM
- **Currency**: 9:00 AM - 5:00 PM

**Note**: Historical data is available 24/7, but fresh data only during market hours.

## 🔐 **Security Best Practices**

### **✅ Do:**
- Use `.env` file for credentials
- Get fresh session tokens regularly
- Keep API secret confidential
- Use HTTPS only

### **❌ Don't:**
- Hardcode credentials in files
- Share API keys publicly
- Use expired session tokens
- Make excessive API calls

## 🎯 **Quick Test Commands**

Once you have credentials:

### **Test 1: Check Connection**
```bash
node new_login_secure.js
```

### **Test 2: Get NIFTY Data**
```javascript
// Add to script:
stockCode: "NIFTY"
exchangeCode: "NSE"
interval: "1day"
```

### **Test 3: Get Options Data** 
```javascript
// Add to script:
stockCode: "NIFTY"
exchangeCode: "NFO"
productType: "options"
right: "call"
strikePrice: "21500"
```

## 📞 **Support Resources**

- **ICICI Direct**: 1860-267-6767
- **API Documentation**: Check ICICI Direct website
- **Technical Issues**: This codebase has working examples

## 🔄 **Next Steps After Getting Credentials**

1. ✅ **Get API credentials** from ICICI
2. ✅ **Setup `.env` file** with credentials  
3. ✅ **Test connection** with `new_login_secure.js`
4. ✅ **Fetch sample data** to verify everything works
5. ✅ **Scale up** to your specific data requirements

**Once you get the new credentials, we can test the system and start fetching the data you need!**