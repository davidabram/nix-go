{
  description = "Reproducible Chi web app with gomod2nix and tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gomod2nix.url = "github:nix-community/gomod2nix";
  };

  outputs = { self, nixpkgs, flake-utils, gomod2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Pinned tool versions - customize these as needed
        goVersion = "go_1_25";   # Options: go_1_25 (1.25.2), go_1_24 (1.24.9), or go (latest)
        
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            gomod2nix.overlays.default
            # Override Go version globally for buildGoApplication
            (final: prev: {
              go = prev.${goVersion};
            })
          ];
        };
        
        # Explicit tool versions for clarity
        go = pkgs.${goVersion};      # Go 1.25.2
        gopls = pkgs.gopls;           # 0.20.0 (LSP server)
        gotools = pkgs.gotools;       # 0.34.0 (goimports, godoc, etc.)
        golangci-lint = pkgs.golangci-lint;  # 2.5.0 (linter)
      in {
        packages.default = pkgs.buildGoApplication {
          pname = "chi-app";
          version = "0.1.0";
          src = ./.;
          modules = ./gomod2nix.toml;
          CGO_ENABLED = 0;
          ldflags = [ "-s" "-w" ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            go              # Go 1.25.2 (controlled by goVersion variable)
            gopls           # 0.20.0 (LSP server)
            gotools         # 0.34.0 (goimports, godoc, etc.)
            golangci-lint   # 2.5.0 (linter)
          ];
          
          shellHook = ''
            echo "Go development environment"
            echo "Go version: $(${go}/bin/go version | grep -oP 'go\K[0-9.]+')"
            echo "gopls version: $(${gopls}/bin/gopls version | grep -oP 'v[0-9.]+')"
            echo "gotools version: $(basename $(dirname $(dirname $(which goimports))) | grep -oP '\d+\.\d+\.\d+')"
            echo "golangci-lint version: $(${golangci-lint}/bin/golangci-lint version 2>&1 | head -1 | grep -oP 'version \K[0-9.]+')"
          '';
          
          # Note: To regenerate gomod2nix.toml, use:
          # nix shell github:nix-community/gomod2nix -c gomod2nix generate
        };

        checks.default = pkgs.buildGoApplication {
          pname = "chi-app-tests";
          version = "0.1.0";
          src = ./.;
          modules = ./gomod2nix.toml;
          checkPhase = ''
            runHook preCheck
            go test ./... -v
            runHook postCheck
          '';
          doCheck = true;
          installPhase = ''
            mkdir -p $out
            echo "Tests passed" > $out/test-results.txt
          '';
        };
      });
}
