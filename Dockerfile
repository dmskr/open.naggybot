FROM node:0.10.36-onbuild
ONBUILD RUN apt-get update && apt-get install gcc make build-essential

expose 8081
