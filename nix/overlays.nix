{}: {
  sddm-sugar-candy  = final: prev: {
    sddm-sugar-candy = final.libsForQt5.callPackage ./default.nix { };
  };
}
