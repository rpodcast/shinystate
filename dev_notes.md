## Nix Quirks

When using this project with Nix, we are not able to install any packages in the default library controlled by Nix with the usual `devtools::install()`. This is an issue with the use of `{shinytest2}`, where the application package must be installed separately before any tests can be performed or recorded. I learned through the docs of [`devtools::install`](https://devtools.r-lib.org/reference/install.html) that you can leverage `withr::with_libpaths()` to install the package to a non-standard library location. Hence here is the procedure to get the tests involving the example apps of the package ready for testing:

* Install the package using this snippet anytime the code has been updated:

```r
withr::with_libpaths("prototyping/tmp_lib", devtools::install())
```

* Use the same `withr::with_libpaths()` call above to wrap any call for loading the application code.
