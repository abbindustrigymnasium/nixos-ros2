{inputs, ...}: {
  # Compatibility shim for nixpkgs >= 25.11 where tbb_2021_11 was removed.
  base-compat = final: prev: {
    tbb_2021_11 = prev.tbb_2021_11 or prev.onetbb or prev.tbb;
  };

  ros2-humble = inputs.nix-ros-overlay.overlays.default;

  # Fix for separateDebugInfo requiring __structuredAttrs in ROS2 packages
  ros2-structuredAttrs = final: prev: {
    rosPackages = prev.rosPackages or {} // {
      humble = (prev.rosPackages.humble or {}) // (prev.lib.mapAttrs (name: pkg:
        if prev.lib.isDerivation pkg && (pkg.separateDebugInfo or false)
        then pkg.overrideAttrs (old: {__structuredAttrs = true;})
        else pkg
      ) (prev.rosPackages.humble or {}));
    };
  };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
