---
name: agentmail-cli
description: Send and receive emails programmatically using the AgentMail CLI. Use when agents need to manage inboxes, send/receive emails, handle threads, drafts, webhooks, and domains via command line.
---

# AgentMail CLI

Use the `agentmail` CLI to send and receive emails programmatically. Requires `AGENTMAIL_API_KEY` environment variable.

## Core Commands

### Inboxes

```bash
# List inboxes
agentmail inboxes list

# Get an inbox
agentmail inboxes retrieve --inbox-id <inbox_id>
```

### Send Email

```bash
# Send a message from an inbox
agentmail inboxes:messages send --inbox-id <inbox_id> \
  --to "recipient@example.com" \
  --subject "Hello" \
  --text "Message body"

# Send with HTML
agentmail inboxes:messages send --inbox-id <inbox_id> \
  --to "recipient@example.com" \
  --subject "Hello" \
  --html "<h1>Hello</h1>"

# Reply to a message
agentmail inboxes:messages reply --inbox-id <inbox_id> --message-id <message_id> \
  --text "Reply body"

# Forward a message
agentmail inboxes:messages forward --inbox-id <inbox_id> --message-id <message_id> \
  --to "someone@example.com"
```

### Read Email

```bash
# List messages in an inbox
agentmail inboxes:messages list --inbox-id <inbox_id>

# Get a specific message
agentmail inboxes:messages retrieve --inbox-id <inbox_id> --message-id <message_id>

# List threads
agentmail inboxes:threads list --inbox-id <inbox_id>

# Get a thread
agentmail inboxes:threads retrieve --inbox-id <inbox_id> --thread-id <thread_id>
```

### Drafts

```bash
# Create a draft
agentmail inboxes:drafts create --inbox-id <inbox_id> \
  --to "recipient@example.com" \
  --subject "Draft" \
  --text "Draft body"

# Send a draft
agentmail inboxes:drafts send --inbox-id <inbox_id> --draft-id <draft_id>
```

## Global Flags

All commands support: `--api-key`, `--base-url`, `--environment`, `--format`, `--debug`.

## Output Formats

Use `--format` to control output: `json` (default), `pretty`, `yaml`, `jsonl`, `raw`, `explore`.
