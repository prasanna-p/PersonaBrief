import requests
import os
import json
import vertexai
from vertexai.preview.generative_models import GenerativeModel, ChatSession


# Function to perform a Google Custom Search
def google_search(query):
    """
    Performs a Google Custom Search using the Custom Search JSON API.

    Args:
        query (str): The search query.

    Returns:
        str: The raw JSON response from the API as a string.
    """
    url = "https://www.googleapis.com/customsearch/v1"
    params = {
        "key": API_KEY,
        "cx": SEARCH_ENGINE_ID,
        "q": query,
        "num": 5  # Limit to the first 5 results
    }
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
    }

    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()  # Raise HTTPError for bad responses
        return response.text
    except requests.exceptions.RequestException as e:
        print(f"Error during API request: {e}")
        return ""


# Function to parse search results
def parse_results(json_string):
    """
    Extracts relevant information from the JSON response of Google Custom Search API.

    Args:
        json_string (str): The raw JSON response as a string.

    Returns:
        str: A formatted string of the first 5 search results.
    """
    try:
        json_data = json.loads(json_string)
        items = json_data.get("items", [])
        filtered_data = []

        # Extract relevant fields from each search result
        for item in items:
            filtered_data.append({
                "title": item.get("title"),
                "snippet": item.get("snippet"),
                "link": item.get("link"),
                "hcard": item.get("pagemap", {})
            })

        # Format the results for readability
        formatted_results = "\n\n".join([
            f"Title: {entry['title']}\nSnippet: {entry['snippet']}\nLink: {entry['link']}\nHCARD: {entry['hcard']}"
            for entry in filtered_data
        ])

        return formatted_results

    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")
        return ""
    except Exception as e:
        print(f"Error parsing results: {e}")
        return ""


# Function to save data to a file
def save_to_file(data, filename):
    """
    Saves data to a specified file.

    Args:
        data (str): The data to save.
        filename (str): The name of the file.
    """
    try:
        with open(filename, 'w', encoding='utf-8') as file:
            file.write(data)
        print(f"Data successfully written to {filename}")
    except Exception as e:
        print(f"An error occurred while writing to file: {e}")


# Function to get chat response
def get_chat_response(chat: ChatSession, prompt: str):
    """
    Sends the prompt to the chat session and returns the response.

    Args:
        chat (ChatSession): The chat session.
        prompt (str): The prompt to send.

    Returns:
        str: The response from the chat.
    """
    response = chat.send_message(prompt)
    return response.text


# Main function to orchestrate the search and result processing
def main():
    """
    Main function to handle user input, perform the search, and display results.
    """
    query = input("Enter the person's name to search: ")
    html = google_search(query)

    if html:
        save_to_file(html, 'search_results.json')
        results = parse_results(html)
        prompt = f"""
        Summarize the following search results about {query} into a concise paragraph. Focus on key details such as the person's roles, achievements, affiliations, and any notable aspects from the provided links. Ensure the summary is coherent and avoids redundancy.

        {results}

        1. Limit the summary to 100 words.
        2. If the results mention more than one person, prioritize the topmost result.
        3. If the query does not pertain to a person, explicitly mention that in the summary.
        """
        print(get_chat_response(chat, prompt))
    else:
        print("No results to display.")


# Entry point of the script
if __name__ == "__main__":
    # Retrieve API credentials from environment variables
    API_KEY = os.getenv('API_KEY')
    SEARCH_ENGINE_ID = os.getenv('SEARCH_ENGINE_ID')
    PROJECT_ID = os.getenv('PROJECT_ID')
    LOCATION = os.getenv('LOCATION')
    vertexai.init(project=PROJECT_ID, location=LOCATION)
    model = GenerativeModel("gemini-1.0-pro")
    chat = model.start_chat()

    if not API_KEY or not SEARCH_ENGINE_ID:
        print("Error: Missing API_KEY or SEARCH_ENGINE_ID environment variables.")
    else:
        main()
