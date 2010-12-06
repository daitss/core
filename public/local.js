$(document).ready(function(){

  // highlight the link at the top with the current location
  if (location.pathname == "/") {
    $("nav a[href='" + location.pathname + "']").addClass("active");
  } else {
    $("nav a[href^='" + location.pathname + "']").addClass("active");
  }

});
