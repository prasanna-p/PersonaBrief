from flask import Flask, render_template, request
import requests
import os
import json
import vertexai
from vertexai.preview.generative_models import GenerativeModel, ChatSession

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

# Function to parse and extract summary and image URL
def parse_summary_and_image(response):
    """
    Extracts the summary and image URL from the response text.
    """
    try:
        # Example response format:
        # "## Name: Summary details... Image URL: https://image-url.com"
        if "Image URL:" in response:
            parts = response.split("Image URL:")
            summary = parts[0].strip()
            image_url = parts[1].strip()
            return summary, image_url
        else:
            return response, ""  # No image URL
    except Exception as e:
        print(f"Error parsing response: {e}")
        return response, ""

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
         Summarize the following search results about {name} into a concise paragraph and provide the image URL if available. Return the response as a JSON object with the following structure:
         
        {{
            "summary": "A concise paragraph summarizing the person's details atleast having 200 words.",
            "image_url": "URL of the image, or an empty string if not available."
        }}

        If the search results are not about a person, identify the subject and return a message indicating that the results are not about a person. 
        
        Search Results:
        {html}
        """
        chat_response = chat.send_message(prompt).text
        print(chat_response)
        cleaned_response = chat_response.strip().replace('\n', ' ').replace('  ', ' ')

        try:
            # Parse the JSON response
            response_data = json.loads(cleaned_response.lstrip("```json").rstrip("```"))
            print(response_data)
            summary = response_data.get("summary", "No summary available.")
            image_url = response_data.get("image_url", "")
            return render_template('summary.html', summary=summary, image_url=image_url)
        except json.JSONDecodeError:
            return render_template('index.html', error="Failed to parse the response from the LLM.")
    else:
        return render_template('index.html', error="No results found.")


if __name__ == "__main__":
    API_KEY = os.getenv('API_KEY')
    SEARCH_ENGINE_ID = os.getenv('SEARCH_ENGINE_ID')
    PROJECT_ID = os.getenv('PROJECT_ID')
    LOCATION = os.getenv('LOCATION')
    vertexai.init(project=PROJECT_ID, location=LOCATION)
    model = GenerativeModel("gemini-1.0-pro")
    chat = model.start_chat()

    app.run(debug=True)
