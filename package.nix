{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  makeWrapper,
  electron,
  binutils,
  autoPatchelfHook,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  xorg,
  libsecret,
  libnotify,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cursor";
  version = "2.1.46";

  # Version info fetched from: https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable
  src = fetchurl {
    url = "https://downloads.cursor.com/production/ab326d0767c02fb9847b342c43ea58275c4b1685/linux/x64/deb/amd64/deb/cursor_${finalAttrs.version}_amd64.deb";
    hash = "sha256-x7FXIlr8NgRYYCv/CCY1YOyDaYvUNeZMTxYmzKJJV+I=";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
    autoPatchelfHook
    wrapGAppsHook3
    binutils
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libGL
    libxkbcommon
    mesa
    nspr
    nss
    pango
    libsecret
    libnotify
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    xorg.libxshmfence
    xorg.libxkbfile
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    ar x $src
    tar --no-same-owner --no-same-permissions -xf data.tar.*
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/cursor $out/bin $out/share

    # Copy application files (new structure: usr/share/cursor/)
    cp -r usr/share/cursor/* $out/lib/cursor/

    # Copy other share files (applications, pixmaps, mime, etc.)
    cp -r usr/share/applications $out/share/ || true
    cp -r usr/share/pixmaps $out/share/ || true
    cp -r usr/share/mime $out/share/ || true
    cp -r usr/share/bash-completion $out/share/ || true
    cp -r usr/share/zsh $out/share/ || true

    # Create wrapper
    makeWrapper $out/lib/cursor/cursor $out/bin/cursor \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

    # Fix desktop file
    substituteInPlace $out/share/applications/cursor.desktop \
      --replace-fail "Exec=/usr/share/cursor/cursor" "Exec=$out/bin/cursor" \
      --replace-fail "Icon=co.anysphere.cursor" "Icon=$out/share/pixmaps/co.anysphere.cursor.png"

    # Fix URL handler desktop file
    substituteInPlace $out/share/applications/cursor-url-handler.desktop \
      --replace-fail "Exec=/usr/share/cursor/cursor" "Exec=$out/bin/cursor" \
      --replace-fail "Icon=co.anysphere.cursor" "Icon=$out/share/pixmaps/co.anysphere.cursor.png" || true

    runHook postInstall
  '';

  meta = {
    description = "AI-first code editor (fork of VS Code)";
    homepage = "https://cursor.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cursor";
  };
})
