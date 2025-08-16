import os
import google.auth
from google.cloud import run_v2
from flask import Flask, request

# Initialize Flask App
app = Flask(__name__)

# Get environment variables
PROJECT_ID = os.environ.get("PROJECT_ID")
JOB_REGION = os.environ.get("JOB_REGION")
JOB_NAME = os.environ.get("JOB_NAME")

@app.route("/", methods=["POST"])
def run_job_handler():
    """Receives an HTTP POST request and triggers a Cloud Run Job."""
    if not all([PROJECT_ID, JOB_REGION, JOB_NAME]):
        return "Server is not configured with required environment variables.", 500

    print(f"Received request. Triggering job: {JOB_NAME} in region {JOB_REGION}")

    try:
        # Initialize the Cloud Run client inside the handler
        run_client = run_v2.JobsClient()

        # Construct the full job name path required by the API
        job_path = f"projects/{PROJECT_ID}/locations/{JOB_REGION}/jobs/{JOB_NAME}"

        # Make the API call to run the job
        operation = run_client.run_job(name=job_path)

        print(f"Successfully started job. Operation: {operation.metadata.name}")

        # Return a success message
        return f"Successfully triggered job '{JOB_NAME}'.", 202

    except Exception as e:
        print(f"Error triggering job: {e}")
        return f"An error occurred while triggering the job: {e}", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
