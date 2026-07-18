import psycopg2

# Initialize variables to avoid NameError if connection fails
conn = None
cursor = None

try:
    print("Connecting to AWS RDS PostgreSQL...")
    conn = psycopg2.connect(
        host="my-app-database.c2dk80mm00fx.us-east-1.rds.amazonaws.com", # Your real endpoint (without :5432)
        port="5432",                                                      # The port goes here
        user="dbadmin",
        password="SuperSecret123!",
        dbname="appdb"
    )
    
    cursor = conn.cursor()
    cursor.execute("SELECT NOW();")
    record = cursor.fetchone()
    print("🎉 Connected successfully! Database time:", record[0])
    
except Exception as e:
    print("\n❌ Connection error:", e)
finally:
    # This block now runs safely even if the connection failed
    if cursor:
        cursor.close()
    if conn:
        conn.close()