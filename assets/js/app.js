$(function(){
  if( $.browser.msie && (window.location.pathname == "/") ){
    window.location = "/msie.html";
  }
  
  $(".date").humaneDates();
});


// disqus comments count
//
// (function() {
//   var links = document.getElementsByTagName('a');
//   var query = '?';
//   for(var i = 0; i < links.length; i++) {
//     if(links[i].href.indexOf('#disqus_thread') >= 0) {
//       query += 'url' + i + '=' + encodeURIComponent(links[i].href) + '&';
//     }
//   }
//   document.write('<script charset="utf-8" type="text/javascript" src="http://disqus.com/forums/#{disqus_shortname}/get_num_replies.js' + query + '"></' + 'script>');
// })();