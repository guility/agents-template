run_csharp_tests() {
    log_step "Running C# tests..."

    local sln_file
    local project_file
    sln_file=$(find "$ROOT_DIR" -name "*.sln" -print -quit)
    if [ -n "$sln_file" ]; then
        project_file="$sln_file"
    else
        project_file=$(find "$ROOT_DIR" -name "*.Tests.csproj" -print -quit)
        if [ -z "$project_file" ]; then
            project_file=$(find "$ROOT_DIR" -name "*.csproj" -print -quit)
        fi
    fi

    if [ -z "$project_file" ]; then
        log_error "No .sln or .csproj file found; cannot run C# tests"
        return 1
    fi

    if ! command -v dotnet &> /dev/null; then
        log_error "dotnet not found; cannot run C# tests"
        return 1
    fi

    cd "$(dirname "$project_file")" || return 1

    # Запуск тестов с покрытием
    local coverage_dir="$ROOT_DIR/test-results/csharp/run-$(date +%s)-$$"
    mkdir -p "$coverage_dir"
    if dotnet test "$project_file" --no-restore --filter "Category=Unit" \
        --collect:"XPlat Code Coverage" --results-directory "$coverage_dir" \
        2>&1 | tee "$ROOT_DIR/test-results/csharp-tests.log"; then
        local coverage_file rates line_rate branch_rate
        coverage_file=$(find "$coverage_dir" -name coverage.cobertura.xml -print -quit)
        if [ -z "$coverage_file" ]; then
            log_error "C# coverage report is missing"
            return 1
        fi
        rates=$(sed -n 's/.*line-rate="\([^"]*\)".*branch-rate="\([^"]*\)".*/\1 \2/p' "$coverage_file" | head -1)
        read -r line_rate branch_rate <<< "$rates"
        if ! awk -v lines="$line_rate" -v branches="$branch_rate" 'BEGIN { exit !(lines >= 1 && branches >= 1) }'; then
            log_error "C# line or branch coverage is below 100% (${line_rate:-missing}, ${branch_rate:-missing})"
            return 1
        fi
        log_info "C# tests passed with 100% line and branch coverage"
    else
        log_error "C# tests failed"
        return 1
    fi
}

run_csharp_integration_tests() {
    run_csharp_category_tests Integration
}

run_csharp_e2e_tests() {
    run_csharp_category_tests E2E
}

run_csharp_category_tests() {
    local category="$1"
    local suite
    suite="$(printf '%s' "$category" | tr '[:upper:]' '[:lower:]')"
    local test_dir="$ROOT_DIR/tests/$suite"
    local project_file
    if [ ! -d "$test_dir" ] || ! find "$test_dir" -type f -print -quit | grep -q .; then
        log_error "C# $suite test suite is missing or empty"
        return 1
    fi
    project_file=$(find "$ROOT_DIR" -name "*.Tests.csproj" -print -quit)
    [ -n "$project_file" ] || { log_error "C# test project not found"; return 1; }
    cd "$(dirname "$project_file")" || return 1
    dotnet test "$project_file" --no-restore --filter "Category=$category" \
        2>&1 | tee "$ROOT_DIR/test-results/${suite}-csharp.log"
}

run_csharp_mutation_tests() {
    local project_file
    project_file=$(find "$ROOT_DIR" -name "*.csproj" -print -quit)
    [ -n "$project_file" ] || { log_error "No .csproj file found; cannot run C# mutation tests"; return 1; }
    command -v dotnet >/dev/null || { log_error "dotnet not found; cannot run C# mutation tests"; return 1; }
    cd "$(dirname "$project_file")" || return 1
    dotnet tool restore --tool-manifest .config/dotnet-tools.json
    dotnet stryker 2>&1 | tee "$ROOT_DIR/test-results/mutation-csharp.log"
}

# Основная функция
