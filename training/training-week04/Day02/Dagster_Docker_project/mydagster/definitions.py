from dagster import Definitions

from .assets import dlt_pipeline
from .jobs import openAQ_job
from .schedules import daily_schedule
from .sensors import (
    slack_on_failure,
    slack_on_success,
    slack_on_cancel,
)
defs = Definitions(
    assets=[dlt_pipeline],
    jobs=[openAQ_job],
    schedules=[daily_schedule],
    sensors=[
        slack_on_failure,
        slack_on_success,
        slack_on_cancel,
    ]
)