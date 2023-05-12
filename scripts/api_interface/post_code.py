import requests

CODE_URL = "https://sqlillo.dziban.net/api/private/codes"


def post_code(file_name, token):
    with open(file_name, "r") as f:
        code = f.read()
    r = requests.post(
        CODE_URL, json={"code": code}, headers={"Authorization": f"Bearer {token}"}
    )
    if not r.status_code == 200:
        raise ConnectionError("Post failed")
    return r.json()
