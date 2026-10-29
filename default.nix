{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation rec {
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
}
