FROM node:4.4.6
ONBUILD RUN apt-get update && apt-get install gcc make build-essential

RUN mkdir -p /var/naggybot
WORKDIR /var/naggybot

COPY . /var/naggybot
RUN rm -rf ./node_modules
RUN npm install

EXPOSE 8081
CMD ["npm", "start"]

