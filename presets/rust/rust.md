# Rust Conventions

This preset covers best practices for Rust projects with testing, error handling, module organization, and safety patterns.

## Build & Test

Use Cargo for all builds and tests. Never use raw `rustc`.

**Pattern:**

```bash
cargo build                # Debug build
cargo build --release      # Optimized build
cargo test                 # Run all tests
cargo test -- --nocapture # Show output
cargo test --release       # Test optimized binary
cargo fmt                  # Format code
cargo clippy               # Lint
cargo doc --open           # Build and open docs
```

## Error Handling

Prefer Result types with structured error types.

**Pattern (using `anyhow`):**

```rust
use anyhow::{Result, anyhow, Context};

fn read_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .context("Failed to read config file")?;
    let config: Config = serde_json::from_str(&content)
        .context("Invalid config format")?;
    Ok(config)
}

fn main() -> Result<()> {
    let config = read_config("config.json")?;
    println!("Config: {:?}", config);
    Ok(())
}
```

**Pattern (using `thiserror` for custom errors):**

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Invalid input: {0}")]
    InvalidInput(String),
    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

fn validate_email(email: &str) -> Result<(), AppError> {
    if !email.contains('@') {
        return Err(AppError::InvalidInput("Missing @".into()));
    }
    Ok(())
}
```

**Pattern (error matching):**

```rust
match read_config("config.json") {
    Ok(config) => println!("Config loaded: {:?}", config),
    Err(e) => eprintln!("Failed to load config: {:#}", e),
}

if let Some(err) = error_source {
    println!("Caused by: {}", err);
}
```

Never panic in libraries; use Result types instead.

## Module Organization

Use filesystem-based module hierarchy. Each directory gets a `mod.rs` file.

**Pattern:**

```
src/
├── main.rs           # Entry point
├── lib.rs            # Library root
├── models/
│   ├── mod.rs        # pub mod user; pub mod item;
│   ├── user.rs       # pub struct User { }
│   └── item.rs       # pub struct Item { }
├── handlers/
│   ├── mod.rs        # pub mod auth; pub mod api;
│   ├── auth.rs       # pub async fn login() { }
│   └── api.rs        # pub async fn get_items() { }
└── db/
    ├── mod.rs        # pub async fn connect() { }
    └── migrations.rs
```

**Pattern (lib.rs):**

```rust
pub mod models;
pub mod handlers;
pub mod db;

pub use models::{User, Item};
pub use handlers::{auth, api};
```

## Testing

Use `#[cfg(test)]` module pattern with fixtures.

**Pattern:**

```rust
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn test_add_negative() {
        assert_eq!(add(-1, 1), 0);
    }

    #[test]
    #[should_panic]
    fn test_panic() {
        panic!("Expected panic");
    }
}
```

**Pattern (integration tests):**

```
tests/
├── integration_test.rs   # Tests the entire crate as a library
```

```rust
use my_crate::read_config;

#[test]
fn test_config_loading() {
    let result = read_config("tests/fixtures/config.json");
    assert!(result.is_ok());
}
```

## Unsafe Code

Minimize unsafe blocks. Document why unsafe is needed.

**Pattern:**

```rust
/// SAFETY: Only called when `ptr` is valid and properly aligned.
/// The caller must ensure `ptr` was allocated with `malloc`.
unsafe fn process_raw_pointer(ptr: *mut u8) {
    if ptr.is_null() {
        panic!("Null pointer passed");
    }
    // Safe operations here
    let value = *ptr;
}

// Safe wrapper
pub fn safe_process(ptr: *mut u8) -> Result<(), &'static str> {
    if ptr.is_null() {
        return Err("Null pointer");
    }
    unsafe { process_raw_pointer(ptr); }
    Ok(())
}
```

Unsafe blocks must be:
1. Minimal (one concern per block)
2. Well-documented (SAFETY: comment)
3. Wrapped in safe functions
4. Unit-tested with edge cases

## Documentation

Use rustdoc for all public APIs.

**Pattern:**

```rust
/// Adds two numbers together.
///
/// # Arguments
///
/// * `a` - The first number
/// * `b` - The second number
///
/// # Returns
///
/// The sum of `a` and `b`.
///
/// # Examples
///
/// ```
/// use my_crate::add;
/// assert_eq!(add(2, 3), 5);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// # Panics
///
/// Panics if the vector is empty.
pub fn first(vec: &[i32]) -> i32 {
    vec[0]
}
```

Run `cargo doc --open` to verify documentation builds correctly.

## Cargo.toml

**Pattern:**

```toml
[package]
name = "my_crate"
version = "0.1.0"
edition = "2021"
authors = ["Your Name <email@example.com>"]
license = "MIT"

[dependencies]
anyhow = "1.0"
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1", features = ["full"] }

[dev-dependencies]
tokio-test = "0.4"

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
```

## Common Mistakes

1. **Using `unwrap()` in production** — Use `?` operator or proper error handling
2. **Cloning excessively** — Use references, borrowed data
3. **Ignoring lifetime errors early** — Fix them immediately; they're design feedback
4. **Mixing `anyhow` and `thiserror`** — Pick one: anyhow for apps, thiserror for libraries
5. **Not writing tests** — Rust's type system catches many bugs; tests catch logic bugs
