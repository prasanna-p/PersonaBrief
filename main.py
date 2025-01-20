from flask import Flask, request, jsonify, render_template
import os
import json
import requests
import vertexai
from vertexai.preview.generative_models import GenerativeModel, ChatSession

app = Flask(__name__)

# Initialize Vertex AI
API_KEY = os.getenv('API_KEY')
SEARCH_ENGINE_ID = os.getenv('SEARCH_ENGINE_ID')
PROJECT_ID = os.getenv('PROJECT_ID')
LOCATION = os.getenv('LOCATION')

if API_KEY and SEARCH_ENGINE_ID and PROJECT_ID and LOCATION:
    vertexai.init(project=PROJECT_ID, location=LOCATION)
    model = GenerativeModel("gemini-1.0-pro")
    chat = model.start_chat()
else:
    raise EnvironmentError("Missing required environment variables.")

# Google Search Function
def google_search(query):
    url = "https://www.googleapis.com/customsearch/v1"
    params = {
        "key": API_KEY,
        "cx": SEARCH_ENGINE_ID,
        "q": query,
        "num": 5
    }
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        return {"error": f"Error during API request: {e}"}

# Parse Results Function
def parse_results(json_string):
    try:
        json_data = json.loads(json_string)
        items = json_data.get("items", [])
        filtered_data = [
            {
                "title": item.get("title"),
                "snippet": item.get("snippet"),
                "link": item.get("link"),
                "hcard": item.get("pagemap", {})
            }
            for item in items
        ]
        return filtered_data
    except json.JSONDecodeError:
        return {"error": "Error decoding JSON"}

# Chat Response Function
def get_chat_response(chat, prompt):
    response = chat.send_message(prompt)
    return response.text

@app.route('/')
def index():
    return render_template('index.html')

# Flask Route for Search
@app.route('/search', methods=['POST'])
def search():
    data = request.json
    query = data.get('query')
    if not query:
        return jsonify({"error": "Query parameter is missing"}), 400

    html = google_search(query)
    if "error" in html:
        return jsonify(html), 500

    results = parse_results(html)
    if "error" in results:
        return jsonify(results), 500

    prompt = f"""
    Summarize the following search results about {query} into a concise paragraph. Focus on key details such as the person's roles, achievements, affiliations, and any notable aspects from the provided links. Ensure the summary is coherent and avoids redundancy.

    {results}

    1. Limit the summary to 100 words.
    2. If the results mention more than one person, prioritize the topmost result.
    3. If the query does not pertain to a person, explicitly mention that in the summary.
    4. Give invalid response if search is not about any person.
    5. also capture image url of the person and provide it in the response.
    """
    summary = get_chat_response(chat, prompt)
    print(summary)
    return jsonify({"query": query, "results": results, "summary": summary})

# Run the Flask App
if __name__ == '__main__':
    app.run(debug=True)
