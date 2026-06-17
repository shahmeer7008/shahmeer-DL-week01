from typing import Any, Optional

import dlt
from dlt.common.pendulum import pendulum
from dlt.sources.rest_api import RESTAPIConfig, rest_api_resources


@dlt.source(name="github")
def github_source(
    access_token: Optional[str] = dlt.secrets.value,
) -> Any:

    print("GitHub token loaded:", bool(access_token))

    config: RESTAPIConfig = {

        "client": {
            "base_url": "https://api.github.com",
            "paginator": "header_link",

            "auth": {
                "type": "bearer",
                "token": access_token,
            },
        },

        "resource_defaults": {

            "primary_key": "id",

            "write_disposition": "merge",

            "endpoint": {
                "params": {
                    "per_page": 5
                }
            },
        },

        "resources": [

            {
                "name": "my_profile",

                "endpoint": {
                    "path": "user",
                },
            },


            {
                "name": "issues",

                "endpoint": {

                    "path": "repos/dlt-hub/dlt/issues",

                    "params": {
                        "sort": "updated",
                        "direction": "desc",
                        "state": "open",
                        "since": "{incremental.start_value}",
                    },

                    "incremental": {

                        "cursor_path": "updated_at",

                        "initial_value":
                            pendulum.today()
                            .subtract(days=30)
                            .to_iso8601_string(),
                    },
                },
            },
        ],
    }

    yield from rest_api_resources(config)


def load_github():

    pipeline = dlt.pipeline(
        pipeline_name="rest_api_github",
        destination="duckdb",
        dataset_name="github_data",
    )

    load_info = pipeline.run(
        github_source()
    )

    print(load_info)


if __name__ == "__main__":
    load_github()