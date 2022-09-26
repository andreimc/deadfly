.PHONY: all build deps dev-deps image migrate test vet sec format unused
CHECK_FILES?=./...
FLAGS?=-buildvcs=false

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: vet sec static build ## Run the tests and build the binary.

build: deps ## Build the binary.
	go build $(FLAGS)
	GOOS=linux GOARCH=amd64 go build $(FLAGS) -o deadfly-linux-amd64
	GOOS=darwin GOARCH=amd64 go build $(FLAGS) -o deadfly-darwin-amd64
	GOOS=darwin GOARCH=arm64 go build $(FLAGS) -o deadfly-darwin-x86

dev-deps: ## Install developer dependencies
	@go install github.com/gobuffalo/pop/soda@latest
	@go install github.com/securego/gosec/v2/cmd/gosec@latest
	@go install honnef.co/go/tools/cmd/staticcheck@latest

deps: ## Install dependencies.
	@go mod download
	@go mod verify

test: build ## Run tests.
	go test $(CHECK_FILES) -coverprofile=coverage.out -coverpkg ./... -p 1 -race -v -count=1

vet: # Vet the code
	go vet $(CHECK_FILES)

sec: dev-deps # Check for security vulnerabilities
	gosec -quiet $(CHECK_FILES)
	gosec -quiet -tests -exclude=G104 $(CHECK_FILES)

unused: dev-deps # Look for unused code
	@echo "Unused code:"
	staticcheck -checks U1000 $(CHECK_FILES)
	
	@echo
	
	@echo "Code used only in _test.go (do move it in those files):"
	staticcheck -checks U1000 -tests=false $(CHECK_FILES)

static: dev-deps
	staticcheck ./...

format:
	gofmt -s -w .
