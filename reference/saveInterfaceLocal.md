# Set saving and loading interfaces for shiny bookmarking local storage

The `saveInterfaceLocal` and `loadInterfaceLocal` functions provide
implementations for saving and loading Shiny bookmark state to a local
directory. These functions can be set as the saving and loading
interfaces for Shiny bookmarking using
[`shiny::shinyOptions()`](https://rdrr.io/pkg/shiny/man/shinyOptions.html)..
While these callback functions are set by default when initializing a
new instance of `StorageClass`, certain Shiny application structures
such as applications created with the `golem` R package require these
callbacks to be defined as part of the `onStart` argument in
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Usage

``` r
saveInterfaceLocal(id, callback)

loadInterfaceLocal(id, callback)
```

## Arguments

- id:

  character string for session ID.

- callback:

  function to call with the path to save/load the bookmark state.
