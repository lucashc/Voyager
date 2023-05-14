from api_interface.games import get_past_games, fetch_game
from api_interface.game_analysis import get_players, get_moves, bool_to_checkmark
from concurrent.futures import ThreadPoolExecutor
from collections import defaultdict


def get_ranking_pretty(token, N_GAMES, progress_disable=True):
    game_objs = get_past_games(token)[:N_GAMES]
    print(f"* Retrieved {N_GAMES} game IDs")

    games = []
    print("* Downloading games...")
    with ThreadPoolExecutor(max_workers=10) as executor:
        for game in executor.map(
            lambda game_obj: fetch_game(token, game_obj["id"]), game_objs
        ):
            games.append(game)
    print()
    print("* Downloaded all games")

    print("* Getting rankings...")
    rankings = defaultdict(lambda: 0)
    for game in games:
        players = get_players(game)
        for player in players:
            moves = get_moves(game, player)
            health = moves[-1]["h"]
            won = health > 0
            rankings[player] += won
    sorted_rankings = {
        k: v / N_GAMES
        for k, v in sorted(rankings.items(), key=lambda item: item[1], reverse=True)
    }
    print(f"* Obtained rankings over {N_GAMES}:")
    print()
    print(f"### Ranking with scores")
    print()
    we_are_first = False
    for index, (player, ranking) in enumerate(sorted_rankings.items()):
        if index == 0 and player == "OutLauz":
            we_are_first = True
        if index >= 10:
            break
        print(f"{index+1}. {player}: {ranking*100:.1f}% wins")
    print()
    print(f"**Are we first? 🤔: {bool_to_checkmark(we_are_first)}**")
    print()
