$(function(){
  if( $.browser.msie && (window.location.pathname == "/") ){
    window.location = "/msie.html";
  }
  
  $(".date").humaneDates();
});


