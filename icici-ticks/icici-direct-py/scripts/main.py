# connecting with Breeze API

from breeze_connect import BreezeConnect


isec = BreezeConnect(api_key="your api key comes here")

isec.generate_session(api_secret="your secret key comes here", session_token="your session key comes here")

 

# initializing input variables like expiry date and strike price

start_date = "2022-04-19T07:00:00.000Z"

end_date = "2022-04-19T18:00:00.000Z"

 

expiry = "2022-04-21T07:00:00.000Z"

time_interval = "1minute"

 

strike = 17000

 

# downloading historical data for put option contract 

data1 = isec.get_historical_data(interval = time_interval,

                            from_date = start_date,

                            to_date = end_date,

                            stock_code = "NIFTY",

                            exchange_code = "NFO",

                            product_type = "options",

                            expiry_date = expiry,

                            right = "put",

                            strike_price = strike)

put_data = pd.DataFrame(data1["Success"])

 

# downloading historical data for Nifty

data2 = isec.get_historical_data(interval = time_interval,

                            from_date = start_date,

                            to_date = end_date,

                            stock_code = "NIFTY",

                            exchange_code = "NSE",

                            product_type = "cash")

stock_data = pd.DataFrame(data2["Success"])

 

# Transforming downloaded data into excel format

put_data.to_csv(index=False)

put_data.to_csv('Nifty put data.csv')

 

stock_data.to_csv(index=False)

stock_data.to_csv('Nifty index data.csv')