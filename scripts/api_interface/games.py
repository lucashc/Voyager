import requests
from datetime import datetime


GAMES_URL = "https://sqlillo.dziban.net/api/private/games"

GAME_DATA_URL = "https://sqlillo.dziban.net/api/games-data/"


def get_past_games(token):
    r = requests.get(GAMES_URL, headers={"Authorization": f"Bearer {token}"})
    if not r.status_code == 200:
        raise ConnectionError("Get failed")
    games = r.json()
    for game in games:
        game["updated_at"] = datetime.strptime(
            game["updated_at"], "%Y-%m-%dT%H:%M:%S.%f%z"
        ).timestamp()
        game["created_at"] = datetime.strptime(
            game["created_at"], "%Y-%m-%dT%H:%M:%S.%f%z"
        ).timestamp()
    return games


def get_most_recent_games_after_time(token, timestamp):
    games = get_past_games(token)
    games_after_time = list(filter(lambda game: game["created_at"] > timestamp, games))
    return games_after_time


def fetch_game(token, game_id):
    url = GAME_DATA_URL + str(game_id)
    r = requests.get(url, headers={"Authorization": f"Bearer {token}"})
    if not r.status_code == 200:
        raise ConnectionError("Get failed")
    return r.json()
