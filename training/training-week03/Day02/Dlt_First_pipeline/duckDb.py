import duckdb

con = duckdb.connect("rest_api_github.duckdb")

print(con.sql("SHOW TABLES"))

print(con.sql("""
SELECT login, id, public_repos
FROM github_data.my_profile
"""))