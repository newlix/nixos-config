# CLAUDE.md — agent-optimized coding rules

## Agent behavior

- **Default to action.** When ambiguity exists, pick the most reasonable option and execute. Do not ask for confirmation on obvious next steps; being corrected after the fact costs less than stopping to ask.
- **Post-hoc ambiguity summary.** After completing work, briefly list any ambiguous decisions made — which option was chosen and why. This is a summary, not a pre-action confirmation.
- **Phase commits.** Commit after each todo phase completes. Commit messages include the post-hoc ambiguity summary for that phase.

## Coding rules

Each rule answers one question the agent faces daily. Format: ❌ what NOT to do → ✅ what to do → WHY it matters to the agent.

---

## 1 — No overloading. Signatures tell the truth. One name = one signature.

**Go**

```go
// ❌ interface{} param with type-switch — agent must read the body
func handleEvent(event interface{}) error

// ✅ concrete types, distinct names
func handleOrderEvent(event OrderEvent) error
```

**TypeScript**

```typescript
// ❌ union param — agent must narrow at every call site
function lookup(id: string | number): User | null

// ❌ same name, different arity — agent must disambiguate
export function resetTables(db: D1Database): Promise<void>
export const resetTables = () => resetTables(cf.DB)

// ✅ distinct names, concrete types
function lookupById(id: string): User | null
function lookupByIndex(idx: number): User | null
export function resetTables(db: D1Database): Promise<void>   // canonical
export const clearTables = () => resetTables(cf.DB)           // fixture
```

**Swift**

```swift
// ❌ Any with type-cast — agent must read the body
func handle(_ event: Any) throws

// ❌ overloaded by type — same name, different param types
func lookup(_ id: String) -> User?
func lookup(_ index: Int) -> User?

// ✅ concrete types, distinct names
func handleOrderEvent(_ event: OrderEvent) throws
func lookupById(_ id: String) -> User?
func lookupByIndex(_ index: Int) -> User?
```

**Kotlin**

```kotlin
// ❌ implicit return type — agent must read the body to know command vs query
fun toggleFavorite(asset: Asset)

// ✅ explicit return type — agent knows it's a command (Unit) or query (User?)
fun toggleFavorite(asset: Asset): Unit
fun findUser(id: String): User?
```

**Not violations** (have `|` / `Any` / `Optional` / implicit return but caller doesn't need to narrow):
Go: `interface{}` in generic helpers with no type-switch.
TS: `Error | null` return (Go-style), `T | null` ORM not-found, `field?: string | null | undefined` DB columns.
Swift: `Optional<T>`, `Result<T, Error>`, `enum` with associated values.
Kotlin: `private fun` helpers, `override fun`, single-expression `= ...` bodies whose return type is obvious from the expression.

The import path is the namespace — NEVER repeat it in the symbol name.
`import { resetTables } from "@totality/db/src/test-utils"` — not `resetD1Tables`.

## 2 — One source of truth. NEVER copy-paste within the repo.

Before writing a helper, check: does it already exist? If 2+ files have the same logic, extract it NOW.
Only one canonical location per concept.

## 3 — Side effects MUST be visible at the call site.

```go
// ❌ agent can't know what this touches without reading the body
user.Save()

// ✅ every side effect is explicit in the signature
result, err := db.InsertUser(ctx, user)
if err != nil { return err }
```

Return errors as values. NEVER throw for business logic.
NEVER hide DB/HTTP/IO in decorators, proxies, or implicit middleware.

## 4 — Fail loud.

```go
// ❌ swallowed — agent thinks it succeeded
if err := step(); err != nil { _ = err }

// ✅ surfaced — agent knows what happened
if err := step(); err != nil { return fmt.Errorf("step: %w", err) }
```

"Done" = nothing skipped. "Tests pass" = every test ran. Default to surfacing uncertainty.
