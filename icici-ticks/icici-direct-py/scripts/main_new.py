from breeze_connect import BreezeConnect

# Initialize SDK
breeze = BreezeConnect(api_key="l3391568WJ#20820_64f4H92)36&@k35")

# Obtain your session key from https://api.icicidirect.com/apiuser/login?api_key=YOUR_API_KEY
# Incase your api-key has special characters(like +,=,!) then encode the api key before using in the url as shown below.
import urllib
print("https://api.icicidirect.com/apiuser/login?api_key="+urllib.parse.quote_plus("l3391568WJ#20820_64f4H92)36&@k35"))

# Generate Session
print('gennn', breeze.generate_session(api_secret="7734i9c076%N89q313ao0r8128lhb845",
                        session_token="4137147"))

print(breeze)

# Generate ISO8601 Date/DateTime String
import datetime
iso_date_string = datetime.datetime.strptime("28/02/2021","%d/%m/%Y").isoformat()[:10] + 'T05:30:00.000Z'
iso_date_time_string = datetime.datetime.strptime("28/02/2021 23:59:59","%d/%m/%Y %H:%M:%S").isoformat()[:19] + '.000Z'

print(breeze.get_historical_data(interval="1minute",
                            from_date= "2022-08-15T07:00:00.000Z",
                            to_date= "2022-08-17T07:00:00.000Z",
                            stock_code="ICIBAN",
                            exchange_code="NFO",
                            product_type="futures",
                            expiry_date="2022-08-25T07:00:00.000Z",
                            right="others",
                            strike_price="0"))