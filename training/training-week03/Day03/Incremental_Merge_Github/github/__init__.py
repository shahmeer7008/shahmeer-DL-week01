import urllib.parse
from typing import Iterator, Optional, Sequence

import dlt
from dlt.common.typing import TDataItems
from dlt.sources import DltResource

from .helpers import get_reactions_data, get_rest_pages, get_stargazers



@dlt.source
def github_reactions(
    owner: str,
    name: str,
    access_token: str = dlt.secrets.value,
    items_per_page: int = 100,
    max_items: Optional[int] = None,
) -> Sequence[DltResource]:


    @dlt.resource(
        name="issues",
        primary_key="number",
        write_disposition="merge"
    )
    def issues(

        updated_at=dlt.sources.incremental(
            "updatedAt",
            initial_value="2024-01-01T00:00:00Z",
            last_value_func=max
        )

    ):

        for item in get_reactions_data(
            "issues",
            owner,
            name,
            access_token,
            items_per_page,
            max_items
        ):

            yield item



    @dlt.resource(
        name="pull_requests",
        primary_key="number",
        write_disposition="merge"
    )
    def pull_requests(

        updated_at=dlt.sources.incremental(
            "updatedAt",
            initial_value="2024-01-01T00:00:00Z",
            last_value_func=max
        )

    ):

        for item in get_reactions_data(
            "pullRequests",
            owner,
            name,
            access_token,
            items_per_page,
            max_items
        ):

            yield item



    return (
        issues,
        pull_requests
    )





@dlt.source(max_table_nesting=2)
def github_repo_events(
    owner: str,
    name: str,
    access_token: Optional[str] = None
):


    @dlt.resource(
        primary_key="id",
        table_name=lambda i: i["type"],
        write_disposition="append"
    )
    def repo_events(

        last_created_at=dlt.sources.incremental(
            "created_at",
            initial_value="1970-01-01T00:00:00Z",
            last_value_func=max
        )

    ):


        repo_path = (
            f"/repos/{urllib.parse.quote(owner)}/{urllib.parse.quote(name)}/events"
        )


        for page in get_rest_pages(
            access_token,
            repo_path + "?per_page=100"
        ):

            yield page


            if last_created_at.start_out_of_range:
                break



    return repo_events





@dlt.source
def github_stargazers(
    owner: str,
    name: str,
    access_token: str = dlt.secrets.value,
    items_per_page: int = 100,
    max_items: Optional[int] = None,
):


    @dlt.resource(
        name="stargazers",
        primary_key="login",
        write_disposition="merge"
    )
    def stargazers():

        yield from get_stargazers(
            owner,
            name,
            access_token,
            items_per_page,
            max_items
        )


    return (
        stargazers,
    )