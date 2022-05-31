import os
import json
import boto3
import base64
from ipaddress import ip_network, ip_address
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    # Get the required parameters
    required_param_list = ["serverId", "username", "protocol", "sourceIp"]
    for parameter in required_param_list:
        if parameter not in event:
            print("Incoming " + parameter + " missing - Unexpected")
            return {}

    input_serverId = event["serverId"]
    input_username = event["username"]
    input_protocol = event["protocol"]
    input_sourceIp = event["sourceIp"]
    input_password = event.get("password", "")

    print("ServerId: {}, Username: {}, Protocol: {}, SourceIp: {}"
          .format(input_serverId, input_username, input_protocol, input_sourceIp))

    # Check for password and set authentication type appropriately. No password means SSH auth
    print("Start User Authentication Flow")
    if input_password != "":
        print("Using PASSWORD authentication")
        authentication_type = "PASSWORD"
    else:
        print("Using SSH authentication")
        authentication_type = "SSH"

    # Retrieve our user details from the secret. For all key-value pairs stored in SecretManager,
    # checking the protocol-specified secret first, then use generic ones.
    # e.g. If SFTPPassword and Password both exists, will be using SFTPPassword for authentication
    if os.environ["EnabledSecretStore"] == "ssm":
        secret = get_secret(
            os.environ["ParameterStorePathPrefix"] + input_serverId + "/" + input_username, os.environ["EnabledSecretStore"])
    elif os.environ["EnabledSecretStore"] == "secretsmanager":
        secret = get_secret(
            input_serverId + "/" + input_username, os.environ["EnabledSecretStore"])

    if secret is not None:
        secret_dict = json.loads(secret)
        # Run our password checks
        user_authenticated = authenticate_user(
            authentication_type, secret_dict, input_password, input_protocol)
        # Run sourceIp checks
        ip_match = check_ipaddress(secret_dict, input_sourceIp, input_protocol)

        if user_authenticated and ip_match:
            print("User authenticated, calling build_response with: " +
                  authentication_type)
            return build_response(secret_dict, authentication_type, input_protocol, input_username)
        else:
            print("User failed authentication return empty response")
            return {}
    else:
        # Otherwise something went wrong. Most likely the object name is not there
        print("Secrets Manager exception thrown - Returning empty response")
        # Return an empty data response meaning the user was not authenticated
        return {}


def lookup(secret_dict, key, input_protocol):
    if input_protocol + key in secret_dict:
        print("Found protocol-specified {}".format(key))
        return secret_dict[input_protocol + key]
    else:
        return secret_dict.get(key, None)


def check_ipaddress(secret_dict, input_sourceIp, input_protocol):
    accepted_ip_network = lookup(
        secret_dict, "AcceptedIpNetwork", input_protocol)
    if not accepted_ip_network:
        # No IP provided so skip checks
        print("No IP range provided - Skip IP check")
        return True

    net = ip_network(accepted_ip_network)
    if ip_address(input_sourceIp) in net:
        print("Source IP address match")
        return True
    else:
        print("Source IP address not in range")
        return False


def authenticate_user(auth_type, secret_dict, input_password, input_protocol):
    # Function returns True if: auth_type is password and passwords match or auth_type is SSH. Otherwise returns False
    if auth_type == "SSH":
        # Place for additional checks in future
        print("Skip password check as SSH login request")
        return True
    # auth_type could only be SSH or PASSWORD
    else:
        # Retrieve the password from the secret if exists
        password = lookup(secret_dict, "Password", input_protocol)
        if not password:
            print("Unable to authenticate user - No field match in Secret for password")
            return False

        if input_password == password:
            return True
        else:
            print("Unable to authenticate user - Incoming password does not match stored")
            return False


# Build out our response data for an authenticated response
def build_response(secret_dict, auth_type, input_protocol, input_username):
    response_data = {}
    # Check for each key value pair. These are required so set to empty string if missing
    role = lookup(secret_dict, "Role", input_protocol)
    if role:
        response_data["Role"] = role
    else:
        print("No field match for role - Set empty string in response")
        response_data["Role"] = ""
    # These are optional so ignore if not present
    policy = lookup(secret_dict, "Policy", input_protocol)
    if policy:
        response_data["Policy"] = policy

    # External Auth providers support chroot and virtual folder assignments so we'll check for that
    home_directory_details = lookup(
        secret_dict, "HomeDirectoryDetails", input_protocol)
    if home_directory_details:
        print("HomeDirectoryDetails found - Applying setting for virtual folders - "
              "Note: Cannot be used in conjunction with key: HomeDirectory")
        response_data["HomeDirectoryDetails"] = home_directory_details
        # If we have a virtual folder setup then we also need to set HomeDirectoryType to "Logical"
        print("Setting HomeDirectoryType to LOGICAL")
        response_data["HomeDirectoryType"] = "LOGICAL"

    # Note that HomeDirectory and HomeDirectoryDetails / Logical mode
    # can't be used together but we're not checking for this
    home_directory = lookup(secret_dict, "HomeDirectory", input_protocol)
    if home_directory:
        print("HomeDirectory found - Note: Cannot be used in conjunction with key: HomeDirectoryDetails")
        response_data["HomeDirectory"] = home_directory

    if auth_type == "SSH":
        public_key = lookup(secret_dict, "PublicKey", input_protocol)
        if public_key:
            response_data["PublicKeys"] = [public_key]
        else:
            # SSH Auth Flow - We don't have keys so we can't help
            print("Unable to authenticate user - No public keys found")
            return {}
    posix_profile = lookup(secret_dict, "PosixProfile", input_protocol)
    if posix_profile:
        response_data["PosixProfile"] = json.loads(posix_profile)
        # if response_data["HomeDirectoryType"] == "LOGICAL":
        #     HomeDirectoryEval = eval(secret_dict["HomeDirectoryDetails"])
        #     HomeDirectory = HomeDirectoryEval[0]["Target"].replace("$${Transfer:UserName}", input_username).split("/", 2)[2:][0]
        #     create_path(HomeDirectory)

    return response_data


def create_path(data):
    path = "/mnt/efs/" + data
    print(path)
    os.makedirs("/mnt/efs/test", exist_ok=True)
    # os.makedirs(path, exist_ok=True)


def get_secret(id, backend):
    region = os.environ["SecretStoreRegion"]
    print(
        f"Secrets Manager: Initiating lookup of {id} in {region} using {backend}.")

    client = boto3.session.Session().client(
        service_name=backend, region_name=region)
    try:
        if backend == "sessionmanager":
            resp = client.get_secret_value(SecretId=id)
            if "SecretString" in resp:
                print("Identified Secret String")
                return resp["SecretString"]
            else:
                print("Identified Binary Secret")
                return base64.b64decode(resp["SecretBinary"])
        elif backend == "ssm":
            resp = client.get_parameter(Name=id, WithDecryption=True)
            return resp["Parameter"]["Value"]
    except ClientError as err:
        print("Error Talking to Secret Backend: " + err.response["Error"]["Code"] + ", Message: " +
              err.response["Error"]["Message"])
        return None
