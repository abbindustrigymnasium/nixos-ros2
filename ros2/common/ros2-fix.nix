{
  pkgs,
  lib,
  ...
}: {
  # Fix for ROS2 packages requiring __structuredAttrs with separateDebugInfo
  # Override ROS packages to add __structuredAttrs where needed
  nixpkgs.overlays = [
    (
      final: prev:
        lib.optionalAttrs (prev ? rosPackages) {
          rosPackages =
            prev.rosPackages
            // {
              humble =
                lib.mapAttrs (
                  name: pkg:
                    if lib.isDerivation pkg && (pkg.separateDebugInfo or false)
                    then
                      pkg.overrideAttrs (old: {
                        __structuredAttrs = true;
                      })
                    else pkg
                )
                prev.rosPackages.humble;
            };
        }
    )
  ];
}
