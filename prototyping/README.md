Use this directory to store misc code files used for ad-hoc testing. By default the contents of this directory will not be version-controlled.

**Note for Nix users**: The directory `pkg_dev_lib` is meant for holding a temporary installation of the local dev version of `{shinystate}` in order to run tests successfully with `{shinytest2}`. Before running a test, ensure that the dev version of the package is installed by runnign the following:

```r
withr::with_libpaths("prototyping/pkg_dev_lib", devtools::install(upgrade = "never"))
```
