FROM node:slim

WORKDIR /app

RUN apt-get update -y && apt-get install jq openssl gpg -y

COPY backup.sh .

RUN npm i -g @bitwarden/cli

ENV EXPORT_PATH=/app/exports

ENTRYPOINT ["bash", "/app/backup.sh"]
