run_rust_tests() {
    log_step "Running Rust tests..."

    local cargo_toml="$ROOT_DIR/Cargo.toml"

    if [ ! -f "$cargo_toml" ]; then
        log_error "Cargo.toml not found; cannot run Rust tests"
        return 1
    fi

    cd "$ROOT_DIR" || return 1

    # Unit и integration тесты
    if cargo test --all-features 2>&1 | tee "$ROOT_DIR/test-results/rust-tests.log"; then
        log_info "Rust tests passed"
    else
        log_error "Rust tests failed"
        return 1
    fi

    if ! command -v cargo-llvm-cov &> /dev/null; then
        log_error "cargo-llvm-cov is required for the Rust line-coverage gate"
        return 1
    fi
    rustup component add llvm-tools-preview --toolchain "${RUSTUP_TOOLCHAIN:-stable}" || return 1
    mkdir -p "$ROOT_DIR/docs/coverage/rust"
    if ! cargo llvm-cov --locked --all-features --lcov \
        --output-path "$ROOT_DIR/docs/coverage/rust/lcov.info" \
        --fail-under-lines 100 2>&1 | tee "$ROOT_DIR/test-results/rust-coverage.log"; then
        log_error "Rust line coverage is below 100% or coverage generation failed"
        return 1
    fi
    log_info "Rust line coverage gate passed"
}

# Мутационное тестирование для Rust (cargo-mutants)
run_rust_mutation_tests() {
    log_step "Running Rust mutation testing..."

    local cargo_toml="$ROOT_DIR/Cargo.toml"

    if [ ! -f "$cargo_toml" ]; then
        return 0
    fi

    if command -v cargo-mutants &> /dev/null; then
        cd "$ROOT_DIR" || return 1

        if cargo mutants --jobs 2 2>&1 | tee "$ROOT_DIR/test-results/mutation-rust.log"; then
            log_info "Rust mutation testing completed"
        else
            log_error "Rust mutation testing found surviving mutants or failed to complete"
            return 1
        fi
    else
        log_error "cargo-mutants not found; cannot run Rust mutation testing"
        return 1
    fi
}

# Запуск тестов для Go
