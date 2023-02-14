{
  description = "Zeebe Performance Testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs { inherit system; };
        gcloud = pkgs.google-cloud-sdk.withExtraComponents [pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin];
      in
      {
        devShells = {
          default = pkgs.mkShell
            {
              buildInputs = with pkgs; [
                gcloud
                docker
                kubernetes-helm
                kubectl
                kind
                krew
                jq
              ];
            };
        };
      });
}
