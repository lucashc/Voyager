import requests
import json
import os
import argparse

LOGIN_URL = "https://sqlillo.dziban.net/api/login"

CODE_URL = "https://sqlillo.dziban.net/api/private/codes"


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
    else:
        print("Successfully logged in")
    return r.json()["token"]


def post_code(file_name, token):
    with open(file_name, "r") as f:
        code = f.read()
    r = requests.post(
        CODE_URL, json={"code": code}, headers={"Authorization": f"Bearer {token}"}
    )
    if not r.status_code == 200:
        raise ConnectionError("Post failed")
    else:
        print("Successfully posted code")
    return r.json()


def main(file_name):
    # Get token
    token = login_and_get_token()
    # Post code
    result = post_code(file_name, token)
    # Print result
    print(f"Posted code with id {result['id']} and user {result['username']}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("file_name", help="File name to post")
    args = parser.parse_args()
    main(args.file_name)
