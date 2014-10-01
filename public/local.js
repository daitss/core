$(document).ready(function(){

  // highlight the link at the top with the current location
  if (location.pathname == "/") {
    $("nav a[href='" + location.pathname + "']").addClass("active");
  } else {
    $("nav a[href^='" + location.pathname + "']").addClass("active");
  }
  
  // set user type and account to default as blank
  document.getElementById("user-type").selectedIndex = -1;
  document.getElementById("user-account").selectedIndex = -1;

});

function confirmClick() {
  return confirm("Are you sure?");
};


