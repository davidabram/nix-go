{
  description = "A basic gomod2nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";
  inputs.gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.gomod2nix.inputs.flake-utils.follows = "flake-utils";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      gomod2nix,
    }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        buildGoApplication = gomod2nix.legacyPackages.${system}.buildGoApplication;

        callPackage = pkgs.callPackage;

        goPackage = callPackage ./. {
          inherit buildGoApplication;
        };

        go-test = goPackage.overrideAttrs (old: {
          name = "go-test";
          doCheck = true;
          checkPhase = ''
            runHook preCheck
            go test -v ./...
            runHook postCheck
          '';
          buildPhase = "true";
          installPhase = ''
            mkdir -p "$out"
          '';
        });

        go-lint = goPackage.overrideAttrs (old: {
          name = "go-lint";
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
            pkgs.golangci-lint
          ];
          preBuild = ''
            export HOME=$(mktemp -d)
            export GOLANGCI_LINT_CACHE=$HOME/.cache/golangci-lint
            export GOCACHE=$HOME/.cache/go-build
            golangci-lint run
          '';
          buildPhase = "true";
          doCheck = false;
          installPhase = ''
            mkdir -p "$out"
          '';
        });

        go-format = goPackage.overrideAttrs (old: {
          name = "go-format";
          # Check formatting after modules are configured but before build
          preBuild = ''
            echo "Checking Go code formatting..."
            unformatted=$(gofmt -l .)
            if [ -n "$unformatted" ]; then
              echo "ERROR: The following files are not formatted with gofmt:"
              echo "$unformatted"
              echo ""
              echo "Please run 'gofmt -w .' to format these files."
              exit 1
            fi
            echo "All Go files are properly formatted."
          '';
          buildPhase = "true";
          doCheck = false;
          installPhase = ''
            mkdir -p "$out"
          '';
        });

        dockerImage = pkgs.dockerTools.buildImage {
          name = "chi-app";
          tag = "latest";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [
              goPackage
              pkgs.dockerTools.caCertificates
              pkgs.busybox
            ];
            pathsToLink = [ "/bin" ];
          };

          config = {
            Cmd = [ "${goPackage}/bin/chi-app" ];
            ExposedPorts = {
              "8080/tcp" = {};
            };
            Env = [
              "ADDR=:8080"
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            ];
          };
        };
      in
      {
        checks = {
          inherit go-test go-lint go-format;
        };
        packages = {
          default = goPackage;
          docker = dockerImage;
        };
        devShells.default = callPackage ./shell.nix {
          inherit (gomod2nix.legacyPackages.${system}) mkGoEnv gomod2nix;
        };
      }
    ));
}
