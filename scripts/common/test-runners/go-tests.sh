run_go_tests() {
    log_step "Running Go tests..."

    local go_mod="$ROOT_DIR/go.mod"

    if [ ! -f "$go_mod" ]; then
        log_error "go.mod not found; cannot run Go tests"
        return 1
    fi

    cd "$ROOT_DIR" || return 1

    if go test ./tests/unit/... -v -coverpkg=./src/... \
        -coverprofile="$ROOT_DIR/test-results/go-coverage.out" \
        2>&1 | tee "$ROOT_DIR/test-results/go-tests.log"; then
        local coverage
        coverage=$(go tool cover -func="$ROOT_DIR/test-results/go-coverage.out" | awk '/^total:/ {print $3}')
        if [ "$coverage" != "100.0%" ]; then
            log_error "Go statement coverage is ${coverage:-missing}; 100% is required"
            return 1
        fi
        log_info "Go tests passed"

        # Генерация HTML отчета
        go tool cover -html="$ROOT_DIR/test-results/go-coverage.out" -o "$ROOT_DIR/docs/coverage/go/coverage.html" 2>/dev/null || true
    else
        log_error "Go tests failed"
        return 1
    fi
}

run_go_integration_tests() {
    run_go_suite integration
}

run_go_e2e_tests() {
    run_go_suite e2e
}

run_go_suite() {
    local suite="$1"
    local test_dir="$ROOT_DIR/tests/$suite"
    if [ ! -d "$test_dir" ] || ! find "$test_dir" -type f -print -quit | grep -q .; then
        log_error "Go $suite test suite is missing or empty"
        return 1
    fi
    cd "$ROOT_DIR" || return 1
    go test "./tests/$suite/..." -v 2>&1 | tee "$ROOT_DIR/test-results/$suite-go.log"
}

# Мутационное тестирование для Go (Gremlins)
run_go_mutation_tests() {
    log_step "Running Go mutation testing..."

    local go_mod="$ROOT_DIR/go.mod"

    if [ ! -f "$go_mod" ]; then
        return 0
    fi

    if command -v gremlins &> /dev/null; then
        cd "$ROOT_DIR" || return 1

        if gremlins unleash --integration --coverpkg=./... \
            --threshold-efficacy 100 --threshold-mcover 100 \
            2>&1 | tee "$ROOT_DIR/test-results/mutation-go.log"; then
            log_info "Go mutation testing completed"
        else
            log_error "Go mutation testing found surviving mutants or failed to complete"
            return 1
        fi
    else
        log_error "Gremlins not found; cannot run Go mutation testing"
        return 1
    fi
}

# Запуск тестов для C#
