
import dlt
from OpenAQ_Source import openaq_source

pipeline = dlt.pipeline(
    pipeline_name="openaq_pipeline",
    destination="snowflake",
    dataset_name="openaq_data",
    dev_mode=False        
)

load_info = pipeline.run(openaq_source())

print(load_info)


print("\n--- Load Details ---")
for package in load_info.load_packages:
    print(f"Load ID : {package.load_id}")
    print(f"Status  : {package.state}")
    for job in package.jobs.get("failed_jobs", []):
        print(f"FAILED JOB: {job.job_file_path} — {job.failed_message}")