#!/bin/bash
set -e

# Skill activation hook - suggests relevant skills based on prompt keywords
# Runs on UserPromptSubmit to help users activate the right skills

# Read input from stdin
input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // empty' | tr '[:upper:]' '[:lower:]')

if [[ -z "$prompt" ]]; then
    exit 0
fi

# Find skill-rules.json - check plugin root first, then project
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

rules_file=""
if [[ -n "$PLUGIN_ROOT" ]] && [[ -f "$PLUGIN_ROOT/../xano-sdk-builder/skill-rules.json" ]]; then
    rules_file="$PLUGIN_ROOT/../xano-sdk-builder/skill-rules.json"
elif [[ -f "$PROJECT_DIR/.claude/skill-rules.json" ]]; then
    rules_file="$PROJECT_DIR/.claude/skill-rules.json"
else
    exit 0
fi

# Simple keyword matching (no jq iteration for performance)
matched_skills=""

# Check xano-sdk-builder keywords
if echo "$prompt" | grep -qiE "(xano|xanoscript|endpoint|sdk_builder|db\.query|db\.add|api\.request|curl test|batch migration)"; then
    matched_skills="${matched_skills}xano-sdk-builder (CRITICAL)\n"
fi

# Check frontend-dev-guidelines keywords
if echo "$prompt" | grep -qiE "(react|component|typescript|shadcn|tailwind|tanstack|suspense|useSWR|next\.?js)"; then
    matched_skills="${matched_skills}frontend-dev-guidelines\n"
fi

# Check playwright-testing keywords
if echo "$prompt" | grep -qiE "(playwright|e2e|browser test|screenshot|browser automation)"; then
    matched_skills="${matched_skills}playwright-testing\n"
fi

# Check skill-builder keywords
if echo "$prompt" | grep -qiE "(create skill|new skill|build skill|add skill|skill template|showcase pattern|500-line rule|progressive disclosure)"; then
    matched_skills="${matched_skills}skill-builder\n"
fi

# Check skill-developer keywords
if echo "$prompt" | grep -qiE "(skill-rules\.json|skill rules|trigger patterns|hook mechanisms|UserPromptSubmit|PreToolUse|enforcement level|skill activation|YAML frontmatter)"; then
    matched_skills="${matched_skills}skill-developer\n"
fi

# Output if matches found
if [[ -n "$matched_skills" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 SKILL ACTIVATION CHECK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📚 RECOMMENDED SKILLS:"
    echo -e "$matched_skills" | while read -r skill; do
        if [[ -n "$skill" ]]; then
            echo "  → $skill"
        fi
    done
    echo ""
    echo "ACTION: Use Skill tool BEFORE responding"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

exit 0
