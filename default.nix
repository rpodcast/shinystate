# This file was generated by the {rix} R package v0.6.0 on 2024-04-19
# with following call:
# >rix(r_ver = "d764f230634fa4f86dc8d01c6af9619c7cc5d225",
#  > r_pkgs = c("shiny",
#  > "cookie",
#  > "fs"),
#  > system_pkgs = "vscode",
#  > ide = "code",
#  > project_path = ".",
#  > overwrite = TRUE)
# It uses nixpkgs' revision d764f230634fa4f86dc8d01c6af9619c7cc5d225 for reproducibility purposes
# which will install R version latest
# Report any issues to https://github.com/b-rodrigues/rix
let
 pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/d764f230634fa4f86dc8d01c6af9619c7cc5d225.tar.gz") {};
 rpkgs = builtins.attrValues {
  inherit (pkgs.rPackages) shiny fs languageserver pins archive s3fs DT DBI RSQLite lubridate pool dplyr dbplyr;
};
   system_packages = builtins.attrValues {
  inherit (pkgs) R glibcLocales vscodium nix;
};
  in
  pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then  "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";

    buildInputs = [  rpkgs  system_packages  ];
      
  }
