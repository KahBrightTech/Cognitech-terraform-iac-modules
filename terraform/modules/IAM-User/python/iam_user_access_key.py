#!/usr/bin/env python3
import boto3
import json
import sys

def get_existing_access_keys(username):
    """Retrieve all active access keys for the user."""
    iam = boto3.client('iam')
    response = iam.list_access_keys(UserName=username)
    return [key for key in response['AccessKeyMetadata'] if key['Status'] == 'Active']

def create_iam_access_key(username):
    iam = boto3.client('iam')

    # Check for existing active access keys
    existing_keys = get_existing_access_keys(username)
    
    if existing_keys:
        # Return existing key info (no SecretAccessKey available)
        first_key = existing_keys[0]
        return {
            "access_key_id": first_key['AccessKeyId'],
            "secret_access_key": "",  # Cannot be retrieved
            "exists": "true"
        }
    else:
        # Create a new access key
        response = iam.create_access_key(UserName=username)
        access_key = response["AccessKey"]
        return {
            "access_key_id": access_key["AccessKeyId"],
            "secret_access_key": access_key["SecretAccessKey"],
            "exists": "false"
        }

def main():
    try:
        input_data = json.load(sys.stdin)
        username = input_data.get("username")

        if not username:
            print(json.dumps({"error": "Missing 'username' input"}))
            sys.exit(1)

        result = create_iam_access_key(username)
        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()
