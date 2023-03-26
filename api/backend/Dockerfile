FROM golang:alpine as builder
ENV GO111MODULE=on

RUN mkdir -p /app/
WORKDIR /app
ADD go.mod .
ADD go.sum .
RUN go mod download
ADD internal/cache internal/cache
RUN go build internal/cache/cache.go

ADD . .
RUN go build -o app
RUN go build -o bun cmd/bun/main.go

FROM node:alpine as nodeBuilder

WORKDIR /app
ADD docxExport/package.json docxExport/yarn.lock ./
RUN yarn install --frozen-lockfile
ADD docxExport/* ./
RUN npx tsc

FROM alpine as prod
RUN apk add --no-cache ca-certificates postgresql-client curl tini bash gnupg nodejs yarn
ENTRYPOINT ["/sbin/tini", "--"]

ENV GO_ENV=production
EXPOSE 1323

# node
WORKDIR /app/docxExport
COPY --from=nodeBuilder /app/package.json /app/yarn.lock ./
RUN yarn install --production --frozen-lockfile
COPY --from=nodeBuilder /app/dist ./dist

WORKDIR /app
COPY --from=builder /app/app /app/bun ./
RUN touch .env

CMD /app/bun db init && /app/bun db migrate && exec /app/app
