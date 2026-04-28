---
description: "Standards for logging, monitoring, and debugging output."
---

### OBSERVABILITY PROTOCOL [THE EYE]

> Defines trace schema, monitoring metrics, and log structure for all agent actions.

#### 1. Trace Schema

Every agent action MUST emit a trace:

```json
{
  "trace_id": "tr_<uuid>",
  "span_id": "sp_<uuid>",
  "parent_span_id": "sp_<uuid>|null",
  "agent": "MANAGER|ARCHITECT|ENGINEER|...",
  "action": "route|read|write|execute|search",
  "timestamp": "ISO8601",
  "duration_ms": 1234,
  "tokens": {"input": 1000, "output": 500, "thinking": 200},
  "cost_usd": 0.0015,
  "status": "success|error|timeout",
  "metadata": {}
}
```

Span hierarchy: `MANAGER.route (root) → ENGINEER.execute → Read/Write/VALIDATOR.verify`

#### 1.1 Boot Cost Counter (V7.7 — Advisory Telemetry)

MANAGER SHOULD emit a `boot_cost_tokens` counter in every Tier 1 JSON, estimating the token overhead of the current turn's boot sequence (Phase 0 checks, skill resolution, routing JSON, system file reads):

```json
{
  "routing_agent": "MANAGER",
  "...",
  "boot_cost_tokens": 4820
}
```

This field is **advisory** — omission is NOT a Law 1 violation. It enables regression detection: if median boot cost drifts above 10K tokens across 20 consecutive turns, V7.1–V7.5 optimizations should be tightened. Remediation remains a human judgment call, not an automated gate.

#### 2. Monitoring Metrics

**Performance:** `latency_p50` >10s | `latency_p95` >30s | `latency_p99` >60s | `throughput` <1 rpm → alert.
**Tokens:** `tokens_per_request` >50K | `tokens_session_total` >500K | `cache_hit_rate` <50% → alert.
**Cost:** `cost_per_request` >$1.00 | `cost_session_total` >$10.00 | `cost_daily_total` >$50.00 → alert.
**Errors:** `error_rate` >5% | `timeout_rate` >2% | `retry_rate` >10% → alert.

#### 3. Log Structure

| Level   | Use Case          | Retention    |
| :------ | :---------------- | :----------- |
| `DEBUG` | Dev tracing       | Session only |
| `INFO`  | Normal operations | 7 days       |
| `WARN`  | Potential issues  | 30 days      |
| `ERROR` | Failures          | 90 days      |

```json
{"level": "INFO", "timestamp": "ISO8601", "trace_id": "tr_abc123", "agent": "ENGINEER", "action": "write_file", "message": "...", "metadata": {}}
```

#### 4. OpenTelemetry Environment Variables

Claude Code emits OTel traces, metrics, and logs when the following env vars are set. All supported surfaces (CLI, VS Code extension, JetBrains plugin) share the same wire protocol and source env vars from the login shell.

**Required env vars:**

```bash
CLAUDE_CODE_ENABLE_TELEMETRY=1
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

##### Cross-Surface Env Var Parity

| Surface | Env source | Setup |
| :--- | :--- | :--- |
| CLI (zsh/bash) | Reads shell env directly from `~/.zshrc` / `~/.bashrc` | `export` lines in shell rc |
| VS Code extension | Inherits parent shell env when launched from a terminal session | No extra setup if VS Code launched via `code` from a login shell |
| JetBrains plugin | Inherits parent shell env when IDE launched from terminal | No extra setup if JetBrains launched via CLI from a login shell |

### ALERTING & EXPORT AUTHORITY

> Defines alert severity tiers and OpenTelemetry export targets for operational governance.

#### 4. Alerting Rules

**Critical (Immediate):** Error rate >10% for 5min | latency p99 >120s | cost >$5.00/req | security violation.
**Warning (Batched):** Error rate >5% for 15min | latency p95 >30s | session tokens >400K | cache hit <30%.
**Info (Daily):** Cost summary | agent utilization | top errors.

### PRIVACY & RETENTION AUDIT

> Validation rules for data masking, retention enforcement, and compliance with Law 6 (Secret Sanitization).

#### 5. Privacy & Security

- API keys: `sk-...****` | Passwords: `[REDACTED]` | PII: Hash or mask.

**Retention:** Traces 7d | Logs 30d | Metrics 90d | Errors 90d.
