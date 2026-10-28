import os
from flask import Flask, jsonify, render_template

app = Flask(__name__)

# These values come from environment variables.
# On Azure, Terraform sets them in the Web App settings.
APP_ENV = os.environ.get("APP_ENV", "development")
APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")


@app.route("/")
def home():
    return render_template("index.html", env=APP_ENV, version=APP_VERSION)


@app.route("/health")
def health():
    # Jenkins calls this URL after deployment to check the app is alive.
    return jsonify(status="ok", environment=APP_ENV, version=APP_VERSION), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
