#!/bin/bash
set -e

# Stop event hook that runs TypeScript build checks
# Runs when Claude Code finishes responding - catches errors early

# Read event information from stdin
event_info=$(cat)

# Extract session ID
session_id=$(echo "$event_info" | jq -r '.session_id // empty')

# Cache directory in project
cache_dir="$CLAUDE_PROJECT_DIR/.claude/tsc-cache/${session_id:-default}"

# Check if cache exists
if [[ ! -d "$cache_dir" ]]; then
    exit 0
fi

# Check if any repos were edited
if [[ ! -f "$cache_dir/affected-repos.txt" ]]; then
    exit 0
fi

# Create results directory
results_dir="$cache_dir/results"
mkdir -p "$results_dir"

# Initialize error tracking
total_errors=0
has_errors=false

# Function to count TypeScript errors
count_tsc_errors() {
    local output="$1"
    echo "$output" | grep -E "\.tsx?.*:.*error TS[0-9]+:" | wc -l | tr -d ' '
}

# Clear any previous error summary
> "$results_dir/error-summary.txt"

# Read affected repos and run TSC checks
while IFS= read -r repo; do
    # Get TSC command for this repo
    tsc_cmd=$(grep "^$repo:tsc:" "$cache_dir/commands.txt" 2>/dev/null | cut -d':' -f3-)

    if [[ -z "$tsc_cmd" ]]; then
        continue
    fi

    # Run TSC and capture output
    if ! output=$(eval "$tsc_cmd" 2>&1); then
        has_errors=true

        # Count errors
        error_count=$(count_tsc_errors "$output")
        total_errors=$((total_errors + error_count))

        # Save error output
        echo "$output" > "$results_dir/$repo-errors.txt"
        echo "$repo:$error_count" >> "$results_dir/error-summary.txt"
    else
        echo "$repo:0" >> "$results_dir/error-summary.txt"
    fi
done < "$cache_dir/affected-repos.txt"

# If we have errors, report them
if [[ "$has_errors" == "true" ]]; then
    # Combine all errors
    > "$cache_dir/last-errors.txt"
    for error_file in "$results_dir"/*-errors.txt; do
        if [[ -f "$error_file" ]]; then
            repo_name=$(basename "$error_file" -errors.txt)
            echo "=== Errors in $repo_name ===" >> "$cache_dir/last-errors.txt"
            cat "$error_file" >> "$cache_dir/last-errors.txt"
            echo "" >> "$cache_dir/last-errors.txt"
        fi
    done

    # Format message for Claude
    echo "" >&2
    echo "## TypeScript Build Errors Detected" >&2
    echo "" >&2
    echo "Found $total_errors TypeScript error(s):" >&2

    while IFS=':' read -r repo count; do
        if [[ $count -gt 0 ]]; then
            echo "- $repo: $count errors" >&2
        fi
    done < "$results_dir/error-summary.txt"

    echo "" >&2

    if [[ $total_errors -lt 5 ]]; then
        # Show errors inline for small counts
        echo "Error details:" >&2
        cat "$cache_dir/last-errors.txt" | head -50 | sed 's/^/  /' >&2
        echo "" >&2
        echo "Please fix these errors in the affected files." >&2
    else
        echo "Run \`tsc --noEmit\` to see full error details." >&2
        echo "Consider using the auto-error-resolver agent for bulk fixes." >&2
    fi

    # Exit with status 2 to send feedback to Claude
    exit 2
else
    # Clean up on success
    rm -rf "$cache_dir"
    exit 0
fi
