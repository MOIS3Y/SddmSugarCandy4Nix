{}: {
  SddmSugarCandy4Nix = final: prev: {
    SddmSugarCandy4Nix = final.libsForQt5.callPackage ./default.nix { };
  };
}
