import duckdb

con = duckdb.connect()

df = con.execute("""
    SELECT *
    FROM read_csv_auto('sales_data.csv')
    LIMIT 5;
""").df()

print(df)