# nix-go

## Running with Nix

### Development Environment

Enter the development shell with all dependencies:

```bash
nix develop
```

This provides:
- Go toolchain
- gomod2nix for Go module management
- All project dependencies

Once in the development shell, you can run standard Go commands:

```bash
go run main.go
go test ./...
```

### Running the Application

Run the application directly without entering the shell:

```bash
nix run
```

The server will start on `http://localhost:8080` by default.

To specify a custom address:

```bash
ADDR=":3000" nix run
```

### Building the Application

Build the application:

```bash
nix build
```

The binary will be available at `./result/bin/myapp`:

```bash
./result/bin/myapp
```

## Available Commands

### Run Tests

```bash
nix flake check
```

This runs:
- Go tests (`go test -v ./...`)
- golangci-lint checks

Or run tests individually:

```bash
nix build .#checks.x86_64-linux.go-test
nix build .#checks.x86_64-linux.go-lint

nix develop
go test ./...
golangci-lint run
```

## Updating Dependencies

When you modify `go.mod` or `go.sum`, update the Nix dependencies:

```bash
nix develop
gomod2nix
```

This regenerates `gomod2nix.toml` with the latest dependency information.
