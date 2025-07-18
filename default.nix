# This file was generated by the {rix} R package v0.16.0 on 2025-04-24
# with following call:
# >rix(date = "2025-04-16",
#  > r_pkgs = c("archive",
#  > "cli",
#  > "DBI",
#  > "devtools",
#  > "dplyr",
#  > "DT",
#  > "fs",
#  > "htmltools",
#  > "lubridate",
#  > "pins",
#  > "R6",
#  > "RSQLite",
#  > "pool",
#  > "shiny",
#  > "tibble",
#  > "rlang",
#  > "testthat",
#  > "withr",
#  > "s3fs",
#  > "sodium",
#  > "shinyvalidate",
#  > "chromote",
#  > "zip",
#  > "ggplot2"),
#  > ide = "none",
#  > project_path = getwd(),
#  > overwrite = TRUE,
#  > r_ver = "4.5.0")
# It uses the `rstats-on-nix` fork of `nixpkgs` which provides improved
# compatibility with older R versions and R packages for Linux/WSL and
# Apple Silicon computers.
# Report any issues to https://github.com/ropensci/rix
let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-04-16.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      archive
      chromote
      cli
      DBI
      devtools
      dplyr
      DT
      fs
      ggplot2
      htmltools
      lubridate
      pins
      pool
      R6
      rlang
      RSQLite
      s3fs
      shiny
      shinyvalidate
      sodium
      testthat
      tibble
      withr
      zip;
  };
     
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      glibcLocales
      nix
      R;
  };
  
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    
    buildInputs = [  rpkgs   system_packages   ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
