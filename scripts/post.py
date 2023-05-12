import argparse
from api_interface.login import login_and_get_token
from api_interface.post_code import post_code


def main(file_name):
    # Get token
    token = login_and_get_token()
    print("Successfully logged in")
    # Post code
    result = post_code(file_name, token)
    print("Successfully posted code")
    # Print result
    print(f"Posted code with id {result['id']} and user {result['username']}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("file_name", help="File name to post")
    args = parser.parse_args()
    main(args.file_name)
