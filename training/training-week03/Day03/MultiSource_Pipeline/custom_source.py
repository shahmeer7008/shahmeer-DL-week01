import dlt
import pandas as pd
import hashlib
import json


@dlt.resource(
    name="CallingAgents",
    primary_key="id",
    write_disposition="merge",
)
def public_dataset():

    df = pd.read_csv("callingagent.csv")

    df["id"] = df.apply(
        lambda row: hashlib.md5(
            json.dumps(
                row.to_dict(),
                sort_keys=True
            ).encode("utf-8")
        ).hexdigest(),
        axis=1
    )

    yield df.to_dict(orient="records")