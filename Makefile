.PHONY: all clean help
.PHONY: build-x86_64 build-arm64 build-all build-x86_64-static build-arm64-static build-all-static
.PHONY: libcarla-x86_64 libcarla-arm64 third-party-x86_64 third-party-arm64
.PHONY: client-x86_64 client-arm64 client-x86_64-static client-arm64-static
.PHONY: clean-x86_64 clean-arm64 test-x86_64 test-arm64 test-x86_64-static test-arm64-static
.PHONY: prepare-python-deps-x86_64 prepare-python-deps-arm64
.PHONY: wheel-x86_64 wheel-arm64 wheels-all clean-python

# Docker images
DOCKER_X86_64 = carla-x86_64-native:ubuntu-22.04
DOCKER_ARM64 = carla-arm64-builder:latest

# Directories
BUILD_X86_64 = build/x86_64
BUILD_ARM64 = build/aarch64
DEPS_X86_64 = deps/x86_64
DEPS_ARM64 = deps/aarch64

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
NC = \033[0m # No Color

##@ General

help: ## Display this help
	@echo "CARLA Simple Client - Build System"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

all: build-all ## Build everything (x86_64 + ARM64)

##@ x86_64 Builds

build-x86_64: libcarla-x86_64 third-party-x86_64 client-x86_64 ## Build complete x86_64 stack (dynamic)

build-x86_64-static: libcarla-x86_64 third-party-x86_64 client-x86_64-static ## Build complete x86_64 stack (static)

libcarla-x86_64: ## Build LibCarla for x86_64
	@echo "$(GREEN)Building LibCarla for x86_64...$(NC)"
	@mkdir -p $(BUILD_X86_64)/libcarla
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace/$(BUILD_X86_64)/libcarla \
		$(DOCKER_X86_64) bash -c ' \
		cmake /workspace/LibCarla/cmake \
			-DCMAKE_BUILD_TYPE=Client \
			-DCMAKE_INSTALL_PREFIX=/workspace/$(BUILD_X86_64)/libcarla/install \
			-DLIBCARLA_BUILD_RELEASE=ON \
			-DLIBCARLA_BUILD_DEBUG=OFF \
			-DLIBCARLA_BUILD_TEST=OFF \
			-DRPCLIB_INCLUDE_PATH=/workspace/$(DEPS_X86_64)/include \
			-DBOOST_INCLUDE_PATH=/usr/include \
			-DRECAST_INCLUDE_PATH=/usr/include \
			-DLIBPNG_INCLUDE_PATH=/usr/include \
			-G Ninja && \
		ninja install'
	@echo "$(GREEN)✓ LibCarla x86_64 built successfully$(NC)"

third-party-x86_64: ## Build third-party libraries for x86_64
	@echo "$(GREEN)Building third-party libraries for x86_64...$(NC)"
	@mkdir -p $(BUILD_X86_64)/third-party
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace/$(BUILD_X86_64)/third-party \
		$(DOCKER_X86_64) bash -c ' \
		g++ -std=c++14 -fPIC -O3 -DNDEBUG \
			-c /workspace/LibCarla/source/third-party/odrSpiral/odrSpiral.cpp -o odrSpiral.o && \
		g++ -std=c++14 -fPIC -O3 -DNDEBUG \
			-c /workspace/LibCarla/source/third-party/pugixml/pugixml.cpp -o pugixml.o && \
		ar rcs libcarla_third_party.a odrSpiral.o pugixml.o'
	@echo "$(GREEN)✓ Third-party x86_64 built successfully$(NC)"

client-x86_64: libcarla-x86_64 third-party-x86_64 ## Build C++ client for x86_64 (dynamic linking)
	@echo "$(GREEN)Building C++ client for x86_64 (dynamic)...$(NC)"
	@if [ -f "examples/cpp_client/cpp_client" ]; then \
		echo "$(YELLOW)Client already exists, rebuilding...$(NC)"; \
	fi
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace/examples/cpp_client \
		$(DOCKER_X86_64) bash -c ' \
		g++ -std=c++14 -pthread -fPIC -O3 -DNDEBUG \
			-DBOOST_ERROR_CODE_HEADER_ONLY \
			-I/workspace/$(BUILD_X86_64)/libcarla/install/include \
			-I/workspace/$(DEPS_X86_64)/include \
			-isystem /usr/include/boost \
			-o cpp_client main.cpp \
			/workspace/$(BUILD_X86_64)/libcarla/install/lib/libcarla_client.a \
			/workspace/$(BUILD_X86_64)/third-party/libcarla_third_party.a \
			/workspace/$(DEPS_X86_64)/lib/librpc.a \
			-lboost_filesystem -lboost_system -lpng -lz'
	@echo "$(GREEN)✓ C++ client x86_64 (dynamic) built successfully$(NC)"
	@ls -lh examples/cpp_client/cpp_client

client-x86_64-static: libcarla-x86_64 third-party-x86_64 ## Build C++ client for x86_64 (static linking)
	@echo "$(GREEN)Building C++ client for x86_64 (static)...$(NC)"
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace/examples/cpp_client \
		$(DOCKER_X86_64) bash -c ' \
		g++ -std=c++14 -pthread -fPIC -O3 -DNDEBUG \
			-DBOOST_ERROR_CODE_HEADER_ONLY \
			-I/workspace/$(BUILD_X86_64)/libcarla/install/include \
			-I/workspace/$(DEPS_X86_64)/include \
			-isystem /usr/include/boost \
			-static-libgcc -static-libstdc++ \
			-o cpp_client_static main.cpp \
			/workspace/$(BUILD_X86_64)/libcarla/install/lib/libcarla_client.a \
			/workspace/$(DEPS_X86_64)/lib/librpc.a \
			-Wl,-Bstatic -lboost_filesystem -lboost_system -lpng \
			-Wl,-Bdynamic -lz -lpthread -ldl'
	@echo "$(GREEN)✓ C++ client x86_64 (static) built successfully$(NC)"
	@ls -lh examples/cpp_client/cpp_client_static
	@echo ""
	@echo "$(YELLOW)Size comparison:$(NC)"
	@if [ -f "examples/cpp_client/cpp_client" ]; then \
		echo -n "  Dynamic: "; ls -lh examples/cpp_client/cpp_client | awk '{print $$5}'; \
	fi
	@echo -n "  Static:  "; ls -lh examples/cpp_client/cpp_client_static | awk '{print $$5}'

##@ ARM64 Builds

build-arm64: libcarla-arm64 third-party-arm64 client-arm64 ## Build complete ARM64 stack (dynamic)

build-arm64-static: libcarla-arm64 third-party-arm64 client-arm64-static ## Build complete ARM64 stack (static)

libcarla-arm64: ## Build LibCarla for ARM64
	@echo "$(GREEN)Building LibCarla for ARM64...$(NC)"
	@mkdir -p $(BUILD_ARM64)/libcarla
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace/$(BUILD_ARM64)/libcarla \
		$(DOCKER_ARM64) bash -c ' \
		cmake /workspace/LibCarla/cmake \
			-DCMAKE_TOOLCHAIN_FILE=/workspace/cmake/toolchain-arm64.cmake \
			-DCMAKE_BUILD_TYPE=Client \
			-DCMAKE_INSTALL_PREFIX=/workspace/$(BUILD_ARM64)/libcarla/install \
			-DLIBCARLA_BUILD_RELEASE=ON \
			-DLIBCARLA_BUILD_DEBUG=OFF \
			-DLIBCARLA_BUILD_TEST=OFF \
			-DRPCLIB_INCLUDE_PATH=/workspace/$(DEPS_ARM64)/install/rpclib-2.2.1/include \
			-DBOOST_INCLUDE_PATH=/workspace/$(DEPS_ARM64)/install/boost-1.84.0/include \
			-DRECAST_INCLUDE_PATH=/workspace/$(DEPS_ARM64)/install/recast-1.6.0/include \
			-DLIBPNG_INCLUDE_PATH=/workspace/$(DEPS_ARM64)/install/libpng-1.6.37/include \
			-G Ninja && \
		ninja install'
	@echo "$(GREEN)✓ LibCarla ARM64 built successfully$(NC)"

third-party-arm64: ## Build third-party libraries for ARM64
	@echo "$(GREEN)Building third-party libraries for ARM64...$(NC)"
	@mkdir -p $(BUILD_ARM64)/third-party
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace/$(BUILD_ARM64)/third-party \
		$(DOCKER_ARM64) bash -c ' \
		aarch64-linux-gnu-g++ -std=c++14 -fPIC -O3 -DNDEBUG \
			-c /workspace/LibCarla/source/third-party/odrSpiral/odrSpiral.cpp -o odrSpiral.o && \
		aarch64-linux-gnu-g++ -std=c++14 -fPIC -O3 -DNDEBUG \
			-c /workspace/LibCarla/source/third-party/pugixml/pugixml.cpp -o pugixml.o && \
		aarch64-linux-gnu-ar rcs libcarla_third_party.a odrSpiral.o pugixml.o'
	@echo "$(GREEN)✓ Third-party ARM64 built successfully$(NC)"

client-arm64: libcarla-arm64 third-party-arm64 ## Build C++ client for ARM64 (dynamic linking)
	@echo "$(GREEN)Building C++ client for ARM64 (dynamic)...$(NC)"
	@mkdir -p $(BUILD_ARM64)/cpp_client
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace/$(BUILD_ARM64)/cpp_client \
		$(DOCKER_ARM64) bash -c ' \
		aarch64-linux-gnu-g++ -std=c++14 -pthread -fPIC -O3 -DNDEBUG \
			-DBOOST_ERROR_CODE_HEADER_ONLY \
			-I/workspace/$(BUILD_ARM64)/libcarla/install/include \
			-I/workspace/$(DEPS_ARM64)/install/rpclib-2.2.1/include \
			-I/workspace/$(DEPS_ARM64)/install/boost-1.84.0/include \
			-o cpp_client /workspace/examples/cpp_client/main.cpp \
			/workspace/$(BUILD_ARM64)/libcarla/install/lib/libcarla_client.a \
			/workspace/$(BUILD_ARM64)/third-party/libcarla_third_party.a \
			/workspace/$(DEPS_ARM64)/install/rpclib-2.2.1/lib/librpc.a \
			/workspace/$(DEPS_ARM64)/install/boost-1.84.0/lib/libboost_filesystem.a \
			/workspace/$(DEPS_ARM64)/install/boost-1.84.0/lib/libboost_system.a \
			/workspace/$(DEPS_ARM64)/install/recast-1.6.0/lib/libRecast.a \
			/workspace/$(DEPS_ARM64)/install/recast-1.6.0/lib/libDetour.a \
			/workspace/$(DEPS_ARM64)/install/recast-1.6.0/lib/libDetourCrowd.a \
			/workspace/$(DEPS_ARM64)/install/libpng-1.6.37/lib/libpng.a -lz'
	@echo "$(GREEN)✓ C++ client ARM64 (dynamic) built successfully$(NC)"
	@ls -lh $(BUILD_ARM64)/cpp_client/cpp_client

client-arm64-static: libcarla-arm64 third-party-arm64 ## Build C++ client for ARM64 (static linking)
	@echo "$(GREEN)Building C++ client for ARM64 (static)...$(NC)"
	@mkdir -p $(BUILD_ARM64)/cpp_client
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace/$(BUILD_ARM64)/cpp_client \
		$(DOCKER_ARM64) bash -c ' \
		aarch64-linux-gnu-g++ -std=c++14 -pthread -fPIC -O3 -DNDEBUG \
			-DBOOST_ERROR_CODE_HEADER_ONLY \
			-I/workspace/$(BUILD_ARM64)/libcarla/install/include \
			-I/workspace/$(DEPS_ARM64)/install/rpclib-2.2.1/include \
			-I/workspace/$(DEPS_ARM64)/install/boost-1.84.0/include \
			-static-libgcc -static-libstdc++ \
			-o cpp_client_static /workspace/examples/cpp_client/main.cpp \
			/workspace/$(BUILD_ARM64)/libcarla/install/lib/libcarla_client.a \
			/workspace/$(DEPS_ARM64)/install/rpclib-2.2.1/lib/librpc.a \
			/workspace/$(DEPS_ARM64)/install/boost-1.84.0/lib/libboost_filesystem.a \
			/workspace/$(DEPS_ARM64)/install/boost-1.84.0/lib/libboost_system.a \
			/workspace/$(DEPS_ARM64)/install/recast-1.6.0/lib/libRecast.a \
			/workspace/$(DEPS_ARM64)/install/recast-1.6.0/lib/libDetour.a \
			/workspace/$(DEPS_ARM64)/install/recast-1.6.0/lib/libDetourCrowd.a \
			/workspace/$(DEPS_ARM64)/install/libpng-1.6.37/lib/libpng.a -lz'
	@echo "$(GREEN)✓ C++ client ARM64 (static) built successfully$(NC)"
	@ls -lh $(BUILD_ARM64)/cpp_client/cpp_client_static
	@echo ""
	@echo "$(YELLOW)Size comparison:$(NC)"
	@if [ -f "$(BUILD_ARM64)/cpp_client/cpp_client" ]; then \
		echo -n "  Dynamic: "; ls -lh $(BUILD_ARM64)/cpp_client/cpp_client | awk '{print $$5}'; \
	fi
	@echo -n "  Static:  "; ls -lh $(BUILD_ARM64)/cpp_client/cpp_client_static | awk '{print $$5}'

##@ Multi-Architecture

build-all: build-x86_64 build-arm64 ## Build for both x86_64 and ARM64 (dynamic)
	@echo "$(GREEN)✓ All architectures built successfully$(NC)"
	@echo ""
	@echo "Build artifacts (dynamic):"
	@echo "  x86_64: examples/cpp_client/cpp_client"
	@echo "  ARM64:  $(BUILD_ARM64)/cpp_client/cpp_client"

build-all-static: build-x86_64-static build-arm64-static ## Build for both x86_64 and ARM64 (static)
	@echo "$(GREEN)✓ All architectures built successfully (static)$(NC)"
	@echo ""
	@echo "Build artifacts (static):"
	@echo "  x86_64: examples/cpp_client/cpp_client_static"
	@echo "  ARM64:  $(BUILD_ARM64)/cpp_client/cpp_client_static"

##@ Testing

test-x86_64: ## Run x86_64 client (requires CARLA server)
	@echo "$(YELLOW)Starting x86_64 client (connect to localhost:2000)...$(NC)"
	./examples/cpp_client/cpp_client localhost 2000

test-x86_64-static: ## Run x86_64 static client (requires CARLA server)
	@echo "$(YELLOW)Starting x86_64 static client (connect to localhost:2000)...$(NC)"
	./examples/cpp_client/cpp_client_static localhost 2000

test-arm64: ## Run ARM64 client with QEMU (requires CARLA server)
	@echo "$(YELLOW)Starting ARM64 client with QEMU (connect to localhost:2000)...$(NC)"
	qemu-aarch64 -L /usr/aarch64-linux-gnu $(BUILD_ARM64)/cpp_client/cpp_client localhost 2000

test-arm64-static: ## Run ARM64 static client with QEMU (requires CARLA server)
	@echo "$(YELLOW)Starting ARM64 static client with QEMU (connect to localhost:2000)...$(NC)"
	qemu-aarch64 -L /usr/aarch64-linux-gnu $(BUILD_ARM64)/cpp_client/cpp_client_static localhost 2000

##@ Information

info: ## Show build information
	@echo "Build Information:"
	@echo "  Docker x86_64: $(DOCKER_X86_64)"
	@echo "  Docker ARM64:  $(DOCKER_ARM64)"
	@echo ""
	@echo "Build directories:"
	@echo "  x86_64: $(BUILD_X86_64)/"
	@echo "  ARM64:  $(BUILD_ARM64)/"
	@echo ""
	@echo "Dependency directories:"
	@echo "  x86_64: $(DEPS_X86_64)/"
	@echo "  ARM64:  $(DEPS_ARM64)/"
	@echo ""
	@echo "x86_64 Clients:"
	@if [ -f "examples/cpp_client/cpp_client" ]; then \
		echo -n "  Dynamic: "; ls -lh examples/cpp_client/cpp_client | awk '{print $$5}'; \
		file examples/cpp_client/cpp_client | sed 's/^/    /'; \
	else \
		echo "  Dynamic: not built"; \
	fi
	@if [ -f "examples/cpp_client/cpp_client_static" ]; then \
		echo -n "  Static:  "; ls -lh examples/cpp_client/cpp_client_static | awk '{print $$5}'; \
		file examples/cpp_client/cpp_client_static | sed 's/^/    /'; \
	else \
		echo "  Static:  not built"; \
	fi
	@echo ""
	@echo "ARM64 Clients:"
	@if [ -f "$(BUILD_ARM64)/cpp_client/cpp_client" ]; then \
		echo -n "  Dynamic: "; ls -lh $(BUILD_ARM64)/cpp_client/cpp_client | awk '{print $$5}'; \
		file $(BUILD_ARM64)/cpp_client/cpp_client | sed 's/^/    /'; \
	else \
		echo "  Dynamic: not built"; \
	fi
	@if [ -f "$(BUILD_ARM64)/cpp_client/cpp_client_static" ]; then \
		echo -n "  Static:  "; ls -lh $(BUILD_ARM64)/cpp_client/cpp_client_static | awk '{print $$5}'; \
		file $(BUILD_ARM64)/cpp_client/cpp_client_static | sed 's/^/    /'; \
	else \
		echo "  Static:  not built"; \
	fi
	@echo ""
	@if [ -d "dist" ] && [ "$$(ls -A dist 2>/dev/null)" ]; then \
		echo "Python Wheels:"; \
		ls -lh dist/*.whl 2>/dev/null | awk '{print "  " $$9 ": " $$5}' || true; \
	fi

##@ Python Wheels

prepare-python-deps-x86_64: libcarla-x86_64 third-party-x86_64
	@echo "$(GREEN)Preparing Python dependencies for x86_64...$(NC)"
	@mkdir -p deps/install/libcarla-client/lib
	@mkdir -p deps/install/libcarla-client/include/system
	@mkdir -p deps/install/boost-1.84.0/lib
	@# Copy libcarla
	@cp -f $(BUILD_X86_64)/libcarla/install/lib/libcarla_client.a deps/install/libcarla-client/lib/
	@# Copy third-party libs from build
	@cp -f $(BUILD_X86_64)/third-party/install/lib/*.a deps/install/libcarla-client/lib/ 2>/dev/null || true
	@# Copy third-party libs from deps (recast, rpc, png)
	@if [ -d "$(DEPS_X86_64)/install/recast/lib" ]; then \
		cp -f $(DEPS_X86_64)/install/recast/lib/*.a deps/install/libcarla-client/lib/ 2>/dev/null || true; \
	fi
	@if [ -f "$(DEPS_X86_64)/install/rpclib-v2.2.1_c5/lib/librpc.a" ]; then \
		cp -f $(DEPS_X86_64)/install/rpclib-v2.2.1_c5/lib/librpc.a deps/install/libcarla-client/lib/; \
	fi
	@if [ -f "$(DEPS_X86_64)/install/libpng-1.6.37/lib/libpng.a" ]; then \
		cp -f $(DEPS_X86_64)/install/libpng-1.6.37/lib/libpng.a deps/install/libcarla-client/lib/; \
	fi
	@# Copy headers
	@cp -rf $(BUILD_X86_64)/libcarla/install/include/* deps/install/libcarla-client/include/
	@# Copy system headers (rpclib, boost, recast)
	@if [ -d "$(DEPS_X86_64)/include" ]; then \
		cp -rf $(DEPS_X86_64)/include/* deps/install/libcarla-client/include/system/ 2>/dev/null || true; \
	fi
	@# Copy boost
	@if [ -d "$(DEPS_X86_64)/install/boost-1.84.0/lib" ]; then \
		cp -f $(DEPS_X86_64)/install/boost-1.84.0/lib/libboost_*.a deps/install/boost-1.84.0/lib/; \
	fi
	@echo "$(GREEN)✓ Python dependencies prepared$(NC)"

prepare-python-deps-arm64: libcarla-arm64 third-party-arm64 ## Prepare Python dependencies for ARM64
	@echo "$(GREEN)Preparing Python dependencies for ARM64...$(NC)"
	@mkdir -p deps/install/libcarla-client/lib
	@mkdir -p deps/install/libcarla-client/include/system
	@mkdir -p deps/install/boost-1.84.0/lib
	@# Copy libcarla
	@cp -f $(BUILD_ARM64)/libcarla/install/lib/libcarla_client.a deps/install/libcarla-client/lib/
	@# Copy third-party libs from deps (pre-built)
	@if [ -d "$(DEPS_ARM64)/install/recast-1.6.0/lib" ]; then \
		cp -f $(DEPS_ARM64)/install/recast-1.6.0/lib/*.a deps/install/libcarla-client/lib/ 2>/dev/null || true; \
	fi
	@# Copy rpc lib
	@if [ -f "$(DEPS_ARM64)/install/rpclib-2.2.1/lib/librpc.a" ]; then \
		cp -f $(DEPS_ARM64)/install/rpclib-2.2.1/lib/librpc.a deps/install/libcarla-client/lib/; \
	fi
	@# Copy libpng
	@if [ -f "$(DEPS_ARM64)/install/libpng-1.6.37/lib/libpng.a" ]; then \
		cp -f $(DEPS_ARM64)/install/libpng-1.6.37/lib/libpng.a deps/install/libcarla-client/lib/; \
	fi
	@# Copy headers
	@cp -rf $(BUILD_ARM64)/libcarla/install/include/* deps/install/libcarla-client/include/
	@# Copy system headers (rpclib, boost, recast)
	@if [ -d "$(DEPS_ARM64)/include" ]; then \
		cp -rf $(DEPS_ARM64)/include/* deps/install/libcarla-client/include/system/ 2>/dev/null || true; \
	fi
	@# Copy boost
	@if [ -d "$(DEPS_ARM64)/install/boost-1.84.0/lib" ]; then \
		cp -f $(DEPS_ARM64)/install/boost-1.84.0/lib/libboost_*.a deps/install/boost-1.84.0/lib/; \
	fi
	@echo "$(GREEN)✓ Python dependencies prepared$(NC)"

wheel-x86_64: prepare-python-deps-x86_64 ## Build Python wheel for x86_64
	@echo "$(GREEN)Building Python wheel for x86_64...$(NC)"
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace \
		$(DOCKER_X86_64) bash -c ' \
		python3 -m pip install --upgrade pip build wheel && \
		python3 -m build --wheel'
	@echo "$(GREEN)✓ Python wheel for x86_64 built$(NC)"

wheel-arm64: prepare-python-deps-arm64 ## Build Python wheel for ARM64 (cross-compiled)
	@echo "$(GREEN)Building Python wheel for ARM64...$(NC)"
	@docker run --rm -v "$$(pwd):/workspace" -w /workspace \
		$(DOCKER_ARM64) bash -c ' \
		python3 -m pip install --upgrade pip build wheel && \
		python3 -m build --wheel'
	@echo "$(GREEN)✓ Python wheel for ARM64 built$(NC)"

wheels-all: wheel-x86_64 wheel-arm64 ## Build Python wheels for all architectures

##@ Cleanup

clean-x86_64: ## Clean x86_64 build artifacts
	@echo "$(YELLOW)Cleaning x86_64 build artifacts...$(NC)"
	rm -rf $(BUILD_X86_64)
	rm -f examples/cpp_client/cpp_client examples/cpp_client/cpp_client_static
	@echo "$(GREEN)✓ x86_64 artifacts cleaned$(NC)"

clean-arm64: ## Clean ARM64 build artifacts
	@echo "$(YELLOW)Cleaning ARM64 build artifacts...$(NC)"
	rm -rf $(BUILD_ARM64)
	rm -f build/aarch64/cpp_client/cpp_client build/aarch64/cpp_client/cpp_client_static
	@echo "$(GREEN)✓ ARM64 artifacts cleaned$(NC)"

clean: clean-x86_64 clean-arm64 ## Clean all build artifacts
	@echo "$(GREEN)✓ All build artifacts cleaned$(NC)"

clean-python: ## Clean Python build artifacts
	@echo "$(YELLOW)Cleaning Python build artifacts...$(NC)"
	rm -rf dist/ *.egg-info deps/install/
	find PythonAPI -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find PythonAPI -type f -name '*.pyc' -delete 2>/dev/null || true
	find PythonAPI -type f -name '*.so' -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Python artifacts cleaned$(NC)"

clean-all: clean clean-python ## Clean everything including dependencies
	@echo "$(YELLOW)Cleaning all dependencies...$(NC)"
	rm -rf $(DEPS_X86_64) $(DEPS_ARM64)
	@echo "$(GREEN)✓ Everything cleaned$(NC)"
