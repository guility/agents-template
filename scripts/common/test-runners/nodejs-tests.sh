run_nodejs_unit_tests() {
    local test_dir="$ROOT_DIR/tests/unit"

    if [ ! -d "$test_dir" ]; then
        log_error "Node.js unit test directory not found: $test_dir"
        return 1
    fi

    log_step "Running Node.js unit tests..."

    # Проверка наличия package.json
    if [ ! -f "$ROOT_DIR/package.json" ]; then
        log_error "package.json not found; cannot run Node.js tests"
        return 1
    fi

    cd "$ROOT_DIR" || return 1

    # Определение менеджера пакетов
    local runner="npm run test:unit"
    if [ -f "pnpm-lock.yaml" ]; then
        runner="corepack pnpm run test:unit"
    elif [ -f "yarn.lock" ]; then
        runner="yarn test:unit"
    fi

    if $runner 2>&1 | tee "$ROOT_DIR/test-results/unit-nodejs.log"; then
        log_info "Node.js unit tests passed"
    else
        log_error "Node.js unit tests failed"
        return 1
    fi
}

run_nodejs_integration_tests() {
    run_nodejs_suite integration
}

run_nodejs_e2e_tests() {
    run_nodejs_suite e2e
}

run_nodejs_suite() {
    local suite="$1"
    local test_dir="$ROOT_DIR/tests/$suite"
    if [ ! -d "$test_dir" ] || ! find "$test_dir" -type f -print -quit | grep -q .; then
        log_error "Node.js $suite test suite is missing or empty"
        return 1
    fi
    cd "$ROOT_DIR" || return 1
    if [ -f "pnpm-lock.yaml" ]; then
        corepack pnpm run "test:$suite"
    else
        npm run "test:$suite"
    fi
}

# Мутационное тестирование для Node.js (stryker)
run_nodejs_mutation_tests() {
    log_step "Running Node.js mutation testing..."

    if [ ! -f "$ROOT_DIR/package.json" ]; then
        return 0
    fi

    cd "$ROOT_DIR" || return 1

    # Проверка наличия stryker
    if npx stryker --help &> /dev/null; then
        log_info "Using stryker for mutation testing..."

        if npx stryker run 2>&1 | tee "$ROOT_DIR/test-results/mutation-nodejs.log"; then
            log_info "Mutation testing completed"
        else
            log_error "Stryker found surviving mutants or failed to complete"
            return 1
        fi
    else
        log_error "Stryker not found; cannot run Node.js mutation testing"
        return 1
    fi
}

# Запуск тестов для Rust
