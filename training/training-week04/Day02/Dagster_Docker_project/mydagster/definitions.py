from dagster import Definitions

from .assets import dlt_pipeline
from .jobs import openAQ_job
from .schedules import daily_schedule

defs = Definitions(
    assets=[dlt_pipeline],
    jobs=[openAQ_job],
    schedules=[daily_schedule],
)