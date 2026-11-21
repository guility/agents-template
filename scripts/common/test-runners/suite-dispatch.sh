run_requested_suite() {
    local suite="$1"
    local has_python="$2"
    local has_nodejs="$3"
    local has_rust="$4"
    local has_go="$5"
    local has_csharp="$6"
    local exit_code=0

    case "$suite" in
        all)
            if [ "$has_python" = true ]; then
                run_python_unit_tests || exit_code=1
                run_python_integration_tests || exit_code=1
                run_python_e2e_tests || exit_code=1
                run_python_mutation_tests || exit_code=1
            fi
            if [ "$has_nodejs" = true ]; then
                run_nodejs_unit_tests || exit_code=1
                run_nodejs_integration_tests || exit_code=1
                run_nodejs_e2e_tests || exit_code=1
                run_nodejs_mutation_tests || exit_code=1
            fi
            if [ "$has_rust" = true ]; then
                run_rust_tests || exit_code=1
                run_rust_integration_tests || exit_code=1
                run_rust_e2e_tests || exit_code=1
                run_rust_mutation_tests || exit_code=1
            fi
            if [ "$has_go" = true ]; then
                run_go_tests || exit_code=1
                run_go_integration_tests || exit_code=1
                run_go_e2e_tests || exit_code=1
                run_go_mutation_tests || exit_code=1
            fi
            if [ "$has_csharp" = true ]; then
                run_csharp_tests || exit_code=1
                run_csharp_integration_tests || exit_code=1
                run_csharp_e2e_tests || exit_code=1
                run_csharp_mutation_tests || exit_code=1
            fi
            ;;
        post-merge)
            local runner_count=0
            if [ "$has_python" = true ]; then
                run_python_integration_tests || exit_code=1
                run_python_e2e_tests || exit_code=1
                run_python_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_nodejs" = true ]; then
                run_nodejs_integration_tests || exit_code=1
                run_nodejs_e2e_tests || exit_code=1
                run_nodejs_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_rust" = true ]; then
                run_rust_integration_tests || exit_code=1
                run_rust_e2e_tests || exit_code=1
                run_rust_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_go" = true ]; then
                run_go_integration_tests || exit_code=1
                run_go_e2e_tests || exit_code=1
                run_go_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_csharp" = true ]; then
                run_csharp_integration_tests || exit_code=1
                run_csharp_e2e_tests || exit_code=1
                run_csharp_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            [ "$runner_count" -gt 0 ] || { log_error "No post-merge test runner is configured"; return 1; }
            ;;
        unit)
            [ "$has_python" != true ] || run_python_unit_tests || exit_code=1
            [ "$has_nodejs" != true ] || run_nodejs_unit_tests || exit_code=1
            [ "$has_rust" != true ] || run_rust_tests || exit_code=1
            [ "$has_go" != true ] || run_go_tests || exit_code=1
            [ "$has_csharp" != true ] || run_csharp_tests || exit_code=1
            ;;
        integration)
            local runner_count=0
            if [ "$has_python" = true ]; then
                run_python_integration_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_nodejs" = true ]; then
                run_nodejs_integration_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_rust" = true ]; then
                run_rust_integration_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_go" = true ]; then
                run_go_integration_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_csharp" = true ]; then
                run_csharp_integration_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            [ "$runner_count" -gt 0 ] || { log_error "No integration test runner is configured"; return 1; }
            ;;
        e2e)
            local runner_count=0
            if [ "$has_python" = true ]; then
                run_python_e2e_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_nodejs" = true ]; then
                run_nodejs_e2e_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_rust" = true ]; then
                run_rust_e2e_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_go" = true ]; then
                run_go_e2e_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_csharp" = true ]; then
                run_csharp_e2e_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            [ "$runner_count" -gt 0 ] || { log_error "No e2e test runner is configured"; return 1; }
            ;;
        mutation)
            local runner_count=0
            if [ "$has_python" = true ]; then
                run_python_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_nodejs" = true ]; then
                run_nodejs_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_rust" = true ]; then
                run_rust_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_go" = true ]; then
                run_go_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            if [ "$has_csharp" = true ]; then
                run_csharp_mutation_tests || exit_code=1
                runner_count=$((runner_count + 1))
            fi
            [ "$runner_count" -gt 0 ] || { log_error "No mutation test runner is configured"; return 1; }
            ;;
        *)
            log_error "Unknown test suite: $suite"
            return 2
            ;;
    esac

    return "$exit_code"
}
