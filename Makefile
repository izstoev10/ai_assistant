# Makefile (repo root)

# List of proto-based services (must match proto filenames!)
SERVICES := auth notes openai-proxy
PID_FILE := .service_pids
PROTO_DIR := proto

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
	    --go_out=paths=source_relative:services/$$svc \
	    --go-grpc_out=paths=source_relative:services/$$svc \
	    $(PROTO_DIR)/$$svc.proto; \
	done
	@echo "✅ Protobuf generation complete."

## run: start all services in the background and record their PIDs
run:
	@echo "🚀 Starting services…"
	@rm -f $(PID_FILE)
	@for svc in $(SERVICES); do \
	  port=$$(case $$svc in \
	    auth) echo 50050 ;; \
	    notes) echo 50051 ;; \
	    openai-proxy) echo 50052 ;; \
	  esac); \
	  echo "  • $$svc on port $$port"; \
	  (cd services/$$svc && go run cmd/server.go --port $$port) & \
	  echo $$! >> $(PID_FILE); \
	done
	@echo "▶ Services started in the background. Run ‘make stop’ to kill them."

## stop: kill whatever is listening on the three service ports
stop:
	@echo "🛑 Stopping services…"
	@for port in 8080 8081 8082 50050 50051 50052; do \
	  pid=$$(lsof -t -i tcp:$$port); \
	  if [ -n "$$pid" ]; then \
	    echo "  • killing $$pid on port $$port"; \
	    kill $$pid; \
	  else \
	    echo "  • nothing listening on port $$port"; \
	  fi; \
	done
	@echo "✅ All done."

## clean: remove generated protobuf code
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
