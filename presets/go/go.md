# Go Conventions

This preset covers best practices for Go projects with error handling, concurrency safety, and idiomatic patterns.

## Build & Test

Use the standard Go toolchain. Never use alternate build systems.

**Pattern:**

```bash
go build                       # Build binary
go build -o app ./cmd/main.go  # Build with output name
go test ./...                  # Test all packages
go test -v ./...               # Verbose test output
go test -cover ./...           # Coverage summary
go test -race ./...            # Run with race detector
go vet ./...                   # Lint for common mistakes
go fmt ./...                   # Format code
golangci-lint run              # Comprehensive linting
```

## Error Handling

Use explicit error returns and `errors.Is` / `errors.As` for matching.

**Pattern (explicit returns):**

```go
func readFile(path string) ([]byte, error) {
    data, err := ioutil.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("failed to read file: %w", err)
    }
    return data, nil
}

func main() {
    data, err := readFile("config.json")
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(string(data))
}
```

**Pattern (custom errors with `errors.Is`):**

```go
var ErrNotFound = errors.New("not found")
var ErrInvalidInput = errors.New("invalid input")

func validateEmail(email string) error {
    if !strings.Contains(email, "@") {
        return fmt.Errorf("email validation: %w", ErrInvalidInput)
    }
    return nil
}

func main() {
    err := validateEmail("invalid")
    if errors.Is(err, ErrInvalidInput) {
        fmt.Println("Email validation failed")
    }
}
```

**Pattern (error wrapping with context):**

```go
func processConfig(path string) error {
    data, err := ioutil.ReadFile(path)
    if err != nil {
        return fmt.Errorf("load config: %w", err)
    }

    var cfg Config
    if err := json.Unmarshal(data, &cfg); err != nil {
        return fmt.Errorf("parse config: %w", err)
    }

    return nil
}
```

Never silently ignore errors. Always return or handle them explicitly.

## Interface Patterns

Use small, focused interfaces. Satisfy interfaces implicitly.

**Pattern:**

```go
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

type User struct {
    ID    int
    Email string
}

// User doesn't explicitly implement Reader, but can satisfy it
func (u *User) Read(p []byte) (int, error) {
    // Implementation
    return 0, nil
}

func ProcessData(r Reader) error {
    data := make([]byte, 1024)
    _, err := r.Read(data)
    return err
}
```

Keep interfaces small (1-3 methods max). Compose larger behavior from smaller interfaces.

## Table-Driven Tests

Use table-driven tests for multiple cases.

**Pattern:**

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 2, 3, 5},
        {"negative", -1, 1, 0},
        {"zeros", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("got %d, expected %d", result, tt.expected)
            }
        })
    }
}
```

Table-driven tests are the Go standard. Use them consistently.

## Concurrency

Use goroutines and channels safely. Always handle synchronization explicitly.

**Pattern (goroutines with WaitGroup):**

```go
import "sync"

func fetchUrls(urls []string) {
    var wg sync.WaitGroup
    for _, url := range urls {
        wg.Add(1)
        go func(u string) {
            defer wg.Done()
            resp, err := http.Get(u)
            if err != nil {
                log.Printf("fetch %s: %v", u, err)
                return
            }
            defer resp.Body.Close()
            // Process response
        }(url)
    }
    wg.Wait()
}
```

**Pattern (channels for communication):**

```go
func worker(jobs <-chan int, results chan<- int) {
    for job := range jobs {
        results <- job * 2
    }
}

func main() {
    jobs := make(chan int, 100)
    results := make(chan int, 100)

    for i := 0; i < 3; i++ {
        go worker(jobs, results)
    }

    for j := 1; j <= 5; j++ {
        jobs <- j
    }
    close(jobs)

    for a := 1; a <= 5; a++ {
        <-results
    }
}
```

**Pattern (select for timeout):**

```go
func fetchWithTimeout(url string, timeout time.Duration) ([]byte, error) {
    done := make(chan []byte, 1)
    go func() {
        resp, err := http.Get(url)
        if err != nil {
            return
        }
        defer resp.Body.Close()
        data, _ := ioutil.ReadAll(resp.Body)
        done <- data
    }()

    select {
    case data := <-done:
        return data, nil
    case <-time.After(timeout):
        return nil, errors.New("timeout")
    }
}
```

Goroutines must always be cleaned up. Use `WaitGroup` or channels to track them.

## Package Organization

Use descriptive package names. One responsibility per package.

**Pattern:**

```
myapp/
├── main.go              # Entry point
├── go.mod
├── go.sum
├── cmd/
│   └── myapp/
│       └── main.go
├── internal/
│   ├── config/
│   │   └── config.go
│   ├── db/
│   │   └── db.go
│   └── api/
│       └── handlers.go
└── pkg/
    └── util/
        └── util.go
```

Use `internal/` for packages only used by your app. Use `pkg/` for libraries.

## Testing

Use `testing.T` for unit tests and `testing.B` for benchmarks.

**Pattern (unit test):**

```go
func TestValidateEmail(t *testing.T) {
    if err := ValidateEmail("test@example.com"); err != nil {
        t.Errorf("expected no error, got %v", err)
    }

    if err := ValidateEmail("invalid"); err == nil {
        t.Error("expected error for invalid email")
    }
}
```

**Pattern (benchmark):**

```go
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(2, 3)
    }
}
```

Run benchmarks: `go test -bench=. -benchmem`

## Module Organization (go.mod)

**Pattern (go.mod):**

```mod
module github.com/user/myapp

go 1.21

require (
    github.com/lib/pq v1.10.0
    github.com/google/uuid v1.3.0
)

require github.com/some/tool v1.0.0 // indirect
```

Use `go get -u` to update dependencies. Use `go mod tidy` to clean up.

## Common Mistakes

1. **Ignoring errors silently** — Always check and return errors
2. **Goroutine leaks** — Always clean up goroutines with WaitGroup or channels
3. **Using non-buffered channels incorrectly** — Buffer appropriately or use select
4. **Not using race detector** — Run `go test -race ./...` before commits
5. **Large interfaces** — Keep interfaces small and focused
