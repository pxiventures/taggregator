// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require modernizr
//= require jquery
//= require jquery_ujs
//= require jquery.tappable
//= require underscore
//= require backbone
//= require messenger
//= require ICanHaz
//= require jquery-ui
//= require js-routes
//= require jquery.tokeninput
//= require moment
//= require bootstrap-transition
//= require bootstrap-modal
//= require bootstrap-tooltip
//= require bootstrap-button
//= require bootstrap-dropdown
//= require bootstrap-carousel
//= require analytics
//= require photo
//= require campaigns

// Load Twitter widget JS asynchronously
window.twttr = (function (d,s,id) {
  var t, js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return; js=d.createElement(s); js.id=id;
  js.src="//platform.twitter.com/widgets.js"; fjs.parentNode.insertBefore(js, fjs);
  return window.twttr || (t = { _e: [], ready: function(f){ t._e.push(f) } });
}(document, "script", "twitter-wjs"));

// Configure Messenger
Messenger.options = {
	extraClasses: 'messenger-fixed messenger-on-top',
	theme: 'block',
  messageDefaults: {
    showCloseButton: true,
    retry: { allow: false }
  }
};

// Public: JS implementation of Rails #to_sentence.
//
// Example - 
//  [1, 2, 3].to_sentence();
//  # => "1, 2 and 3"
Array.prototype.to_sentence = function() {
  return this.join(", ").replace(/,\s([^,]+)$/, ' and $1');
};

// Public: Javascript implementation of Rails #capitalize.
String.prototype.capitalize = function() {
  return this.charAt(0).toUpperCase() + this.slice(1);
};

// Public: Show the first help modal.
window.showHelp = function(e) {
  $("#helpModals .modal:first").modal("show");
  Analytics.trackEvent("Help", "Shown", (e ? "Clicked" : "Programatically initiated"));
  if (e) { e.preventDefault(); }
};

// Bind the help modal to the help link.
$(function() {
  $("a#help").click(window.showHelp);

  // Initialize help modal buttons.
  $("#helpModals .modal .next").on("click", function(e) {
    var currentModal = $(this).parents(".modal");
    currentModal.modal("hide");
    currentModal.next().modal("show");
    Analytics.trackEvent("Help", "Next", currentModal.index()+1);
    e.preventDefault();
  });

  // Mobile navigation JS
  $("#toggle-mobile-nav").tappable(function(e) {
    $(".mobile-nav li:nth-child(n+2)").toggleClass("visible");
    e.preventDefault();
  });
});
