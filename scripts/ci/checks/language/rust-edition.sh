rust_edition() {
  local manifest="$1" edition directory
  edition="$(awk '
    /^\[package\][[:space:]]*$/ { section="package"; next }
    /^\[/ { section="" }
    section == "package" && /^[[:space:]]*edition[[:space:]]*=/ {
      sub(/#.*/, ""); sub(/^[^=]*=[[:space:]]*/, ""); gsub(/["[:space:]]/, ""); print; exit
    }
  ' "$manifest")"
  directory="$(dirname "$manifest")"
  while [[ -z "$edition" && ( "$directory" == "$root" || "$directory" == "$root/"* ) ]]; do
    edition="$(awk '
      /^\[workspace\.package\][[:space:]]*$/ { section="workspace"; next }
      /^\[/ { section="" }
      section == "workspace" && /^[[:space:]]*edition[[:space:]]*=/ {
        sub(/#.*/, ""); sub(/^[^=]*=[[:space:]]*/, ""); gsub(/["[:space:]]/, ""); print; exit
      }
    ' "$directory/Cargo.toml" 2>/dev/null || true)"
    [[ -n "$edition" || "$directory" == "$root" ]] || directory="$(dirname "$directory")"
  done
  printf '%s' "${edition:-2015}"
}
