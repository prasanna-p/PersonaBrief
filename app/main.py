from flask import Flask, render_template, request
import requests
import os
import json
import vertexai
from vertexai.preview.generative_models import GenerativeModel, ChatSession
import re
from requests.exceptions import RequestException, Timeout
from datetime import datetime

# Load environment variables
API_KEY = os.getenv('API_KEY')
SEARCH_ENGINE_ID = os.getenv('SEARCH_ENGINE_ID')
PROJECT_ID = os.getenv('PROJECT_ID')
LOCATION = os.getenv('LOCATION')

# Initialize Vertex AI
vertexai.init(project=PROJECT_ID, location=LOCATION)
model = GenerativeModel("gemini-1.5-pro")
chat = model.start_chat()

app = Flask(__name__)

# Function to perform a Google Custom Search
def google_search(query):
    result_count = 3
    url = "https://www.googleapis.com/customsearch/v1"
    params = {
        "key": API_KEY,
        "cx": SEARCH_ENGINE_ID,
        "q": query,
        "num": result_count,
    }
    headers = {
        "User-Agent": "Mozilla/5.0"
    }
    try:
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        result = response.json()

        snippets = recursive_extract(result, 'snippet')
        og_images = recursive_extract(result, 'og:image')

        llm_input = {
            "snippet": " ".join(snippets),
            "image_urls": og_images
        }

        return json.dumps(llm_input, indent=2)

    except (Timeout, RequestException) as e:
        return json.dumps({"error": f"API request failed: {e}"}, indent=2)


# Function to recursively extract values from a JSON object
def recursive_extract(json_obj, key):
    results = []
    if isinstance(json_obj, dict):
        for k, v in json_obj.items():
            if k == key:
                results.append(v)
            elif isinstance(v, (dict, list)):
                results.extend(recursive_extract(v, key))
    elif isinstance(json_obj, list):
        for item in json_obj:
            results.extend(recursive_extract(item, key))
    return results

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
    # input = f"search about a person named {name}"
    html = google_search(name)
    with open("search_results.json", 'w', encoding='utf-8') as file:
            file.write(html)
    if html:
        prompt = f"""
         Summarize the following search results about {name} into a concise paragraph and provide the image URL if available. Return the response strictly as a JSON object with the following structure:
        {{
            "summary": "A concise paragraph summarizing the person's details with not more than 200 words. If the search results are not about a person, clearly state: 'The search results are not about a person.'",
            "image_url": "URL of the image, or an empty string if not available. Ensure the URL is publicly accessible. and preferably in JPEG or PNG format. If URL is not identifiable return first iterm in the image_urls list."
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