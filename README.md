NaggyBot
========

[![Circle CI](https://circleci.com/gh/dmskr/naggybot.svg?style=shield)] (https://circleci.com/gh/dmskr/naggybot)

To run the app locally:
Copy and edit .env file from example provided

```bash
cp env.example .env
```
make sure mongo db connection string as well as github auth set to correct values

To Run the app using docker:

1. Make sure .env file contains correct data for your mongo & github connectivity
2. Run docker compose
```bash
docker-compose up
```

