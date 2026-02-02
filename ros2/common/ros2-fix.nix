{pkgs, lib, ...}: {
  # Fix for ROS2 packages requiring __structuredAttrs with separateDebugInfo
  # This creates an overlay that wraps mkDerivation to automatically add
  # __structuredAttrs when separateDebugInfo is enabled with reference restrictions
  nixpkgs.overlays = [
    (final: prev: {
      # Wrap mkDerivation to automatically fix the separateDebugInfo issue
      mkDerivation = args:
        let
          needsStructuredAttrs =
            (args.separateDebugInfo or false)
            && (
              (args ? allowedRequisites)
              || (args ? allowedReferences)
              || (args ? disallowedRequisites)
              || (args ? disallowedReferences)
            );
          fixedArgs =
            if needsStructuredAttrs
            then args // {__structuredAttrs = true;}
            else args;
        in
          prev.mkDerivation fixedArgs;
    })
  ];
}
