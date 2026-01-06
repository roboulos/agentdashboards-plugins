#!/bin/bash
set -e

# Post-tool-use hook that tracks edited files and their repos
# This runs after Edit, MultiEdit, or Write tools complete successfully

# Read tool information from stdin
tool_info=$(cat)

# Extract relevant data
tool_name=$(echo "$tool_info" | jq -r '.tool_name // empty')
file_path=$(echo "$tool_info" | jq -r '.tool_input.file_path // empty')
session_id=$(echo "$tool_info" | jq -r '.session_id // empty')

# Skip if not an edit tool or no file path
if [[ ! "$tool_name" =~ ^(Edit|MultiEdit|Write)$ ]] || [[ -z "$file_path" ]]; then
    exit 0
fi

# Skip markdown files
if [[ "$file_path" =~ \.(md|markdown)$ ]]; then
    exit 0
fi

# Create cache directory in project
cache_dir="$CLAUDE_PROJECT_DIR/.claude/tsc-cache/${session_id:-default}"
mkdir -p "$cache_dir"

# Function to detect repo from file path
detect_repo() {
    local file="$1"
    local project_root="$CLAUDE_PROJECT_DIR"

    # Remove project root from path
    local relative_path="${file#$project_root/}"

    # Extract first directory component
    local repo=$(echo "$relative_path" | cut -d'/' -f1)

    # Common project directory patterns
    case "$repo" in
        frontend|client|web|app|ui|src|components|pages)
            echo "$repo"
            ;;
        backend|server|api|services)
            echo "$repo"
            ;;
        database|prisma|migrations)
            echo "$repo"
            ;;
        packages)
            local package=$(echo "$relative_path" | cut -d'/' -f2)
            if [[ -n "$package" ]]; then
                echo "packages/$package"
            else
                echo "$repo"
            fi
            ;;
        *)
            if [[ ! "$relative_path" =~ / ]]; then
                echo "root"
            else
                echo "$repo"
            fi
            ;;
    esac
}

# Function to get TSC command for repo
get_tsc_command() {
    local repo="$1"
    local project_root="$CLAUDE_PROJECT_DIR"
    local repo_path="$project_root/$repo"

    # For root, check project root
    if [[ "$repo" == "root" ]]; then
        repo_path="$project_root"
    fi

    # Check if tsconfig.json exists
    if [[ -f "$repo_path/tsconfig.json" ]]; then
        if [[ -f "$repo_path/tsconfig.app.json" ]]; then
            echo "cd $repo_path && npx tsc --project tsconfig.app.json --noEmit"
        else
            echo "cd $repo_path && npx tsc --noEmit"
        fi
        return
    fi

    # Check project root as fallback
    if [[ -f "$project_root/tsconfig.json" ]]; then
        echo "cd $project_root && npx tsc --noEmit"
        return
    fi

    echo ""
}

# Detect repo
repo=$(detect_repo "$file_path")

# Skip if unknown
if [[ -z "$repo" ]]; then
    exit 0
fi

# Log edited file
echo "$(date +%s):$file_path:$repo" >> "$cache_dir/edited-files.log"

# Update affected repos list
if ! grep -q "^$repo$" "$cache_dir/affected-repos.txt" 2>/dev/null; then
    echo "$repo" >> "$cache_dir/affected-repos.txt"
fi

# Store TSC command
tsc_cmd=$(get_tsc_command "$repo")

if [[ -n "$tsc_cmd" ]]; then
    echo "$repo:tsc:$tsc_cmd" >> "$cache_dir/commands.txt.tmp"
fi

# Remove duplicates
if [[ -f "$cache_dir/commands.txt.tmp" ]]; then
    sort -u "$cache_dir/commands.txt.tmp" > "$cache_dir/commands.txt"
    rm -f "$cache_dir/commands.txt.tmp"
fi

exit 0
