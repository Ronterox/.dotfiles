FROM alpine:latest

RUN apk add --no-cache bash git curl

COPY . .

CMD .local/bin/start-tool && bash
