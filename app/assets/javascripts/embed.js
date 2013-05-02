//= require jquery
//= require jquery_ujs
//= require underscore
//= require backbone

$(function() {

  window.atBottom = false;

  var page = 1,
      loading = false;

  function nearBottomOfPage() {
    return $(window).scrollTop() > $(document).height() - $(window).height() - 400;
  }

  $(window).scroll(_.throttle(function(){
    if (loading || atBottom) {
      return;
    }

    if(nearBottomOfPage()) {
      loading=true;
      page++;
      $.ajax({
        url: window.location,
        data: {page: page},
        type: 'get',
        dataType: 'script',
        success: function() {
          loading=false;
        }
      });
    }
  }, 250));

});
