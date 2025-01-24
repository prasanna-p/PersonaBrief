from flask import Flask, render_template, request
import requests
import os
import json
import vertexai
from vertexai.preview.generative_models import GenerativeModel, ChatSession
import re

# Load environment variables
API_KEY = os.getenv('API_KEY')
SEARCH_ENGINE_ID = os.getenv('SEARCH_ENGINE_ID')
PROJECT_ID = os.getenv('PROJECT_ID')
LOCATION = os.getenv('LOCATION')

# Initialize Vertex AI
vertexai.init(project=PROJECT_ID, location=LOCATION)
model = GenerativeModel("gemini-1.0-pro")
chat = model.start_chat()

app = Flask(__name__)

# Function to perform a Google Custom Search
def google_search(query):
    url = "https://www.googleapis.com/customsearch/v1"
    params = {
        "key": API_KEY,
        "cx": SEARCH_ENGINE_ID,
        "q": query,
        "num": 4
    }
    headers = {
        "User-Agent": "Mozilla/5.0"
    }
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        print(f"Error during API request: {e}")
        return ""

# Other functions and routes remain unchanged
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/summary', methods=['POST'])
def summary():
    name = request.form['name']
    if not name:
        return render_template('index.html', error="Please enter a valid name.")

    # Perform Google search and process the results
    html = google_search(name)
    if html:
        prompt = f"""
         Summarize the following search results about {name} into a concise paragraph and provide the image URL if available. Return the response strictly as a JSON object with the following structure:
        {{
            "summary": "A concise paragraph summarizing the person's details with at least 200 words. If the search results are not about a person, clearly state: 'The search results are not about a person.'",
            "image_url": "URL of the image, or an empty string if not available."
        }}
        Important Instructions:
            1.Carefully analyze the search results to determine if they pertain to a person. If they do not, explicitly state this in the summary field and avoid generating details unrelated to the input.
            2.Do not infer or assume information that is not present in the search results.
            3.Responses must strictly adhere to the JSON format.
            Search Results: {html}
        """
        chat_response = chat.send_message(prompt).text
        print(chat_response)
        response = chat_response.strip().replace('\n', ' ').replace('  ', ' ')
        match = re.search(r'\{.*\}', response, re.DOTALL)
        if match:
            json_string = match.group(0)

        try:
            # Parse the JSON response
            json_data = json.loads(json_string)
            summary = json_data.get("summary", "No summary available.")
            image_url = json_data.get("image_url", "")
            return render_template('summary.html', summary=summary, image_url=image_url)
        except json.JSONDecodeError as e:
            print(f"Error during JSON parsing: {e}")
            return render_template('index.html', error="Failed to parse the response from the LLM.")
    else:
        return render_template('index.html', error="No results found.")