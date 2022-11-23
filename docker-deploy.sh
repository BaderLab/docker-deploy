#!/bin/bash

# These env vars should be defined when running the script, e.g.
#
# 	IMAGE_NAME="foo" \
# 	SERVICE_NAME="fooservice" \
# 	REPO_DIR="/home/somebody/foo" \
# 	BRANCH="main" \
# 	PORT="3000" \
# 	./docker-deploy.sh 
#

IMAGE_NAME="${IMAGE_NAME:=image}"
DEFAULT_SERVICE_NAME="${IMAGE_NAME}service"
SERVICE_NAME="${SERVICE_NAME:=$DEFAULT_SERVICE_NAME}"
REPO_DIR="${REPO_DIR:=/home/someuser/some-dir}"
BRANCH="${BRANCH:=main}"
PORT="${PORT:=3000}"

SLACK_CHANNEL="${SLACK_CHANNEL:=monitoring}"
SLACK_USERNAME="${SLACK_USERNAME:=slackorgname}"
SLACK_AUTHOR="${SLACK_AUTHOR:=Deploy Bot}"
SLACK_HOOK=${SLACK_HOOK:=https://example.com/my/slack/hook/url/here}

deploy_docker() {
	echo "Performing a deployment."

	echo "Going to $REPO_DIR."
	cd $REPO_DIR
	
	echo "Changing branch to $BRANCH."
        git checkout $BRANCH

	echo "Building docker image."
	docker build -t $IMAGE_NAME .

	echo "Stopping previous docker service."
	docker service rm $SERVICE_NAME

	echo "Starting updated docker service."

	echo "Checking if .env exists."
	if [[ -f ".env" ]];
	then
		echo "Using .env to start updated docker service."
		docker service create --name $SERVICE_NAME --publish $PORT:$PORT --env-file .env  $IMAGE_NAME
	else
		echo "Did not find .env file.  Starting updated docker service without environment variables."
		docker service create --name $SERVICE_NAME --publish $PORT:$PORT $IMAGE_NAME
	fi

}

main() {
	echo "Checking for git updates."

	echo "Going to $REPO_DIR."
	cd $REPO_DIR

	echo "Changing branch to $BRANCH."
	git checkout $BRANCH

	echo "Fetching from origin."
	git fetch

	LATEST_LOCAL_COMMIT=$(git log -n 1 --pretty=format:%H "$BRANCH")
	LATEST_REMOTE_COMMIT=$(git log -n 1 --pretty=format:%H "origin/$BRANCH")

	if [ "$LATEST_LOCAL_COMMIT" == "$LATEST_REMOTE_COMMIT" ] && [ -z ${FORCE+x} ];
	then
		echo "Local repo is up to date.  Defferring redeployment until next check."
	else
		echo "Remote has new commits.  Pulling."
		git pull
		deploy_docker && notify_slack "The $IMAGE_NAME docker image has been deployed successfully on $HOSTNAME with commit $LATEST_REMOTE_COMMIT." || notify_slack "The $IMAGE_NAME docker image has failed to deploy on $HOSTNAME with commit $LATEST_REMOTE_COMMIT.  Please check the logs."
	fi
}

notify_slack() {
	TEXT=$1

	echo "Notifying Slack with text:"
	echo "$TEXT"

	JSON='
	{
		"username": "'$SLACK_USERNAME'",    
		"attachments": [
			{
				"fallback": "",
				"author_name": "'$SLACK_AUTHOR'",
				"text": "'$TEXT'"
			}
		]
	}
	'

	curl -X POST -H 'Content-type: application/json' --data "$JSON" "$SLACK_HOOK"
	echo ""
}

echo "Starting docker-deploy for $IMAGE_NAME on"
date
main

