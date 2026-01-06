# Batch Migration Patterns

## The Parallel Curl Pattern

**20 concurrent requests is safe for most Xano instances.**

---

## Basic Batch Script

```bash
echo "Starting migration (pages 1-200)..."
for page in $(seq 1 200); do
  curl -s -X POST 'https://x2nu-xcjc-vhax.agentdashboards.xano.io/api:GROUP_ID/migrate-page' \
    -H 'Content-Type: application/json' \
    -d "{\"page\":$page}" &

  # Wait every 20 requests
  if [ $((page % 20)) -eq 0 ]; then
    wait
    echo "Completed up to page $page"
  fi
done
wait
echo "Migration complete"
```

---

## Running in Background

```bash
# Run in background, capture output
nohup bash migrate.sh > migration.log 2>&1 &

# Monitor progress
tail -f migration.log
```

---

## Claude Code Background Pattern

```javascript
// Launch as background task
Bash({
  command: `echo "Starting migration..."
for page in $(seq 1 500); do
  curl -s -X POST 'https://instance.xano.io/api:GROUP/endpoint' \\
    -H 'Content-Type: application/json' \\
    -d "{\\"page\\":$page}" &
  if [ $((page % 20)) -eq 0 ]; then
    wait
    echo "Completed up to page $page"
  fi
done
wait
echo "MIGRATION COMPLETE"`,
  run_in_background: true,
  timeout: 600000  // 10 minutes
})
```

Check output file periodically:
```bash
tail -20 /tmp/claude/.../tasks/TASK_ID.output
```

---

## Multiple Parallel Batches

For large migrations, run multiple batches simultaneously:

```javascript
// Batch 1: Pages 1-300
Bash({ command: "...", run_in_background: true })

// Batch 2: Pages 301-600
Bash({ command: "...", run_in_background: true })

// Batch 3: Pages 601-925
Bash({ command: "...", run_in_background: true })
```

Each batch runs independently.

---

## Handling Failed Pages

Some pages may fail due to:
- API timeouts
- 502 Bad Gateway
- Transient errors

### Retry Failed Pages Sequentially

```bash
# Run failed pages one at a time with longer timeout
for page in 281 283 285 290; do
  echo "Retrying page $page..."
  curl -s --connect-timeout 10 --max-time 120 \
    -X POST 'https://instance.xano.io/api:GROUP/migrate-page' \
    -H 'Content-Type: application/json' \
    -d "{\"page\":$page}"
  echo ""
  sleep 2  # Small delay between retries
done
```

---

## Monitoring Progress

### Check Task Output

```javascript
TaskOutput({
  task_id: "TASK_ID",
  block: false  // Non-blocking check
})
```

### Quick Progress Check

```bash
tail -5 /tmp/claude/.../tasks/TASK_ID.output
```

### Look for Completion

```bash
grep "COMPLETE" /tmp/claude/.../tasks/TASK_ID.output
```

---

## Example: Real Migration Stats

From actual 1.3M record migration:

| Table | Records | Pages | Time |
|-------|---------|-------|------|
| Network | 82,007 | 165 | ~3 min |
| Participant | 647,798 | 1,296 | ~15 min |
| Paid Participant | 106,658 | 214 | ~5 min |
| Income | 462,251 | 925 | ~12 min |

---

## Error Patterns to Expect

### Transient (Auto-Recover)

```
502 Bad Gateway - Nginx overload, next batch succeeds
{"code":"ERROR_FATAL","message":"Connection lost"} - Retry works
```

### Needs Attention

```
{"code":"ERROR_CODE_NOT_FOUND","message":"Invalid app."} - Wrong instance
{"code":"ERROR_FATAL","message":"Unable to locate var: body.items"} - API timeout, check timeout protection
Duplicate record detected - Page already processed, skip it
```

---

## Safe Concurrency Levels

| Records/Page | Concurrent Requests | Notes |
|--------------|---------------------|-------|
| 100 | 30-50 | Light load |
| 500 | 15-20 | Standard |
| 1000 | 10-15 | Heavy writes |

For db.add in forEach loops, 20 concurrent is usually the sweet spot.
