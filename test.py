import os
from dotenv import load_dotenv

from tools.tavily_tool import tavily_search
from tools.flight_tool import search_flights
from backend import run_travel_agent

# res = tavily_search("Best hotels in India")
# print(res)


# res = search_flights("Plan a 7 days India trip from Bangladesh")
# print(res)

user_input = input("Enter travel request: ")

response = run_travel_agent(
    user_input=user_input,
    thread_id="test_user"
)

print("\nFINAL RESPONSE:\n")
print(response["answer"])



# # Load the .env file first
# load_dotenv()

# # Now the client can automatically find the TAVILY_API_KEY in the environment
# client = TavilyClient()