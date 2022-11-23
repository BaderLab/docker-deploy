# docker-deploy
Automatic docker deployments on git push

## What does this do?

This script automates deploying your service when you do a `git push` to your main branch:

1. It deploys when you have a new commit on `main`.
2. It takes your `Dockerfile` in your repo and builds an image.
3. It deploys your docker image as a service.
4. It notifies you on slack that the deployment has completed.

This is only for simple deployments.

## Prerequisites

You must use this on Linux or Mac.  This script has been tested on Ubuntu VMs.  You must have the following installed:

- bash
- git
- curl
- [docker](https://docs.docker.com/engine/install/ubuntu/), with docker swarm turned on
- tee (nice but optional)

You must have the following environment variables defined to use this script:

- `IMAGE_NAME` : the name of your docker image
- `SERVICE_NAME` [optional] : the name of your docker service (defaults to `IMAGE_NAME` with 'service' appended)
- `REPO_DIR` : the absolute path of your repo on the file system
- `BRANCH` [optional] : the git branch to deploy (default `main`)
- `PORT` : the port to deploy your service (e.g. 3000)
- `SLACK_CHANNEL` : the slack channel to notify (e.g. `monitoring`)
- `SLACK_USERNAME` : the username of the slack org (e.g. `cytoscape`)
- `SLACK_AUTHOR` : the name of your [slack app / webhook](https://api.slack.com/messaging/webhooks) (e.g. `Deploy Bot`)
- `SLACK_HOOK` : the slack [hook address](https://api.slack.com/messaging/webhooks)

## Usage

Clone your repo:

```
cd ~
git clone https://example.com/myservice.git # replace with your repo
```

Set up a cron job:

```
crontab -e
```

Set the job for something like every 5 minutes:

```
*/5 * * * * /home/myusername/myservice.sh
```

You can define your variables in a script like `~/myservice.sh`:

```
#!/bin/bash

# Variables for docker-deploy.sh
export IMAGE_NAME="myservice"
export REPO_DIR="~/myservice"
export PORT="3000"
export SLACK_CHANNEL="monitoring"
export SLACK_USERNAME="myslackorg"
export SLACK_AUTHOR="Deploy Bot"
export SLACK_HOOK="https://example.com/some/address/you/should/get/from/the/slack/docs"

# Note: If you have $REPO_DIR/.env on the file system, then that env file will be used by the docker container.

# Run the deployment script and save the output to a log file.
~/docker-deploy.sh | tee ~/$IMAGE_NAME.log
```

## What if I want to force a build?

If you set the `FORCE` environment variable to a value like `true`, then running `docker-deploy.sh` will rebuild and redeploy everything even if there isn't a new commit.

E.g. with the above `myservice.sh`:

```
FORCE=true ~/myservice.sh
```
