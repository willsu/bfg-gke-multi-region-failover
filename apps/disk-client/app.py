import os
from flask import Flask, request, jsonify, render_template_string, redirect, url_for
import requests

app = Flask(__name__)

# NOTE: The DISK_WRITER_HOST environment variable is injected by Kubernetes.
# This variable should contain the hostname or IP address of the backend service.
# For example: "http://write-bytes-service:8080"
DISK_WRITER_HOST = os.getenv("DISK_WRITER_HOST")

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Disk Writer</title>
    <style>
        body { font-family: sans-serif; text-align: center; margin-top: 50px; }
        .container { width: 400px; margin: auto; padding: 20px; border: 1px solid #ccc; border-radius: 8px; }
        form { margin-top: 20px; }
        input[type="number"] { width: 80%; padding: 8px; margin: 10px 0; }
        input[type="submit"] { padding: 10px 20px; background-color: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; }
        .message { margin-top: 20px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Disk Writer</h1>
        <h3>Current Disk Usage: {{ current_size }} bytes ({{current_size_mb}} MB)</h3>
        <h3>Region: {{ region }} </h3>
        <h3>Hostname: {{ hostname }} </h3>

        <form action="{{ url_for('set_disk_usage') }}" method="post">
            <label for="num_bytes">Enter Number of Bytes:</label><br>
            <input type="number" id="num_bytes" name="num_bytes" value="0" min="0" required><br>
            <input type="submit" value="Set Disk Usage">
        </form>

        {% if message %}
            <p class="message">{{ message }}</p>
        {% endif %}
    </div>
</body>
</html>
"""

# --- get_disk_usage: Renders an HTML view at the root route ---
@app.route("/", methods=["GET"])
def get_disk_usage():
    """
    Forwards a GET request to the backend service to get the current disk usage and renders an HTML view.
    """
    if not DISK_WRITER_HOST:
        return jsonify(error="DISK_WRITER_HOST environment variable not set"), 500

    backend_url = f"http://{DISK_WRITER_HOST}/disk"
    try:
        response = requests.get(backend_url, timeout=10, stream=True)
        # Parse the JSON response from the backend to get the size
        data = response.json()
        current_size = data.get("current_disk_usage_bytes", 0)
        current_size_mb = round(current_size / (1024 * 1024), 2)
        region = data.get("region", "unknown region")
        hostname = data.get("hostname", "unknown host")
        return render_template_string(HTML_TEMPLATE, current_size=current_size, current_size_mb=current_size_mb, region=region, hostname=hostname)
    except requests.exceptions.RequestException as e:
        return jsonify(error=f"Backend GET request failed: {e}"), 500
    except Exception as e:
        return jsonify(error=f"Failed to parse backend response: {e}"), 500

# --- set_disk_usage: Now accepts form data and proxies to the backend ---
@app.route("/disk", methods=["POST"])
def set_disk_usage():
    """
    Forwards a POST request to the backend service to set the disk usage.
    Logs the backend response body and redirects to the root URL upon success.
    """
    if not DISK_WRITER_HOST:
        return jsonify(error="DISK_WRITER_HOST environment variable not set"), 500

    backend_url = f"http://{DISK_WRITER_HOST}/disk"

    # Get the form data, not JSON
    try:
        num_bytes = int(request.form.get("num_bytes", 0))
    except (ValueError, TypeError):
        return jsonify(error="Invalid value for num_bytes"), 400

    json_data = {"num_bytes": num_bytes}

    try:
        response = requests.post(backend_url, json=json_data)

        # Log the raw response body from the backend
        print("Backend POST response body:", response.text)

        # If the request was successful, redirect to the root URL
        if response.status_code == 200:
            return redirect(url_for('get_disk_usage'))
        else:
            return jsonify(error="Backend returned an error"), response.status_code

    except requests.exceptions.RequestException as e:
        return jsonify(error=f"Backend POST request failed: {e}"), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    app.run(host="0.0.0.0", port=port)

