# Coding Conventions Skill

When reviewing or writing code, enforce the following coding conventions. The primary goal is to make code **intuitive** — a reader's first impression of what a variable, function, or component does should be correct.

---

## Naming

### Avoid generic nouns
Do not use vague, non-descriptive names. Reject names like: `data`, `info`, `result`, `payload`, `item`, `entity`, `manifest`. Every name should communicate its specific purpose.

### Name length proportional to scope
- Short-lived variables in small scopes (e.g., loop bodies) should have short names.
- Variables used across many lines of code should have longer, descriptive names.

```go
// Good: short scope, short name
for p := range people {
    greetPerson(p)
}

// Good: long scope, descriptive name
oldestPerson := getOldestPerson(people)
/* 100 lines of code */
greetPerson(oldestPerson)
```

### Pluralize collection types
All references to collections (maps, lists, slices, arrays) must be pluralized.

```go
// Bad
user := []User{}
greetUser(user)

// Good
users := []User{}
greetUsers(users)
```

### Go-specific naming
- **Interfaces**: Prefer `-er` suffix (e.g., `Reader`, `Writer`, `Formatter`).
- **Static errors**: Prefix with `Err` (e.g., `ErrNotFound`).
- **Custom error types**: Suffix with `Error` (e.g., `ConnectionError`, not `ConnectionFailure`).

---

## Functions

### Name describes _what_, not _how_
Function names must describe the outcome, not the implementation. Implementation details are irrelevant to callers and can change.

```go
// Bad: exposes implementation detail
func (s *Store) AddUserToMap(user User) {}

// Good: describes the action
func (s *Store) AddUser(user User) {}
```

### Only accept what you need
Avoid accepting large compound types when only one or two fields are used. Accept the specific values needed — it makes the function easier to test and reason about.

```go
// Bad: accepts entire struct but only uses one field
func CanRentCar(person Person) bool {
    return person.Age >= MinRentalAgeYears
}

// Good: accepts only what is needed
func CanRentCar(ageYears int) bool {
    return ageYears >= MinRentalAgeYears
}
```

**Exception**: The full type is required to satisfy an interface.

### Prefer pure functions
Prefer pure functions over methods. They are easier to test, easier to reason about, and avoid concerns about concurrent mutations.

```go
// Avoid: method on receiver
func (p Person) CanRentCar() bool {
    return p.AgeYears >= MinRentalAgeYears
}

// Prefer: pure function
func CanRentCar(ageYears int) bool {
    return ageYears >= MinRentalAgeYears
}
```

---

## Logging

### Use structured logs
Use structured logging to avoid string interpolation in log messages. Structured messages produce a finite, searchable set of log statements.

```go
// Bad: interpolated message
logger.Infof("Adding user %s to account %d", user.ID, account.ID)

// Good: structured fields
logger.Info("Adding user to account", zap.String("user", user.ID), zap.Int("account", account.ID))
```

**Exception**: Debug/trace level logs may use interpolation for readability.

### ERROR level is for actionable events only
Use ERROR only when immediate action is required. Use WARN for non-exceptional errors like validation failures.

```go
// Bad: validation is normal control flow, not an error
if err := validateUser(user); err != nil {
    logger.Error("User validation failed", zap.Error(err))
}

// Good: database failure requires attention
if err := insertUser(user); err != nil {
    logger.Error("Failed to insert user in database", zap.Error(err))
}
```

### Avoid over-logging
Do not log at every step. Log at meaningful boundaries — entry points, error conditions, and state transitions.

### Provide context in logs
Log messages must say what happened, why, and how the system will react. Do not assume the reader knows the surrounding code.

```
// Bad
{"message": "database error", "error": "deadline exceeded"}

// Good
{"message": "Failed to save message to database, will try again after delay", "error": "handling message from queue foo.bar: saving message to database: deadline exceeded", "delay": "5s"}
```

---

## Comments

### Explain _why_, not _what_ or _how_
Comments should only explain non-intuitive behavior or constraints imposed by external interfaces outside the developer's control. Do not add comments that restate what the code does — code should be self-explanatory. Comments risk becoming stale and misleading.

---

## Go-specific Conventions

### Interfaces: describe what is _needed_, not what is _implemented_
Define interfaces at the point of consumption, listing only the methods the consumer actually needs. Accepting an interface with unused methods misleads readers into thinking those methods are required.

### Error handling: return OR log, not both
When handling errors, either log the error or return/wrap it — never both. Logging at every level as an error propagates up only clutters logs. Use `errors.Wrap` to add context when returning.

```go
func (d *DB) SaveThingToDB(thing Thing) error {
    if err := validateThing(thing); err != nil {
        return errors.Wrap(err, "validating thing")
    }
    if err := d.insertThing(thing); err != nil {
        return err
    }
    return nil
}
```
