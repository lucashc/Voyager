def get_cod_moves(game):
    return list(filter(lambda x: x["ty"] == "cod", game))

def get_moves(game, username):
    return list(filter(lambda x: "username" in x and x["username"] == username, game))

def get_our_moves(game):
    return get_moves(game, "OutLauz")


def get_players(game):
    players = list(set(map(lambda x: x["username"] if x["ty"] == 0 else False, game)))
    players.remove(False)
    return players

def get_remaining_players(game, players):
    last_moves = [moves[-1] for moves in map(lambda x: get_moves(game, x), players)]
    healths = [move["h"] for move in last_moves]
    remaining_players = len(list(filter(lambda x: x > 0, healths)))
    return remaining_players


def distance(pos1, pos2):
    return ((pos1[0] - pos2[0]) ** 2 + (pos1[1] - pos2[1]) ** 2) ** 0.5


def bool_to_checkmark(b):
    return "✅" if b else "❌"

def get_death_index(health):
    for i, h in enumerate(health):
        if h <= 0:
            return i
    return -1


def analyse_game(game):
    players = get_players(game)
    our_moves = get_our_moves(game)
    health = list(map(lambda x: x["h"], our_moves))
    final_position = (our_moves[-1]["x"], our_moves[-1]["y"])

    remaining_players = get_remaining_players(game, players)

    cod_moves = get_cod_moves(game)
    final_cod_position = (cod_moves[-1]["x"], cod_moves[-1]["y"])
    final_cod_radius = cod_moves[-1]["r"]

    print("### Game Statistics")
    print()
    print("| # Moves | # Players | # Survivors |")
    print("| --- | --- | --- |")
    print(f"| {len(our_moves)} | {len(players)} | {remaining_players} |")
    print()

    if health[-1] > 0:
        print(f"* Survive? {bool_to_checkmark(True)}")
    else:
        print(f"* Survive? {bool_to_checkmark(False)} death at turn {get_death_index(health)}")

    print(f"* Our health at the end of the game: {health[-1]}")
    print(f"* Last COD radius was {cod_moves[-1]['r']}")
    print(f"* Distance to COD at end of game: {distance(final_position, final_cod_position):.2f}")
    print(f"* Inside COD at end of game: {bool_to_checkmark(distance(final_position, final_cod_position) < final_cod_radius)}")
