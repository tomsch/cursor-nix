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
  version = "2.4.22";

  src = fetchurl {
    url = "https://downloads.cursor.com/production/618c607a249dd7fd2ffc662c6531143833bebd44/linux/x64/deb/amd64/deb/cursor_${finalAttrs.version}_amd64.deb";
    hash = "sha256-sPciWqdbnGFzaEGOtjymjL//BGownEzGQBvShU5OBFk=";
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

    # Create wrapper script
    cat > $out/bin/cursor << 'WRAPPER'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="LIBPATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="DATAPATH''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"

# Wayland support - only add flags if running on Wayland
WAYLAND_FLAGS=""
if [[ -n "$NIXOS_OZONE_WL" && -n "$WAYLAND_DISPLAY" ]]; then
  WAYLAND_FLAGS="--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true"
fi

exec CURSORPATH $WAYLAND_FLAGS "$@"
WRAPPER

    # Substitute paths in wrapper
    substituteInPlace $out/bin/cursor \
      --replace-fail "LIBPATH" "${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --replace-fail "DATAPATH" "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}" \
      --replace-fail "CURSORPATH" "$out/lib/cursor/cursor"
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
