
import dagster as dg

@dg.asset
def customer():
    return [
        {
            "id":1,
            "name":"Hamid"
        },
        {
            "id":2,
            "name":"Hamza"
        }
    ]