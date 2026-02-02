{inputs, ...}: {
  # Compatibility shim for nixpkgs >= 25.11 where tbb_2021_11 was removed.
  base-compat = final: prev: {
    tbb_2021_11 = prev.tbb_2021_11 or prev.onetbb or prev.tbb;
  };

  ros2-humble = inputs.nix-ros-overlay.overlays.default;

  # Fix for ROS2 packages requiring __structuredAttrs with separateDebugInfo
  # This MUST come after ros2-humble overlay to override the packages
  ros2-structuredAttrs-fix = final: prev:
    final.lib.optionalAttrs (prev ? rosPackages && prev.rosPackages ? humble) {
      rosPackages = prev.rosPackages // {
        humble = final.lib.mapAttrs (name: pkg:
          if final.lib.isDerivation pkg && (pkg.separateDebugInfo or false)
          then pkg.overrideAttrs (old: {
            __structuredAttrs = true;
          })
          else pkg
        ) prev.rosPackages.humble;
      };
    };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
