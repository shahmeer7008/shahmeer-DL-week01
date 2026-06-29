from dagster import asset
from mydagster.pipelines.pipeline import run_pipeline


@asset
def dlt_pipeline():
    run_pipeline()