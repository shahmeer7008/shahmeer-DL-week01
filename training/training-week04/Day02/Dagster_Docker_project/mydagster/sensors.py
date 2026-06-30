import os
import datetime

from dagster import (
    run_failure_sensor,
    run_status_sensor,
    DagsterRunStatus,
    DefaultSensorStatus,
)

from dagster_slack import SlackResource
from dotenv import load_dotenv

load_dotenv()

BASE_URL = "http://localhost:3000"


def get_slack():

    return SlackResource(
        token=os.getenv("SLACK_BOT_TOKEN")
    )


CHANNEL = "launchpad-technical"

@run_failure_sensor(
    default_status=DefaultSensorStatus.RUNNING
)
def slack_on_failure(context):

    run = context.dagster_run

    url = f"{BASE_URL}/runs/{run.run_id}"

    alert_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    message = f"""
    *Dagster Pipeline Failed*

*Job:* {run.job_name}

*Run ID:* `{run.run_id}`

*Time:* {alert_time}

*Logs:* {url}
"""

    get_slack().get_client().chat_postMessage(
        channel=CHANNEL,
        text=message
    )

@run_status_sensor(
    run_status=DagsterRunStatus.SUCCESS,
    default_status=DefaultSensorStatus.RUNNING,
)
def slack_on_success(context):

    run = context.dagster_run

    url = f"{BASE_URL}/runs/{run.run_id}"

    message = f"""
    *Dagster Pipeline Completed Successfully*

*Job:* {run.job_name}

*Run ID:* `{run.run_id}`

*Logs:* {url}
"""

    get_slack().get_client().chat_postMessage(
        channel=CHANNEL,
        text=message
    )

@run_status_sensor(
    run_status=DagsterRunStatus.CANCELED,
    default_status=DefaultSensorStatus.RUNNING,
)
def slack_on_cancel(context):

    run = context.dagster_run

    url = f"{BASE_URL}/runs/{run.run_id}"

    message = f"""
    *Dagster Run Canceled*

*Job:* {run.job_name}

*Run ID:* `{run.run_id}`

*Logs:* {url}
"""

    get_slack().get_client().chat_postMessage(
        channel=CHANNEL,
        text=message
    )