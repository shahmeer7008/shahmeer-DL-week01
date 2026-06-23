import dlt
from dotenv import load_dotenv

from custom_source import public_dataset
from stripe_analytics import stripe_source


load_dotenv()


pipeline = dlt.pipeline(
    pipeline_name="Multi_Source_pipeline",
    destination="snowflake",
    dataset_name="Multi_Source_Data"
)


# -------------------------
# CSV Custom Source
# -------------------------

csv_data = public_dataset()

load_info = pipeline.run(
    csv_data,
    table_name="CallingAgents"
)
print(load_info)


# -------------------------
# Stripe Verified Source
# -------------------------

stripe_data = stripe_source(
    endpoints=("Customer", "Charge","Subscription","PaymentIntent","Invoice")
)

load_info = pipeline.run(
    stripe_data
)
print(load_info)