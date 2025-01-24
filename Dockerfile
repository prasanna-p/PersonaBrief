# Use an official Python runtime as a parent image
FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the application files to the container
COPY . /app

# Install required packages, create a non-root user, adjust permissions, and install Python dependencies in one RUN instruction
RUN apt-get update && apt-get install -y --no-install-recommends \
    passwd && \
    groupadd -r appuser && useradd -r -g appuser appuser && \
    chown -R appuser:appuser /app && \
    pip install --default-timeout=100 --no-cache-dir -r requirements.txt && \
    rm -rf /var/lib/apt/lists/*

# Switch to the non-root user
USER appuser

# Expose the port your Flask app runs on
EXPOSE 8000

# Run the application using Gunicorn
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "main:app"]


