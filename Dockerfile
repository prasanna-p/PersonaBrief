# Use an official Python runtime as a parent image
FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the application files to the container
COPY . /app

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port your Flask app runs on
EXPOSE 8000

# Run the application using Gunicorn
CMD ["gunicorn","-w", "4", "-b", "0.0.0.0:8000", "main:app"]

