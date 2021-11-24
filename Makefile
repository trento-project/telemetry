DEBUG ?= 0

ifeq ($(DEBUG), 0)
	LDFLAGS += -s -w
	GO_BUILD = CGO_ENABLED=0 go build -ldflags "$(LDFLAGS)" -trimpath
else
	GO_BUILD = CGO_ENABLED=0 go build -ldflags "$(LDFLAGS)"
endif

.PHONY: default
default: clean mod-tidy fmt vet-check test build

.PHONY: build
build: 
	$(GO_BUILD)
	
.PHONY: clean
clean:
	go clean

.PHONY: fmt
fmt:
	go fmt ./...

.PHONY: mod-tidy
mod-tidy:
	go mod tidy

.PHONY: test
test:
	go test -v ./...

.PHONY: vet-check
vet-check:
	go vet ./...

.PHONY: fmt-check
fmt-check:
	gofmt -l .
	[ "`gofmt -l .`" = "" ]

.PHONY: generate
generate:
ifeq (, $(shell command -v mockery 2> /dev/null))
	$(error "'mockery' command not found. You can install it locally with 'go install github.com/vektra/mockery/v2'.")
endif
	go generate ./...