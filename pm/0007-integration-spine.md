# 0007 — Integration spine (ports + adapters + Operation runtime)

## Goal

Build the framework between brain and the outside world. Every external interaction (certification, invoicing, bank sync, email delivery, folder sync, notifications) goes through:

```
App code → Port (abstract interface) → Adapter (concrete impl) ← Dispatcher (boundary, assertion-checked) ← OperationJob (Solid Queue) ← Operation (persistent row)
```

The framework ships with **Null adapters** for every port (synthetic results, no I/O). Real adapters (Holded, Verifacti, Postmark, …) are added milestone-by-milestone by binding to the same ports without touching app code.

## Why this shape

- **Pluggability.** Holded is one possible provider, not THE provider. Swap one line of config to change.
- **Auditability.** Every external interaction is a persistent `Operation` row — replayable, observable, attributable to a `correlation_id`.
- **TigerStyle safety.** Operations have a fixed `max_attempts` bound. Dispatcher and Adapter assertions are paired (two code paths for every property — port boundary AND adapter internal). Status transitions are explicit (`pending → running → succeeded | failed | aborted`); illegal transitions raise.
- **Restartability.** Workers are Solid Queue's stoppable loops; jobs are persistent; in-flight work resumes after a SIGTERM. Operations in `running` at restart are detectable via `started_at` and a sweeper (future milestone) can mark them `failed` for retry.

## What "TigerStyle" means here

Adapted from TigerBeetle's NASA-10-style rules:

| Rule | How it shows up |
|------|-----------------|
| §2 Bounded loops/queues | `Operation.max_attempts` mandatory, default 5. Solid Queue retries are double-bounded by the gem. |
| §4 Assertions are a force multiplier | `Port.assert_input!` and `Port.assert_output!` run **twice**: in the Dispatcher (boundary) and indirectly via `Adapter::Base#call` (internal). Paired. |
| §7 70-line functions | Every method in the runtime stays under 30 lines. Helpers split logic clearly. |
| §9 Don't react directly to external events | App code never calls vendors. Inbound webhooks (later) translate to Operations; outbound work goes through Operations. |
| §10 Handle all errors | Dispatcher's `rescue StandardError` records to `operation.error` and decides retry vs abort. No silent failures. |
| §11 Split compound conditions | State machine in `Operation` uses one explicit check per branch. |
| §13 Always say why | Code comments explain the *why* (rationale, invariant), not the *what*. |

## Schema

```
operations
├── id
├── kind             string   NOT NULL    # certify_receipt | issue_invoice | send_notification | sync_bank_transactions | deliver_inbound_document | sync_folder
├── status           string   NOT NULL    # pending | running | succeeded | failed | aborted
├── attempt_count    int      NOT NULL  default 0
├── max_attempts     int      NOT NULL  default 5
├── adapter_name     string   NOT NULL                # concrete adapter class name; mismatch ⇒ assertion failure
├── correlation_id   string                            # links to the upstream entity (e.g. "Receipt:42")
├── input            json     NOT NULL  default '{}'  # frozen at enqueue; never mutated
├── output           json                              # set on success
├── error            text                              # last error message; truncated
├── started_at       datetime
├── completed_at     datetime
├── timestamps
└── indexes: [kind, status]; [status, attempt_count]; correlation_id
```

## Layout

```
app/
├── models/
│   └── operation.rb              # AR model + state machine + asserted transitions
├── ports/
│   ├── receipt_certifier.rb      # demonstrated this milestone
│   └── notifier.rb               # demonstrated this milestone
├── adapters/
│   ├── base.rb                   # template: assert in → _perform → assert out
│   └── null/
│       ├── receipt_certifier.rb
│       └── notifier.rb
└── runtime/
    ├── assert.rb                 # shape!(value, expected, where:)
    ├── dispatcher.rb             # routes Operation → Adapter; asserts boundaries
    └── operation_job.rb          # ActiveJob; thin wrapper around Dispatcher
config/initializers/
└── runtime.rb                    # default bindings (all Null in this milestone)
```

## What ships in this milestone

Two ports are wired end-to-end as proof of the pattern. Other ports get added by their owning feature milestones.

- [ ] `operations` table + `Operation` model with state machine. Illegal transitions raise `Runtime::AssertionError`.
- [ ] `Port::ReceiptCertifier` + `Port::Notifier` with `INPUT_SHAPE` / `OUTPUT_SHAPE` constants and `assert_input!` / `assert_output!` class methods (delegating to `Runtime::Assert.shape!`).
- [ ] `Adapter::Base` enforces the three-step protocol: assert input → `_perform` → assert output.
- [ ] `Adapter::Null::ReceiptCertifier` and `Adapter::Null::Notifier` — synthetic outputs, deterministic where useful (seeded SecureRandom in tests).
- [ ] `Runtime::Dispatcher.call(operation)` — resolves port → adapter, asserts mismatch, drives transitions, paired assertions on input/output.
- [ ] `Runtime::OperationJob` — Solid Queue job. Re-raises non-terminal failures so the queue retries.
- [ ] `config/initializers/runtime.rb` binds every known port to its Null adapter by default.
- [ ] Tests cover: model transitions (positive + negative space), Dispatcher happy path, Dispatcher failure → retry → abort after `max_attempts`, port input/output assertions catching bad data, adapter binding mismatch detection, OperationJob retry semantics.
- [ ] `bin/ci` green.

## Out of scope (deliberately)

- A UI for viewing Operations (could come in 0012 needs-review or as its own milestone).
- A sweeper for crash-recovery of `running` operations (add when we observe one).
- Real provider adapters (Holded etc. — milestone 0013).
- Wiring the spine into ReceiptsController / capture flow — that becomes natural when a port the capture flow needs ships (cert in 0013, notifier in 0011).

## Steps

1. Migration + `Operation` model + tests. → verify: `bin/rails test test/models/operation_test.rb`.
2. `Runtime::Assert.shape!` helper + test. → verify: `bin/rails test test/runtime/`.
3. `Port::ReceiptCertifier`, `Port::Notifier` modules. → verify: port test.
4. `Adapter::Base` + `Adapter::Null::*` for both ports. → verify: adapter test (assert wraps work).
5. `Runtime::Dispatcher` + tests for happy path, failure path, mismatched adapter, paired assertions.
6. `Runtime::OperationJob` + integration test for re-raise on failure / no re-raise on abort.
7. `config/initializers/runtime.rb` binds both ports to their Null adapters.
8. `bin/ci` → exit 0.
9. Commit.

## Notes

- We don't introduce a third-party schema-validation gem. `Runtime::Assert.shape!` is ~15 lines.
- Operation.input is **frozen** semantically: never mutate after enqueue. The dispatcher passes `operation.input.deep_dup` to the adapter to guarantee this.
- Operation.adapter_name is recorded at enqueue time, asserted to still match the live binding at dispatch time. A binding change after enqueue surfaces as a hard error, not silently uses the new adapter.
- Naming follows TigerStyle: snake_case methods, no abbreviations. `assert_input!` / `assert_output!` (bang for raising), `_perform` (private hook), `correlation_id` over `corr_id`.
