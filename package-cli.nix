{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zlib,
  openssl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "cursor-cli";
  version = "2026.07.20-8cc9c0b";

  src = fetchurl {
    url = "https://downloads.cursor.com/lab/${finalAttrs.version}/linux/x64/agent-cli-package.tar.gz";
    hash = "sha256-bp8XJH/+tfj34iRrS81rsmyy1an5pLABLJqA2GjtJbQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  # Tarball bundled binaries: node, rg, cursorsandbox - all ELF, need patchelf.
  buildInputs = [
    stdenv.cc.cc.lib # libstdc++ for bundled node
    zlib             # node compression / rg
    openssl          # cursor-agent --use-system-ca
  ];

  dontConfigure = true;
  dontBuild = true;

  # Tarball extracts to dist-package/.
  sourceRoot = "dist-package";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/cursor-cli $out/bin
    cp -r . $out/lib/cursor-cli/

    # cursor-agent is a bash wrapper that resolves its own directory with realpath;
    # symlinks keep NODE_BIN/index.js lookup intact.
    ln -s $out/lib/cursor-cli/cursor-agent $out/bin/cursor-agent
    ln -s $out/lib/cursor-cli/cursor-agent $out/bin/agent

    runHook postInstall
  '';

  meta = {
    description = "Cursor Agent CLI - AI coding agent (terminal)";
    homepage = "https://docs.cursor.com/cli";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cursor-agent";
  };
})
