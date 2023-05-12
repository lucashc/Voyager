from datetime import datetime, timedelta
import time

from api_interface.login import login_and_get_token
from api_interface.games import get_most_recent_games_after_time, fetch_game
from api_interface.game_analysis import analyse_game

WAIT_TIMEOUT = timedelta(minutes=1)


def check_recent_games(token, timestamp):
    games = get_most_recent_games_after_time(token, timestamp)

    if len(games) == 0:
        return None
    else:
        return games[-1]


def main():
    current_time = datetime.now()
    print(f"Current time is: {current_time}")
    timestamp = current_time.timestamp()

    token = login_and_get_token()
    print("Successfully logged in")

    while not (game := check_recent_games(token, timestamp)):
        print(f"No new games found, waiting {WAIT_TIMEOUT} seconds")
        time.sleep(WAIT_TIMEOUT.seconds)

    print(f"Found game: {game['id']}")
    game_data = fetch_game(token, game["id"])

    analyse_game(game_data)


if __name__ == "__main__":
    main()
