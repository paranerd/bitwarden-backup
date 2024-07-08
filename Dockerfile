FROM node:slim

WORKDIR /app

RUN apt-get update -y && apt-get install jq gpg -y

COPY backup.sh .

RUN npm i -g @bitwarden/cli

ENTRYPOINT ["bash", "/app/backup.sh"]
