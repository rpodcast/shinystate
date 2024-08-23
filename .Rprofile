### File generated by `rix::rix_init()` ###
# 1. Currently, system RStudio does not inherit environmental variables
#   defined in `$HOME/.zshrc`, `$HOME/.bashrc` and alike. This is workaround to
#   make the path of the nix store and hence basic nix commands available
#   in an RStudio session
# 2. For nix-R session, remove `R_LIBS_USER`, system's R user library.`.
#   This guarantees no user libraries from the system are loaded and only
#   R packages in the Nix store are used. This makes Nix-R behave in pure manner
#   at run-time.
{
    is_rstudio <- Sys.getenv("RSTUDIO") == "1"
    is_nix_r <- nzchar(Sys.getenv("NIX_STORE"))
    if (isFALSE(is_nix_r) && isTRUE(is_rstudio)) {
        cat("{rix} detected RStudio R session")
        old_path <- Sys.getenv("PATH")
        nix_path <- "/nix/var/nix/profiles/default/bin"
        has_nix_path <- any(grepl(nix_path, old_path))
        if (isFALSE(has_nix_path)) {
            Sys.setenv(PATH = paste(old_path, nix_path, sep = ":"))
        }
        rm(old_path, nix_path)
    }
    if (isTRUE(is_nix_r)) {
        install.packages <- function(...) {
            stop("You are currently in an R session running from Nix.\nDon't install packages using install.packages(),\nadd them to the default.nix file instead.")
        }
        update.packages <- function(...) {
            stop("You are currently in an R session running from Nix.\nDon't update packages using update.packages(),\ngenerate a new default.nix with a more recent version of R. If you need bleeding edge packages, read the 'Understanding the rPackages set release cycle and using bleeding edge packages' vignette.")
        }
        remove.packages <- function(...) {
            stop("You are currently in an R session running from Nix.\nDon't remove packages using remove.packages(),\ndelete them from the default.nix file instead.")
        }
        current_paths <- .libPaths()
        userlib_paths <- Sys.getenv("R_LIBS_USER")
        user_dir <- grep(paste(userlib_paths, collapse = "|"), current_paths, fixed = TRUE)
        new_paths <- current_paths[-user_dir]
        .libPaths(new_paths)
        rm(current_paths, userlib_paths, user_dir, new_paths)
    }
    rm(is_rstudio, is_nix_r)
}
