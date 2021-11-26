## Colors
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[33m

.DEFAULT_GOAL := default
.SILENT: help

## Help
help:
	printf "${COLOR_COMMENT}Usage:${COLOR_RESET}\n"
	printf "make [target]\n\nIf no target was provided, [default] is executed\n\n"
	printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	awk '/^[a-zA-Z\-\_0-9\.@]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf " ${COLOR_INFO}%-16s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

DEBUG ?= 0

ifeq ($(DEBUG), 0)
	LDFLAGS += -s -w
	GO_BUILD = CGO_ENABLED=0 go build -ldflags "$(LDFLAGS)" -trimpath
else
	GO_BUILD = CGO_ENABLED=0 go build -ldflags "$(LDFLAGS)"
endif

.PHONY: default
## Runs the default target building the binary
default: clean mod-tidy fmt vet-check test build

.PHONY: build
## Builds telemetry binary
build: 
	$(GO_BUILD)
	
.PHONY: clean
## Alias for `go clean`
clean:
	go clean

.PHONY: fmt
## Alias for `go fmt ./...`
fmt:
	go fmt ./...

.PHONY: mod-tidy
## Alias for `go mod tidy`
mod-tidy:
	go mod tidy

.PHONY: test
## Alias for `go test -v ./...`
test:
	go test -v ./...

.PHONY: vet-check
## Alias for `go vet ./...`
vet-check:
	go vet ./...

.PHONY: fmt-check
## Alias for `go fmt`
fmt-check:
	gofmt -l .
	[ "`gofmt -l .`" = "" ]

.PHONY: generate
## Alias for `go generate ./...`
generate:
ifeq (, $(shell command -v mockery 2> /dev/null))
	$(error "'mockery' command not found. You can install it locally with 'go install github.com/vektra/mockery/v2'.")
endif
	go generate ./...

.PHONY: start
## Start the platform infrastructure
start:
	touch .env
	docker-compose up -d