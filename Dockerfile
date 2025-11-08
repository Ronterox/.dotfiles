FROM alpine:latest

RUN apk add --no-cache bash git curl alpine-sdk

COPY . .

CMD .local/bin/start-tool && bash
