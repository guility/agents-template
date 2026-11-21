#!/bin/bash
# Language-specific dependency installation for bootstrap.sh.

# Установка глобальных зависимостей
install_global_tools() {
    log_step "Installing global development tools..."
    
    # Pin the tools used by the measured local fast checks.
    if command -v python3 &> /dev/null; then
        log_info "Installing pinned fast Python checks..."
        python3 -m pip install --user -q lizard==1.25.0 ruff==0.17.6
    fi
    if [ -x "$PROJECT_ROOT/scripts/ci/checks/install-gitleaks.sh" ]; then
        GITLEAKS_VERSION=8.30.1 bash "$PROJECT_ROOT/scripts/ci/checks/install-gitleaks.sh"
    fi
    
    # Node.js инструменты (если есть npm)
    if command -v npm &> /dev/null; then
        log_info "Installing Node.js tools..."
        npm install -g prettier@3.6.2 2>/dev/null || true
    fi
    
    # Rust инструменты
    if command -v cargo &> /dev/null; then
        log_info "Installing Rust tools..."
        if command -v rustup &> /dev/null; then
            rustup toolchain install 1.100.0 --profile minimal --component clippy,rustfmt,llvm-tools-preview
            cargo +1.100.0 install cargo-llvm-cov --version 0.9.1 --locked
            cargo +1.100.0 install cargo-mutants --version 27.1.0 --locked
        else
            cargo install cargo-llvm-cov --version 0.9.1 --locked
        fi
    fi
    
    # Go инструменты
    if command -v go &> /dev/null; then
        log_info "Installing Go tools..."
        go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.8.0 2>/dev/null || true
    fi
    
    # Shell инструменты
    if command -v brew &> /dev/null; then
        brew install shellcheck shfmt 2>/dev/null || true
    elif command -v apt-get &> /dev/null; then
        apt-get install -y shellcheck 2>/dev/null || true
    fi
}
