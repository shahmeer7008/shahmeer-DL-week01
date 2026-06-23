import requests
import dlt
from dlt.sources import incremental

API_KEY = dlt.secrets["sources.openaq.api_key"]
BASE_URL = "https://api.openaq.org/v3"
HEADERS = {"X-API-Key": API_KEY}

MAX_LOCATION_PAGES = 5
MAX_SENSOR_PAGES   = 3


def get_sensor_ids(max_pages=MAX_LOCATION_PAGES):
    sensor_ids = []
    for page in range(1, max_pages + 1):
        print(f"[get_sensor_ids] Fetching locations page {page}...")
        response = requests.get(
            f"{BASE_URL}/locations",
            headers=HEADERS,
            params={"page": page, "limit": 1000},
            timeout=30
        )
        response.raise_for_status()
        results = response.json().get("results", [])
        if not results:
            break
        for location in results:
            for sensor in location.get("sensors", []):
                sensor_ids.append(sensor["id"])
                if len(sensor_ids) >= 50:
                    print("[get_sensor_ids] Reached 50 sensors, stopping.")
                    return sensor_ids
        print(f"[get_sensor_ids] Running sensor count: {len(sensor_ids)}")
    print(f"[get_sensor_ids] Total sensors found: {len(sensor_ids)}")
    return sensor_ids


@dlt.resource(
    name="locations",
    primary_key="id",
    write_disposition="merge"
)
def locations():
    page = 1
    while True:
        print(f"[locations] Fetching page {page}...")
        response = requests.get(
            f"{BASE_URL}/locations",
            headers=HEADERS,
            params={"page": page, "limit": 1000},
            timeout=30
        )
        response.raise_for_status()
        results = response.json().get("results", [])
        if not results:
            print("[locations] Done.")
            break
        print(f"[locations] Yielding {len(results)} rows.")
        yield results
        page += 1


@dlt.resource(
    name="measurements",
    primary_key=["sensors_id", "period_datetime_from_utc"],  
    write_disposition="append"
)
def measurements(
    datetime_cursor=incremental(
        "period_datetime_from_utc",          
        initial_value="2024-01-01T00:00:00Z"
    )
):
    sensor_ids = get_sensor_ids()
    print(f"[measurements] Processing {len(sensor_ids)} sensors...")
    total_rows = 0

    for i, sensor_id in enumerate(sensor_ids):
        print(f"[measurements] Sensor {i+1}/{len(sensor_ids)}: id={sensor_id}")
        page = 1

        while page <= MAX_SENSOR_PAGES:
            response = requests.get(
                f"{BASE_URL}/sensors/{sensor_id}/measurements",
                headers=HEADERS,
                params={
                    "page": page,
                    "limit": 1000,
                    "datetime_from": datetime_cursor.last_value
                },
                timeout=30
            )

            if response.status_code == 404:
                print(f"  [measurements] 404 for sensor {sensor_id}, skipping.")
                break
            if response.status_code == 429:
                print("  [measurements] Rate limited! Waiting...")
                import time; time.sleep(2)
                continue

            response.raise_for_status()
            results = response.json().get("results", [])

            if not results:
                print(f"  [measurements] No results on page {page}, moving on.")
                break

            flattened = []
            for row in results:
                period  = row.get("period") or {}
                dt_from = period.get("datetimeFrom") or {}  
                dt_to   = period.get("datetimeTo") or {}
                param   = row.get("parameter") or {}
                coords  = row.get("coordinates") or {}

                flattened.append({
                    "sensors_id":                 sensor_id,
                    "period_datetime_from_utc":   dt_from.get("utc"),   
                    "period_datetime_from_local":  dt_from.get("local"),
                    "period_datetime_to_utc":     dt_to.get("utc"),
                    "period_datetime_to_local":   dt_to.get("local"),
                    "period_label":               period.get("label"),
                    "period_interval":            period.get("interval"),
                    "value":                      row.get("value"),
                    "has_flags":                  (row.get("flagInfo") or {}).get("hasFlags"),
                    "parameter_id":               param.get("id"),
                    "parameter_name":             param.get("name"),
                    "parameter_units":            param.get("units"),
                    "parameter_display_name":     param.get("displayName"),
                    "latitude":                   coords.get("latitude"),
                    "longitude":                  coords.get("longitude"),
                })

            total_rows += len(flattened)
            print(f"  [measurements] Sensor {sensor_id} page {page}: {len(flattened)} rows (total: {total_rows})")
            yield flattened
            page += 1

    print(f"[measurements] Done. Total rows yielded: {total_rows}")


@dlt.source
def openaq_source():
    return [locations, measurements]