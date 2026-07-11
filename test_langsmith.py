import os
from dotenv import load_dotenv
from langsmith import Client

def check_langsmith_connection():
    load_dotenv()
    
    api_key = os.getenv("LANGSMITH_API_KEY")
    endpoint = os.getenv("LANGSMITH_ENDPOINT", "https://api.smith.langchain.com")
    
    print("=" * 60)
    print("Checking LangSmith Connection Details:")
    print(f"Endpoint: {endpoint}")
    print(f"API Key:  {api_key[:12]}... (truncated)" if api_key else "API Key:  None found!")
    print("=" * 60)
    
    if not api_key:
        print("❌ Error: LANGSMITH_API_KEY is missing from your environment or .env file.")
        return

    try:
        print("Connecting to LangSmith servers...")
        client = Client(api_url=endpoint, api_key=api_key)
        
        # Test auth by trying to fetch the list of projects (limit to 1 to be fast)
        projects = list(client.list_projects(limit=1))
        
        print("\n================ CONNECTION SUCCESSFUL ================")
        print("✅ Successfully authenticated with LangSmith!")
        print("Your API key is active and working.")
        print("=======================================================")
        
    except Exception as e:
        error_msg = str(e)
        if "403" in error_msg or "Forbidden" in error_msg or "Unauthorized" in error_msg:
            print("\n================= AUTHENTICATION FAIL =================")
            print("❌ 403 Forbidden / Unauthorized")
            print("Your API key was rejected by the server.")
            print("Please check that your key is valid, active, and copied correctly.")
            print("=======================================================")
        else:
            print("\n================== CONNECTION ERROR ==================")
            print("❌ Failed to reach the server.")
            print(f"Details: {error_msg}")
            print("=======================================================")

if __name__ == "__main__":
    check_langsmith_connection()