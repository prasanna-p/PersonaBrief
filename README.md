# 🌐 Project Overview

PersonaBrief is a web application that allows users to enter a person's name and receive a summarized profile of the individual. It uses Google Custom Search to find information, scrapes relevant data, and summarizes the content using the Gemini 1.5 Pro LLM.


## 🚀 Features

- Automated Data Retrieval: Uses Google Custom Search to gather information.
- AI-Powered Summarization: Leverages Gemini 1.5 Pro for generating concise summaries.
- Simple Local Setup: Easily run the application locally with minimal configuration.
- Customizable Search Domains: Allows users to customize search domains via environment variables.
- Responsive Frontend: Simple, intuitive interface with responsive design.


## 🛠️ Tech Stack
- Frontend: HTML, CSS
- Backend: Python (Flask) with Gunicorn
- AI/ML: Gemini 1.5 Pro LLM
- Cloud APIs: Google Custom Search, Vertex AI

## ⚙️ Local Setup Instructions

### 🔑 Environment Setup
1. Clone the Repository:
```
git clone https://github.com/your-username/personabrief.git
cd personabrief
```
2. Create a .env file in the root directory with the following variables:
```
API_KEY=<your_api_key>
SEARCH_ENGINE_ID=<your_search_engine_id>
PROJECT_ID=<your_project_id>
LOCATION_ID=<your_location_id>
GOOGLE_APPLICATION_CREDENTIALS=path/to/.config/gcloud/application_default_credentials.json
```
- API_KEY: Generate from GCP with access to Custom Search API.
- SEARCH_ENGINE_ID: Retrieve from the Programmable Search Engine settings.
- PROJECT_ID: Your GCP project ID.
- LOCATION_ID: The GCP region where your Docker image is stored.


### 🌐 Setting Up GOOGLE_APPLICATION_CREDENTIALS
To set up GOOGLE_APPLICATION_CREDENTIALS, follow these steps:

1. Authenticate with Google Cloud:
```
gcloud auth application-default login
```
2. Locate the credentials file, usually found here:
```
~/.config/gcloud/application_default_credentials.json
```
3. Update the .env file with the path to this file:
```
GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/application_default_credentials.json
```
4. Create a Python Virtual Environment:
```
python3.12 -m venv python312
source python312/bin/activate
pip install -r requirements.txt
```


5. Run the Application Locally:
```
gunicorn -w 4 -b 0.0.0.0:8000 main:app
```
6. Access the Application:
```
Open a web browser and visit: http://localhost:8000
```

### 🌐 [Programmable Search Engine](https://programmablesearchengine.google.com/controlpanel/all) Configuration
Ensure the following URLs are added to the Programmable Search Engine API settings:

```
https://en.wikipedia.org
https://www.facebook.com
https://www.instagram.com
https://www.youtube.com
https://en.wikipedia.org
```

## 🚧 Prerequisites

- [Google Cloud SDK installed](https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe)
- Python 3.12 installed
- [Cloud account](https://console.cloud.google.com/) with billing enabled
- enable [Vertex AI API](https://console.cloud.google.com/marketplace/product/google/aiplatform.googleapis.com)
- enable [Custom Search API](https://console.cloud.google.com/marketplace/product/google/customsearch.googleapis.com)


## 🖥️ Usage Guide

- Open the application.
- Enter the name of the person you want to search.
- Click "Search".
- View the summarized profile generated by Gemini 1.5 Pro.


## 🔐 Security Considerations

- Environment Variables: Ensure the .env file is excluded from version control.
- API Key Management: Regularly rotate API keys for security.


## 🚧 Future Improvements

- Observing application latency throgh monitoring tools and implementing caching to reduce the latency.


## 🤝 Contributing

- Contributions are welcome! Feel free to open an issue or submit a pull request.


## 📜 License

- GNU License
