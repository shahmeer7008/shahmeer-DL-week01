from dagster import ScheduleDefinition
from .jobs import openAQ_job

daily_schedule = ScheduleDefinition(
    job=openAQ_job,
    cron_schedule="0 0 * * *"
)