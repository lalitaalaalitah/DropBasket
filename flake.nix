{
  description = "DropBasket - Floating drag-and-drop basket companion for AeroSpace on macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
        inherit system;
      });
    in
    {
      packages = forAllSystems ({ pkgs, system }: rec {
        dropbasket = pkgs.stdenv.mkDerivation rec {
          pname = "dropbasket";
          version = "1.0.0";
          src = ./.;

          nativeBuildInputs = [
            pkgs.swift
            pkgs.swiftpm
          ];

          buildInputs = [
            pkgs.apple-sdk
          ];

          dontStrip = true;

          buildPhase = ''
            runHook preBuild
            export HOME=$(mktemp -d)
            mkdir -p "$HOME/Library/Caches"
            mkdir -p "$HOME/Library/org.swift.swiftpm/configuration"
            mkdir -p "$HOME/Library/org.swift.swiftpm/security"
            swift build -c release --disable-sandbox
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/Applications/DropBasket.app/Contents/MacOS
            mkdir -p $out/Applications/DropBasket.app/Contents/Resources
            mkdir -p $out/bin

            BIN_PATH="$(swift build -c release --show-bin-path)/DropBasket"
            cp "$BIN_PATH" $out/Applications/DropBasket.app/Contents/MacOS/DropBasket
            chmod +x $out/Applications/DropBasket.app/Contents/MacOS/DropBasket

            cp Resources/Info.plist $out/Applications/DropBasket.app/Contents/Info.plist
            if [ -f Resources/AppIcon.icns ]; then
              cp Resources/AppIcon.icns $out/Applications/DropBasket.app/Contents/Resources/AppIcon.icns
            fi

            ln -s $out/Applications/DropBasket.app/Contents/MacOS/DropBasket $out/bin/dropbasket
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Floating drag-and-drop basket companion for AeroSpace on macOS";
            homepage = "https://www.lalitaalaalitah.com";
            license = licenses.mit;
            platforms = platforms.darwin;
            maintainers = [ "lalitaalaalitah" ];
            mainProgram = "dropbasket";
          };
        };

        default = dropbasket;
      });

      apps = forAllSystems ({ pkgs, system }: {
        dropbasket = {
          type = "app";
          program = "${self.packages.${system}.dropbasket}/bin/dropbasket";
        };
        default = self.apps.${system}.dropbasket;
      });

      devShells = forAllSystems ({ pkgs, system }: {
        default = pkgs.mkShell {
          packages = [
            pkgs.swift
            pkgs.swiftpm
            pkgs.apple-sdk
            pkgs.gnumake
          ];
        };
      });

      darwinModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.dropbasket;
        in
        {
          options.services.dropbasket = {
            enable = lib.mkEnableOption "DropBasket background service";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              description = "The DropBasket package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];

            launchd.user.agents.dropbasket = {
              serviceConfig = {
                ProgramArguments = [ "${cfg.package}/bin/dropbasket" "run" ];
                KeepAlive = true;
                RunAtLoad = true;
                ProcessType = "Interactive";
                StandardOutPath = "/tmp/com.lalitaalaalitah.DropBasket.stdout.log";
                StandardErrorPath = "/tmp/com.lalitaalaalitah.DropBasket.stderr.log";
              };
            };
          };
        };

      homeModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.dropbasket;
        in
        {
          options.services.dropbasket = {
            enable = lib.mkEnableOption "DropBasket background service";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              description = "The DropBasket package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];

            launchd.agents.dropbasket = {
              enable = true;
              config = {
                ProgramArguments = [ "${cfg.package}/bin/dropbasket" "run" ];
                KeepAlive = true;
                RunAtLoad = true;
                ProcessType = "Interactive";
                StandardOutPath = "/tmp/com.lalitaalaalitah.DropBasket.stdout.log";
                StandardErrorPath = "/tmp/com.lalitaalaalitah.DropBasket.stderr.log";
              };
            };
          };
        };

      homeManagerModules.default = self.homeModules.default;
    };
}
