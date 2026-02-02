{inputs, ...}: {
  # Compatibility shim for nixpkgs >= 25.11 where tbb_2021_11 was removed.
  base-compat = final: prev: {
    tbb_2021_11 = prev.tbb_2021_11 or prev.onetbb or prev.tbb;
  };

  ros2-humble = inputs.nix-ros-overlay.overlays.default;

  # Fix for separateDebugInfo requiring __structuredAttrs
  # This overrides stdenv to automatically add __structuredAttrs when needed
  structuredAttrs-fix = final: prev: {
    stdenv = prev.stdenv.override (old: {
      mkDerivation = args:
        prev.stdenv.mkDerivation (args
          // (
            if (args.separateDebugInfo or false) && ((args ? allowedRequisites) || (args ? allowedReferences) || (args ? disallowedRequisites) || (args ? disallowedReferences))
            then {__structuredAttrs = true;}
            else {}
          ));
    });
  };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
