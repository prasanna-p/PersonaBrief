from flask import Flask, render_template, request
import requests
import os
import json
import vertexai
from vertexai.preview.generative_models import GenerativeModel, ChatSession
import re
from requests.exceptions import RequestException, Timeout

# Load environment variables
API_KEY = os.getenv('API_KEY')
SEARCH_ENGINE_ID = os.getenv('SEARCH_ENGINE_ID')
PROJECT_ID = os.getenv('PROJECT_ID')
LOCATION = os.getenv('LOCATION')

# Initialize Vertex AI
vertexai.init(project=PROJECT_ID, location=LOCATION)
model = GenerativeModel("gemini-2.5-pro")
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
    html = google_search(name)
    print(html)
    if html:
        prompt = f"""
        Summarize the following search results about {name} into a concise paragraph and provide the image URL if available. Return the response strictly as a JSON object with the following structure:
        {{
            "summary": "A concise paragraph summarizing the person's details with not more than 200 words. If the search results are not about a person, clearly state: 'The search results are not about a person.'",
            "image_url": "The most accurate URL of the image, or an empty string if not available. Ensure the URL is publicly accessible, directly points to an image (JPEG or PNG preferred), and does not lead to placeholders or broken links."
        }}

        **Enhanced Image Selection Rules:**
        1. **Prioritize URLs** containing keywords like `profile_images`, `avatar`, `headshot`, `official`, or the person's name.
        2. Select images hosted on trusted platforms (e.g. wikipedia, Twitter, LinkedIn, Instagram) when available.
        3. Ensure the image ends with `.jpg`, `.jpeg`, or `.png`, avoiding low-res thumbnails or placeholders.
        4. If multiple valid images exist, **choose the one most likely to represent the person** (e.g., profile pictures over random photos).
        5. If no valid image can be confirmed, **use the first entry** from the image_urls list.
        6. Responses must strictly adhere to the JSON format.

        Search Results: {html}
        """


        chat_response = chat.send_message(prompt).text
        response = chat_response.strip().replace('\n', ' ').replace('  ', ' ')
        print(response)
        try:
            # 🔍 Extract "summary" and "image_url" using regex
            summary = re.search(r'"summary"\s*:\s*"((?:[^"\\]|\\.)*)"', response)
            image_url = re.search(r'"image_url"\s*:\s*"([^"]+)"', response)

            # ✅ Extracted values or default messages
            summary = summary.group(1).replace('\\"', '"') if summary else "No summary available."
            image_url = image_url.group(1) if image_url else ""

            # 🔧 Build clean JSON
            json_data = {
                "summary": summary,
                "image_url": image_url
            }

            # Pretty print the result
            print(json.dumps(json_data, indent=4))

            summary = json_data.get("summary")
            image_url = json_data.get("image_url")
            return render_template('summary.html', summary=summary, image_url=image_url)
        except json.JSONDecodeError as e:
            # Handle JSON parsing errors
            print(f"Error during JSON parsing: {e}")
            return render_template('index.html', error="Failed to parse the response from the LLM.")
        except Exception as e:
            # Handle cases where json_string is empty or invalid
            print(f"Unexpected error: {e}")
            return render_template('index.html', error="An unexpected error occurred.")
        


