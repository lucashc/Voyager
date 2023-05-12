import requests
import json
import os


LOGIN_URL = "https://sqlillo.dziban.net/api/login"


def load_credentials():
    current_file = __file__
    base_path = os.path.dirname(current_file)
    credential_file = os.path.join(base_path, "credential.json")
    with open(credential_file, "r") as f:
        credential = json.load(f)
    return credential


def login_and_get_token():
    credential = load_credentials()
    r = requests.post(LOGIN_URL, json=credential)
    if not r.status_code == 200:
        raise ConnectionError("Login failed")
    return r.json()["token"]
