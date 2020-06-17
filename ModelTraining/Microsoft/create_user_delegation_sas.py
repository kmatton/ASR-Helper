import argparse
import requests


def request_user_delegation_key(storage_account_name: str):
    api_endpoint = "https://{}.blob.core.windows.net/?restype=service&comp=userdelegationkey".format(storage_account_name)
    headers=dict(
        Authorization=

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--storage_account_name', type=str, help='name of storage account to get user delegation key for')
    args = parser.parse_args()
    return args


def main():
    args = parse_args()



if __name__ == "__main__":
    main() 
