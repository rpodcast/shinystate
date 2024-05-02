$( document ).ready(function() {
    Shiny.addCustomMessageHandler('redirect', function(arg) {
      window.location.assign(arg.url)
    })
  });
  