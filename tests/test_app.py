import json
import pytest
from app.app import app, get_commit_sha


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_healthcheck_returns_200(client):
    resp = client.get("/healthcheck")
    assert resp.status_code == 200


def test_healthcheck_json_fields(client):
    resp = client.get("/healthcheck")
    data = json.loads(resp.data)
    assert "status" in data
    assert data["status"] == "healthy"
    assert "version" in data
    assert "last_commit_sha" in data
    assert "description" in data


def test_healthcheck_content_type(client):
    resp = client.get("/healthcheck")
    assert resp.content_type == "application/json"


def test_index_returns_200(client):
    resp = client.get("/")
    assert resp.status_code == 200


def test_index_contains_app_name(client):
    resp = client.get("/")
    assert b"HealthApp" in resp.data


def test_login_returns_200(client):
    resp = client.get("/login")
    assert resp.status_code == 200


def test_login_contains_form_fields(client):
    resp = client.get("/login")
    assert b"username" in resp.data
    assert b"password" in resp.data


def test_undefined_route_returns_404(client):
    resp = client.get("/nonexistent")
    assert resp.status_code == 404


def test_commit_sha_from_env(monkeypatch):
    monkeypatch.setenv("COMMIT_SHA", "abc123test")
    assert get_commit_sha() == "abc123test"


def test_commit_sha_fallback(monkeypatch):
    monkeypatch.delenv("COMMIT_SHA", raising=False)
    sha = get_commit_sha()
    # Should return either a real SHA or "unknown", never empty
    assert len(sha) > 0
