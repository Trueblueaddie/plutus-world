{
  inputs,
  cell,
}: let
  inherit (inputs.std) std;
  inherit (inputs) capsules bitte-cells bitte nixpkgs;
  inherit (inputs.cells) cardano;

  # FIXME: this is a work around just to get access
  # to 'awsAutoScalingGroups'
  # TODO: std ize bitte properly to make this interface nicer
  bitte' = inputs.bitte.lib.mkBitteStack {
    inherit inputs;
    inherit (inputs) self;
    domain = "plutus.aws.iohkdev.io";
    bitteProfile = inputs.cells.metal.bitteProfile.default;
    hydrationProfile = inputs.cells.cloud.hydrationProfiles.default;
    deploySshKey = "not-a-key";
  };

  plutusWorld = {
    extraModulesPath,
    pkgs,
    ...
  }: {
    name = nixpkgs.lib.mkForce "Plutus World";
    nixago = [
      (std.nixago.conform {configData = {inherit (inputs) cells;};})
      cell.nixago.treefmt
      cell.nixago.editorconfig
      cell.nixago.mdbook
      std.nixago.lefthook
      std.nixago.adrgen
    ];

    imports = [
      std.devshellProfiles.default
      bitte.devshellModule
    ];
    bitte = {
      domain = "plutus.aws.iohkdev.io";
      cluster = "plutus";
      namespace = "production";
      provider = "AWS";
      cert = null;
      aws_profile = "plutus";
      aws_region = "eu-central-1";
      aws_autoscaling_groups =
        bitte'.clusters.plutus._proto.config.cluster.awsAutoScalingGroups;
    };
  };
in {
  dev = std.lib.mkShell {
    imports = [
      plutusWorld
      capsules.base
      capsules.cloud
      capsules.integrations
    ];
    packages = [];
  };
  ops = std.lib.mkShell {
    imports = [
      plutusWorld
      capsules.base
      capsules.cloud
      capsules.metal
      capsules.integrations
      capsules.tools
    ];
  };
}
