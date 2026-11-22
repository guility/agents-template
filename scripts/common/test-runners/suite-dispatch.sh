select_languages() {
    local -n selected="$1"
    shift
    local -a names=(python nodejs rust go csharp)
    local -a flags=("$@")
    local index
    for index in "${!names[@]}"; do
        if [[ "${flags[$index]}" == true ]]; then
            selected+=("${names[$index]}")
        fi
    done
}

run_language_suite() {
    local language="$1" suite="$2"
    local runner="run_${language}_${suite}_tests"
    if [[ "$suite" == unit ]]; then
        case "$language" in
            rust|go|csharp) runner="run_${language}_tests" ;;
        esac
    fi
    "$runner"
}

run_for_languages() {
    local suite="$1" exit_code=0 language
    shift
    for language in "$@"; do
        run_language_suite "$language" "$suite" || exit_code=1
    done
    return "$exit_code"
}

run_suite_matrix() {
    local suite_list_name="$1" exit_code=0 language suite
    local -n suites="$suite_list_name"
    shift
    for language in "$@"; do
        for suite in "${suites[@]}"; do
            run_language_suite "$language" "$suite" || exit_code=1
        done
    done
    return "$exit_code"
}

run_required_suite() {
    local suite="$1" error="$2"
    shift 2
    if [[ "$#" -eq 0 ]]; then
        log_error "$error"
        return 1
    fi
    run_for_languages "$suite" "$@"
}

run_requested_suite() {
    local suite="$1"
    shift
    local -a languages=() all_suites=(unit integration e2e mutation)
    local -a post_merge_suites=(integration e2e mutation)
    select_languages languages "$@"
    case "$suite" in
        all) run_suite_matrix all_suites "${languages[@]}" ;;
        post-merge) run_suite_matrix post_merge_suites "${languages[@]}" ;;
        unit) run_for_languages unit "${languages[@]}" ;;
        integration) run_required_suite integration "No integration test runner is configured" "${languages[@]}" ;;
        e2e) run_required_suite e2e "No e2e test runner is configured" "${languages[@]}" ;;
        mutation) run_required_suite mutation "No mutation test runner is configured" "${languages[@]}" ;;
        *) log_error "Unknown test suite: $suite"; return 2 ;;
    esac
}
