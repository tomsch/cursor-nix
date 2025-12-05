{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  binutils,
  autoPatchelfHook,
  gsettings-desktop-schemas,
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
  version = "2.1.48";

  src = fetchurl {
    url = "https://downloads.cursor.com/production/ce371ffbf5e240ca47f4b5f3f20efed084991120/linux/x64/deb/amd64/deb/cursor_${finalAttrs.version}_amd64.deb";
    hash = "sha256-JwDN8d+7JsDBXhWoNJF0oQkEdQ1Rnh/bE4S1oNdRRCU=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    binutils
  ];

  dontWrapGApps = true;

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

    # Create wrapper script (needs shell for env var expansion)
    # Using a shell script instead of makeBinaryWrapper because the Wayland
    # flags use shell parameter expansion (${VAR:+...}) which must be evaluated
    # at runtime, not build time.
    cat > $out/bin/cursor << EOF
#!/usr/bin/env bash
export LD_LIBRARY_PATH="${lib.makeLibraryPath finalAttrs.buildInputs}\''${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}\''${XDG_DATA_DIRS:+:\$XDG_DATA_DIRS}"
exec $out/lib/cursor/cursor \''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}} "\$@"
EOF
    chmod +x $out/bin/cursor

    # Fix desktop file - remove %F to prevent spurious file arguments
    substituteInPlace $out/share/applications/cursor.desktop \
      --replace-fail "Exec=/usr/share/cursor/cursor %F" "Exec=$out/bin/cursor" \
      --replace-fail "Exec=/usr/share/cursor/cursor --new-window %F" "Exec=$out/bin/cursor --new-window" \
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
