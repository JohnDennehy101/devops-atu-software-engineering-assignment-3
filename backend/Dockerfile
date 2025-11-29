# Build
FROM golang:1.25-alpine AS builder

WORKDIR /app

RUN apk update && apk upgrade && apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/bin/api ./cmd/api

RUN GOBIN=/app/bin go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Test
FROM golang:1.25-alpine AS tester

WORKDIR /app

RUN apk update && apk upgrade && apk add --no-cache git

COPY --from=builder /app /app/

CMD ["sh"]

# Production
FROM alpine:latest

RUN apk update && apk upgrade --no-cache && \
    apk --no-cache add ca-certificates tzdata postgresql-client

WORKDIR /root/

COPY --from=builder /app/bin/api .

COPY --from=builder /app/bin/migrate /usr/local/bin/migrate

COPY --from=builder /app/migrations ./migrations

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \ 
    CMD wget --no-verbose --tries=1 --spider $HEALTHCHECK_URL || exit 1

CMD ["sh", "-c", "migrate -path ./migrations -database $NOTES_DB_DSN up && ./api --cors-trusted-origins \"$FRONTEND_BASE_URL\""]