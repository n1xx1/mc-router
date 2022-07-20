FROM golang:1.18

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build ./cmd/mc-router

ENTRYPOINT ["/build/mc-router"]
