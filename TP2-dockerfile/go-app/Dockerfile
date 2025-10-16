# Stage 1: Build
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod .
COPY main.go .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-w -s' -o webapp .

# Stage 2: Runtime
FROM alpine:3.18

RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/webapp .

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1

CMD ["./webapp"]
