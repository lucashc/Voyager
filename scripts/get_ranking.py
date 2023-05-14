from api_interface.login import login_and_get_token
from api_interface.rankings import get_ranking_pretty

N_GAMES = 20


def main():
    print("## Ranking")
    token = login_and_get_token()
    print("* Successfully logged in")
    get_ranking_pretty(token, N_GAMES, False)


if __name__ == "__main__":
    main()
