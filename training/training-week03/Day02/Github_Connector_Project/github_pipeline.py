import dlt
from github import github_reactions


def GithubData():

    pipeline = dlt.pipeline(
        pipeline_name="github_reactions",
        destination="snowflake",
        dataset_name="github_data"
    )

    data = github_reactions(
        "dlt-hub",
        "dlt",
        max_items=100
    ).with_resources("pull_requests")


    load_info = pipeline.run(data)

    print(load_info)


GithubData()
