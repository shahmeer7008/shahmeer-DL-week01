# test_api.py
import requests
import dlt

API_KEY = dlt.secrets["sources.openaq.api_key"]
BASE_URL = "https://api.openaq.org/v3"
HEADERS = {"X-API-Key": API_KEY}

# 1. Check locations endpoint
resp = requests.get(f"{BASE_URL}/locations", headers=HEADERS, params={"limit": 5})
print("Status:", resp.status_code)
print("Keys:", resp.json().keys())
data = resp.json()
print("Found:", data["meta"]["found"])
print("First location:", data["results"][0])

# 2. Check sensors inside that location
first_location = data["results"][0]
print("\nSensors in first location:", first_location.get("sensors"))

# 3. Test measurements for first sensor

    # test_api.py - print the raw row from sensor 12234782
sensor_id = 12234782
meas = requests.get(
    f"{BASE_URL}/sensors/{sensor_id}/measurements",
    headers=HEADERS,
    params={"limit": 3}
)
for row in meas.json()["results"]:
    print(row)
    print("\nMeasurements status:", meas.status_code)
    print("Measurements:", meas.json())


