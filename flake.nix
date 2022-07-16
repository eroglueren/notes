{
  description = "Personal notes";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs"; };

  outputs = { self, nixpkgs }: {
    defaultPackage.x86_64-linux = self.packages.x86_64-linux.personal-notes;

    packages.x86_64-linux.personal-notes =
      let pkgs = import nixpkgs { system = "x86_64-linux"; };
      in pkgs.stdenvNoCC.mkDerivation {
        pname = "personal-notes";
        version = "0.0.1";
        src = ./.;
        buildInputs = with pkgs; [ sphinx ];
        buildPhase = ''
          make html
        '';
        installPhase = ''
          cp -r build/html/ $out
        '';
      };

    devShells.x86_64-linux.default =
      let pkgs = import nixpkgs { system = "x86_64-linux"; };
      in pkgs.mkShell { buildInputs = with pkgs; [ sphinx ]; };
  };
}
