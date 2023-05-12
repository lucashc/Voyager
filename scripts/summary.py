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
    print("## Summary Script")
    current_time = datetime.now()
    print(f"- [x] Current time is: {current_time}")
    timestamp = current_time.timestamp()

    token = login_and_get_token()
    print("- [x] Successfully logged in")
    print("- [x] Waiting for new games, ", end="")
    while not (game := check_recent_games(token, timestamp)):
        print(".", end="")
        time.sleep(WAIT_TIMEOUT.seconds)
    print()

    print(f"- [x] Found game: {game['id']}")
    game_data = fetch_game(token, game["id"])

    print()
    print("### Game Analysis")
    analyse_game(game_data)


if __name__ == "__main__":
    main()
