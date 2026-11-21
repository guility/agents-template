run_python_mutation_tests() {
    log_step "Running Python mutation testing..."

    if ! command -v mutmut &> /dev/null; then
        log_error "mutmut not found; cannot run Python mutation tests"
        return 1
    fi

    cd "$ROOT_DIR" || return 1
    if mutmut run 2>&1 | tee "$ROOT_DIR/test-results/mutation-python.log"; then
        mutmut results --all true | tee -a "$ROOT_DIR/test-results/mutation-python.log"
        if grep -q ': survived$' "$ROOT_DIR/test-results/mutation-python.log"; then
            log_error "Python mutation testing found surviving mutants"
            return 1
        fi
        log_info "Python mutation testing passed"
    else
        mutmut results --all true | tee -a "$ROOT_DIR/test-results/mutation-python.log"
        log_error "Python mutation testing failed; surviving mutants remain"
        return 1
    fi
}
