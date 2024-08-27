#!/bin/bash

# Function to display an error message and usage instructions
function show_help() {
    echo "Error: Missing required environment variables."
    echo "Make sure the following environment variables are set:"
    echo "  GITHUB_REPO: The GitHub repository in the format 'owner/repo'."
    echo "  GITHUB_OAUTH_SECRET_ARN: The ARN of the GitHub OAuth secret in AWS Secrets Manager."
    echo
    echo "Usage:"
    echo "  ./script.sh"
    exit 1
}

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Environment Variables with default values
GITHUB_REPO=${GITHUB_REPO}
BRANCH=${BRANCH:-main}  # Default to 'main' if BRANCH is not set
GITHUB_OAUTH_SECRET_ARN=${GITHUB_OAUTH_SECRET_ARN}

# Check if required environment variables are set
if [ -z "$GITHUB_REPO" ] || [ -z "$GITHUB_OAUTH_SECRET_ARN" ]; then
    show_help
fi

# Extract the repository details from the full GitHub repo string
REPO_OWNER=$(echo "$GITHUB_REPO" | awk -F'/' '{print $1}')
REPO_NAME=$(echo "$GITHUB_REPO" | awk -F'/' '{print $2}')

# Define the stack names and other parameters using the extracted repository name
PIPELINE_STACK_NAME="${REPO_NAME}-pipeline"
TARGET_STACK_NAME="${REPO_NAME}"

# Create the CloudFormation stack
aws cloudformation create-stack \
    --stack-name "$PIPELINE_STACK_NAME" \
    --template-body file://pipeline.yaml \
    --parameters ParameterKey=GitHubOwner,ParameterValue="$REPO_OWNER" \
                 ParameterKey=GitHubRepoName,ParameterValue="$REPO_NAME" \
                 ParameterKey=GitHubBranch,ParameterValue="$BRANCH" \
                 ParameterKey=GitHubOAuthSecretArn,ParameterValue="$GITHUB_OAUTH_SECRET_ARN" \
                 ParameterKey=TargetStackName,ParameterValue="$TARGET_STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM
