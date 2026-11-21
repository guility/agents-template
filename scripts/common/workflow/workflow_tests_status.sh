print_test_status() {
    local implemented_count="$1"
    local tests_dir="./src/tests"
    echo ""
    echo "=== Этап 3: Тесты ==="
    if [[ -d "$tests_dir" ]]; then
        local unit_count integration_count e2e_count
        unit_count=$(find "$tests_dir/unit" -type f 2>/dev/null | wc -l)
        integration_count=$(find "$tests_dir/integration" -type f 2>/dev/null | wc -l)
        e2e_count=$(find "$tests_dir/e2e" -type f 2>/dev/null | wc -l)
        echo "  Unit тестов: $unit_count"
        echo "  Integration тестов: $integration_count"
        echo "  E2E тестов: $e2e_count"
        if [[ "$implemented_count" -gt 0 && "$unit_count" -eq 0 ]]; then
            echo "  ⚠️  Есть реализованные требования, но нет unit тестов"
        fi
    else
        echo "  ⚠️  Директория тестов не найдена"
    fi
    echo ""
    echo "=== Этап 4: Проверка покрытия мутационными тестами ==="
    local mutation_dir="$tests_dir/mutation"
    if [[ -d "$mutation_dir" ]]; then
        echo "  Мутационных тестов: $(find "$mutation_dir" -type f 2>/dev/null | wc -l)"
    else
        echo "  ℹ️  Директория мутационных тестов не найдена (будет создана при необходимости)"
    fi
}
