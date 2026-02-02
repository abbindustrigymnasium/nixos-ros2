{inputs, ...}: {
  # Compatibility shim for nixpkgs >= 25.11 where tbb_2021_11 was removed.
  base-compat = final: prev: {
    tbb_2021_11 = prev.tbb_2021_11 or prev.onetbb or prev.tbb;
  };

  ros2-humble = inputs.nix-ros-overlay.overlays.default;

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
