#!/bin/zsh
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$project_dir/.build/checks"
mkdir -p "$output_dir"

source_files=(
  "$project_dir"/Sources/MotivationNote/Models/*.swift(N)
  "$project_dir"/Sources/MotivationNote/Persistence/*.swift(N)
  "$project_dir"/Sources/MotivationNote/State/*.swift(N)
)

for check_file in "$project_dir"/Tests/Checks/*Checks.swift(N); do
  check_name="${check_file:t:r}"
  output="$output_dir/$check_name"
  swiftc -parse-as-library \
    "${source_files[@]}" \
    "$project_dir/Tests/Checks/CheckSupport.swift" \
    "$check_file" \
    -o "$output"
  "$output"
done
