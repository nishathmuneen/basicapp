"""Integration tests for My Health Tracker FastAPI + SQLite backend."""

from __future__ import annotations

import os
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.database import DEFAULT_PASSWORD, DEFAULT_USERNAME
from app.evaluation import (
    HIGH_BP_WARNING,
    HIGH_GLUCOSE_WARNING,
    LOW_GLUCOSE_WARNING,
    VERY_HIGH_BP_WARNING,
)
from app.main import app


def _login_default(test_client: TestClient) -> None:
    resp = test_client.post(
        "/api/auth/login",
        json={"username": DEFAULT_USERNAME, "password": DEFAULT_PASSWORD},
    )
    assert resp.status_code == 200


@pytest.fixture()
def client(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> TestClient:
    db_file = tmp_path / "test_health.db"
    monkeypatch.setenv("HEALTH_TRACKER_DB_PATH", str(db_file))
    with TestClient(app) as test_client:
        _login_default(test_client)
        yield test_client


def test_auth_protection_login_update_and_logout(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    db_file = tmp_path / "auth_health.db"
    monkeypatch.setenv("HEALTH_TRACKER_DB_PATH", str(db_file))

    with TestClient(app) as anon:
        for protected_path in (
            "/api/dashboard",
            "/api/readings",
            "/api/charts",
            "/api/thresholds",
            "/api/reminders",
        ):
            assert anon.get(protected_path).status_code == 401

        session_info = anon.get("/api/auth/session").json()
        assert session_info["authenticated"] is False
        assert session_info["show_default_hint"] is True
        assert session_info["default_username"] == DEFAULT_USERNAME
        assert session_info["default_password"] == DEFAULT_PASSWORD

        bad_login = anon.post(
            "/api/auth/login", json={"username": DEFAULT_USERNAME, "password": "wrong"}
        )
        assert bad_login.status_code == 401

        good_login = anon.post(
            "/api/auth/login",
            json={"username": f"  {DEFAULT_USERNAME.upper()} ", "password": DEFAULT_PASSWORD},
        )
        assert good_login.status_code == 200
        assert good_login.json()["authenticated"] is True
        assert good_login.json()["is_default_password"] is True

        # Wrong current password rejected on update
        bad_update = anon.put(
            "/api/auth/credentials",
            json={
                "current_password": "wrong",
                "username": "alex",
                "display_name": "Alex",
                "new_password": "newpass123",
            },
        )
        assert bad_update.status_code == 400

        # Valid credential update persists and hides default hint
        good_update = anon.put(
            "/api/auth/credentials",
            json={
                "current_password": DEFAULT_PASSWORD,
                "username": "alex",
                "display_name": "Alex",
                "new_password": "newpass123",
            },
        )
        assert good_update.status_code == 200
        assert good_update.json()["username"] == "alex"
        assert good_update.json()["display_name"] == "Alex"
        assert good_update.json()["is_default_password"] is False

        assert anon.get("/api/dashboard").json()["display_name"] == "Alex"

        logout_resp = anon.post("/api/auth/logout")
        assert logout_resp.status_code == 200
        assert anon.get("/api/dashboard").status_code == 401

        after_logout = anon.get("/api/auth/session").json()
        assert after_logout["authenticated"] is False
        assert after_logout["show_default_hint"] is False
        assert after_logout["default_password"] is None

    # Fresh client against same SQLite DB enforces new credentials
    with TestClient(app) as client2:
        assert (
            client2.post(
                "/api/auth/login",
                json={"username": DEFAULT_USERNAME, "password": DEFAULT_PASSWORD},
            ).status_code
            == 401
        )
        assert (
            client2.post(
                "/api/auth/login", json={"username": "alex", "password": "newpass123"}
            ).status_code
            == 200
        )

    # Bearer token flow (used by Flutter mobile/desktop clients)
    with TestClient(app) as mobile_client:
        login_resp = mobile_client.post(
            "/api/auth/login", json={"username": "alex", "password": "newpass123"}
        )
        token = login_resp.json()["access_token"]
        assert token
        mobile_client.cookies.clear()
        headers = {"Authorization": f"Bearer {token}"}
        assert mobile_client.get("/api/dashboard", headers=headers).status_code == 200
        assert mobile_client.post("/api/auth/logout", headers=headers).status_code == 200
        assert mobile_client.get("/api/dashboard", headers=headers).status_code == 401


def test_dashboard_empty_and_default_reminders(client: TestClient) -> None:
    resp = client.get("/api/dashboard", params={"local_now": "2026-11-11T07:00"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["health_status"] == "No Readings Yet"
    assert data["latest_glucose"] is None
    assert data["latest_bp"] is None
    assert data["latest_heart_rate"] is None

    rem_resp = client.get("/api/reminders")
    assert rem_resp.status_code == 200
    titles = [item["title"] for item in rem_resp.json()]
    assert "Morning glucose check" in titles
    assert "Evening glucose check" in titles
    assert "BP measurement" in titles


def test_glucose_evaluation_and_warnings(client: TestClient) -> None:
    # Normal fasting reading
    normal_resp = client.post(
        "/api/readings/glucose",
        json={
            "glucose_value": 105,
            "glucose_type": "Fasting",
            "recorded_at": "2026-11-11T08:00",
        },
    )
    assert normal_resp.status_code == 201
    assert normal_resp.json()["evaluation"]["color"] == "green"
    assert normal_resp.json()["evaluation"]["within_target"] is True

    # High glucose reading
    high_resp = client.post(
        "/api/readings/glucose",
        json={
            "glucose_value": 195,
            "glucose_type": "After Meal",
            "recorded_at": "2026-11-11T10:30",
        },
    )
    assert high_resp.status_code == 201
    high_eval = high_resp.json()["evaluation"]
    assert high_eval["color"] == "yellow"
    assert high_eval["within_target"] is False
    assert high_eval["warning_message"] == HIGH_GLUCOSE_WARNING

    # Low glucose reading
    low_resp = client.post(
        "/api/readings/glucose",
        json={
            "glucose_value": 62,
            "glucose_type": "Before Meal",
            "recorded_at": "2026-11-11T12:00",
        },
    )
    assert low_resp.status_code == 201
    low_eval = low_resp.json()["evaluation"]
    assert low_eval["color"] == "red"
    assert low_eval["status_label"] == "Urgent"
    assert low_eval["warning_message"] == LOW_GLUCOSE_WARNING

    # Latest reading is low glucose (Urgent) -> Dashboard health_status = Critical
    dash = client.get("/api/dashboard").json()
    assert dash["health_status"] == "Critical"
    assert dash["latest_glucose"]["glucose_value"] == 62
    assert dash["last_recorded_at"] == "2026-11-11T12:00"


def test_bp_evaluation_warnings_and_optional_hr(client: TestClient) -> None:
    # Normal BP without HR
    normal_bp = client.post(
        "/api/readings/bp",
        json={"systolic": 118, "diastolic": 76, "recorded_at": "2026-11-11T09:00"},
    )
    assert normal_bp.status_code == 201
    assert normal_bp.json()["evaluation"]["color"] == "green"
    assert normal_bp.json()["heart_rate"] is None

    # Elevated BP (Attention / Yellow)
    high_bp = client.post(
        "/api/readings/bp",
        json={
            "systolic": 144,
            "diastolic": 92,
            "heart_rate": 74,
            "recorded_at": "2026-11-11T11:00",
        },
    )
    assert high_bp.status_code == 201
    high_eval = high_bp.json()["evaluation"]
    assert high_eval["color"] == "yellow"
    assert high_eval["warning_message"] == HIGH_BP_WARNING

    dash_warn = client.get("/api/dashboard").json()
    assert dash_warn["health_status"] == "Warning"
    assert dash_warn["latest_heart_rate"] == 74

    # Severely elevated BP (Urgent / Red)
    very_high_bp = client.post(
        "/api/readings/bp",
        json={
            "systolic": 184,
            "diastolic": 112,
            "heart_rate": 88,
            "recorded_at": "2026-11-11T12:15",
        },
    )
    assert very_high_bp.status_code == 201
    very_high_eval = very_high_bp.json()["evaluation"]
    assert very_high_eval["color"] == "red"
    assert very_high_eval["warning_message"] == VERY_HIGH_BP_WARNING

    # Invalid BP where systolic <= diastolic
    bad_bp = client.post(
        "/api/readings/bp",
        json={"systolic": 80, "diastolic": 90, "recorded_at": "2026-11-11T12:20"},
    )
    assert bad_bp.status_code == 422


def test_history_filtering_charts_and_persistence(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    db_file = tmp_path / "persist.db"
    monkeypatch.setenv("HEALTH_TRACKER_DB_PATH", str(db_file))

    with TestClient(app) as client1:
        _login_default(client1)
        client1.post(
            "/api/readings/glucose",
            json={"glucose_value": 140, "glucose_type": "Fasting", "recorded_at": "2026-10-20T08:00"},
        )
        client1.post(
            "/api/readings/glucose",
            json={"glucose_value": 120, "glucose_type": "Fasting", "recorded_at": "2026-11-08T08:00"},
        )
        client1.post(
            "/api/readings/glucose",
            json={"glucose_value": 100, "glucose_type": "Fasting", "recorded_at": "2026-11-11T08:00"},
        )
        client1.put(
            "/api/reminders/morning_glucose",
            json={"time_of_day": "07:30", "enabled": False, "note": "Updated note"},
        )

    # Simulate fresh app instance / restart pointing to the same SQLite DB
    with TestClient(app) as client2:
        _login_default(client2)
        daily = client2.get(
            "/api/readings", params={"period": "daily", "reference_date": "2026-11-11"}
        ).json()
        assert len(daily) == 1
        assert daily[0]["glucose_value"] == 100

        weekly = client2.get(
            "/api/readings", params={"period": "weekly", "reference_date": "2026-11-11"}
        ).json()
        assert len(weekly) == 2

        monthly = client2.get(
            "/api/readings", params={"period": "monthly", "reference_date": "2026-11-11"}
        ).json()
        assert len(monthly) == 3

        charts = client2.get(
            "/api/charts", params={"period": "monthly", "reference_date": "2026-11-11"}
        ).json()
        assert charts["glucose_trend"]["direction"] == "decreasing"

        reminders = {r["key"]: r for r in client2.get("/api/reminders").json()}
        assert reminders["morning_glucose"]["time_of_day"] == "07:30"
        assert reminders["morning_glucose"]["enabled"] is False


def test_configurable_thresholds_and_reset(client: TestClient) -> None:
    current = client.get("/api/thresholds").json()
    current["glucose_fasting_max"] = 110
    updated = client.put("/api/thresholds", json=current)
    assert updated.status_code == 200
    assert updated.json()["glucose_fasting_max"] == 110

    reading = client.post(
        "/api/readings/glucose",
        json={"glucose_value": 120, "glucose_type": "Fasting", "recorded_at": "2026-11-11T08:00"},
    ).json()
    assert reading["evaluation"]["within_target"] is False
    assert reading["evaluation"]["color"] == "yellow"

    reset = client.post("/api/thresholds/reset")
    assert reset.status_code == 200
    assert reset.json()["glucose_fasting_max"] == 130

    readings = client.get("/api/readings", params={"period": "all"}).json()
    assert readings[0]["evaluation"]["within_target"] is True
    assert readings[0]["evaluation"]["color"] == "green"


def test_delete_reading_and_due_reminders_and_spa(client: TestClient) -> None:
    # At 09:30 with no logs, all morning_glucose (08:00) and bp_measurement (09:00) are due
    dash_before = client.get("/api/dashboard", params={"local_now": "2026-11-11T09:30"}).json()
    due_keys = {item["key"] for item in dash_before["due_reminders"]}
    assert due_keys == {"morning_glucose", "bp_measurement"}

    created = client.post(
        "/api/readings/bp",
        json={
            "systolic": 116,
            "diastolic": 74,
            "heart_rate": 115,
            "recorded_at": "2026-11-11T09:31",
        },
    )
    assert created.status_code == 201
    created_data = created.json()
    assert created_data["evaluation"]["color"] == "yellow"

    # After logging BP, bp_measurement is no longer due
    dash_after_bp = client.get("/api/dashboard", params={"local_now": "2026-11-11T09:32"}).json()
    assert {item["key"] for item in dash_after_bp["due_reminders"]} == {"morning_glucose"}

    # Delete reading and confirm 404 on second delete
    del_resp = client.delete(f"/api/readings/{created_data['id']}")
    assert del_resp.status_code == 204
    missing_resp = client.delete(f"/api/readings/{created_data['id']}")
    assert missing_resp.status_code == 404

    # Built SPA should be served at /
    index_resp = client.get("/")
    assert index_resp.status_code == 200
    assert "My Health Tracker" in index_resp.text
