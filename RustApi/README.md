# Rust API

This is a Rust implementation of the .NET Minimal API, providing equivalent endpoints for benchmarking and comparison purposes.

## API Endpoints

- `GET /users` - Returns 10,000 generated user records with detailed information
- `GET /benchmark` - Performs CPU-intensive prime number calculation and returns performance metrics

## Prerequisites

- Rust 1.70+ (install from https://rustup.rs/)

## Building

### Debug Build
```bash
cargo build
```

### Release Build (Optimized)
```bash
cargo build --release
```

The release build is optimized for performance with:
- LTO (Link Time Optimization)
- Single codegen unit
- Stripped symbols
- Panic abort

## Running

### Development Mode
```bash
cargo run
```

### Production Mode (Optimized)
```bash
cargo run --release
```

The server will start on `http://127.0.0.1:5003`

## Testing the API

### Test /users endpoint
```bash
curl http://localhost:5003/users
```

### Test /benchmark endpoint
```bash
curl http://localhost:5003/benchmark
```

## Performance Notes

- The release build is highly optimized for performance and small binary size
- Similar to the .NET Native AOT version, this produces a self-contained executable
- The benchmark endpoint calculates primes up to 1,000,000 for CPU performance testing
- Memory usage is tracked and reported in the benchmark results

## Comparison with .NET API

This Rust API provides functionally equivalent endpoints to the .NET Native AOT Minimal API:
- Same data structures and JSON response format
- Same prime number calculation algorithm
- Identical 10,000 user dataset generated at startup for consistent responses
- Comparable performance characteristics
