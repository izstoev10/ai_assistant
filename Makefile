# Makefile (repo root)

# List of proto-based services (must match proto filenames!)
SERVICES := auth notes openai-proxy

PROTO_DIR := proto

PID_FILE := .service_pids

# Ensure protoc-gen-go plugins are installed
PROTOC := $(shell command -v protoc 2>/dev/null)
ifeq ($(PROTOC),)
$(error "protoc not found; install protobuf-compiler")
endif
ifeq ($(shell command -v protoc-gen-go 2>/dev/null),)
$(error "protoc-gen-go not found; run 'go install google.golang.org/protobuf/cmd/protoc-gen-go@latest'")
endif
ifeq ($(shell command -v protoc-gen-go-grpc 2>/dev/null),)
$(error "protoc-gen-go-grpc not found; run 'go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest'")
endif

.PHONY: all proto run clean tidy stop

all: proto run

proto:
	@echo "🔨 Generating protobuf code…"
	@for svc in $(SERVICES); do \
	  echo "  • $$svc"; \
	  protoc \
	    --proto_path=$(PROTO_DIR) \
	    --go_out=services/$$svc \
	    --go-grpc_out=services/$$svc \
	    $(PROTO_DIR)/$$svc.proto; \
	done
	@echo "✅ Protobuf generation complete."

## run: start all services in background and record their PIDs
run:
	@echo "🚀 Starting services…"
	@rm -f $(PID_FILE)
	@for svc in $(SERVICES); do \
	  port=$$(case $$svc in \
	    auth) echo 50051 ;; \
	    notes) echo 50052 ;; \
	    openai-proxy) echo 50053 ;; \
	  esac); \
	  (cd services/$$svc && go run cmd/server.go --port $$port) & \
	  echo $$! >> $(PID_FILE); \
	  echo "  • $$svc (PID $$!) on port $$port"; \
	done
	@echo "▶ To stop services: make stop"
	@wait

## stop: kill all services started by make run
stop:
	@if [ -f $(PID_FILE) ]; then \
	  echo "🛑 Stopping services…"; \
	  # kill all PIDs listed in the file, silencing any errors \
	  kill $$(cat $(PID_FILE)) >/dev/null 2>&1; \
	  rm -f $(PID_FILE); \
	  echo "✅ All services stopped."; \
	else \
	  echo "ℹ️  No running services (PID file not found)."; \
	fi

## clean: remove generated pb files
clean:
	@echo "🧹 Cleaning generated code…"
	@for svc in $(SERVICES); do \
	  rm -f services/$$svc/*.pb.go; \
	done
	@echo "✅ Clean complete."

tidy:
	@echo "🧹 Tidying go.mod in all services…"
	@for svc in $(SERVICES); do \
	  echo "  • $$svc"; \
	  (cd services/$$svc && go mod tidy); \
	done
	@echo "✅ All services tidied."
