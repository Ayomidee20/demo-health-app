import os
import subprocess
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev-fallback-key")


def get_commit_sha():
    """Return the current git commit SHA, or fall back to env var."""
    sha = os.environ.get("COMMIT_SHA", None)
    if sha:
        return sha
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return "unknown"


@app.route("/healthcheck")
def healthcheck():
    return jsonify({
        "status": "healthy",
        "version": "1.0",
        "last_commit_sha": get_commit_sha(),
        "description": "Azure Container Apps CI/CD project by Ayomide Giwa"
    })


@app.route("/login")
def login():
    return render_template_string(LOGIN_PAGE)


@app.route("/")
def index():
    return render_template_string(INDEX_PAGE)


INDEX_PAGE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HealthApp — Azure DevOps + Terraform</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: #0f172a;
            color: #e2e8f0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .card {
            background: #1e293b;
            border: 1px solid #334155;
            border-radius: 12px;
            padding: 2.5rem;
            max-width: 480px;
            width: 90%;
            text-align: center;
        }
        .card h1 { font-size: 1.5rem; margin-bottom: 0.5rem; color: #38bdf8; }
        .card p { color: #94a3b8; line-height: 1.6; margin-bottom: 1.5rem; }
        .links { display: flex; gap: 1rem; justify-content: center; }
        .links a {
            display: inline-block;
            padding: 0.6rem 1.2rem;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 500;
            font-size: 0.9rem;
        }
        .links a.primary {
            background: #38bdf8;
            color: #0f172a;
        }
        .links a.secondary {
            border: 1px solid #475569;
            color: #cbd5e1;
        }
        .links a:hover { opacity: 0.85; }
        .badge {
            display: inline-block;
            margin-top: 1.5rem;
            padding: 0.3rem 0.8rem;
            background: #164e63;
            color: #67e8f9;
            border-radius: 999px;
            font-size: 0.75rem;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>HealthApp</h1>
        <p>
            A Python Flask app deployed on Azure Container Apps
            with Terraform and Azure DevOps CI/CD pipelines.
        </p>
        <div class="links">
            <a href="/healthcheck" class="primary">Healthcheck</a>
            <a href="/login" class="secondary">Login</a>
        </div>
        <span class="badge">Ayomide Giwa — DevOps Project</span>
    </div>
</body>
</html>
"""

LOGIN_PAGE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login — HealthApp</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: #0f172a;
            color: #e2e8f0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .card {
            background: #1e293b;
            border: 1px solid #334155;
            border-radius: 12px;
            padding: 2.5rem;
            max-width: 400px;
            width: 90%;
        }
        .card h2 { text-align: center; margin-bottom: 1.5rem; color: #38bdf8; }
        label {
            display: block; margin-bottom: 0.3rem;
            font-size: 0.85rem; color: #94a3b8;
        }
        input {
            width: 100%;
            padding: 0.6rem 0.8rem;
            margin-bottom: 1rem;
            border: 1px solid #475569;
            border-radius: 8px;
            background: #0f172a;
            color: #e2e8f0;
            font-size: 0.9rem;
        }
        input:focus { outline: none; border-color: #38bdf8; }
        button {
            width: 100%;
            padding: 0.7rem;
            background: #38bdf8;
            color: #0f172a;
            border: none;
            border-radius: 8px;
            font-size: 0.95rem;
            font-weight: 600;
            cursor: pointer;
        }
        button:hover { opacity: 0.85; }
        .back {
            display: block;
            text-align: center;
            margin-top: 1rem;
            color: #64748b;
            text-decoration: none;
            font-size: 0.85rem;
        }
        .back:hover { color: #94a3b8; }
    </style>
</head>
<body>
    <div class="card">
        <h2>Login</h2>
        <label for="username">Username</label>
        <input type="text" id="username" placeholder="Enter username">
        <label for="password">Password</label>
        <input type="password" id="password" placeholder="Enter password">
        <button type="button" onclick="alert('This is a demo app — no auth backend.')">
            Sign In
        </button>
        <a href="/" class="back">&larr; Back to home</a>
    </div>
</body>
</html>
"""


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 3000))
    # Must listen on all interfaces inside a container. Only used locally;
    # in the image gunicorn binds instead.
    app.run(host="0.0.0.0", port=port)  # nosec B104
