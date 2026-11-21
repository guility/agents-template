#!/bin/bash
# Git hook setup.

# Подключение обязательных локальных hooks.
install_git_hooks() {
    log_step "Installing Git hooks..."
    
    if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        log_warn "Not a git repository, skipping hook installation"
        return 0
    fi
    
    chmod +x "$PROJECT_ROOT/.hooks/pre-commit" "$PROJECT_ROOT/.hooks/pre-push"
    git -C "$PROJECT_ROOT" config core.hooksPath .hooks
    log_info "pre-commit and pre-push hooks enabled"
}
