(function() {

  window.App = window.App || {};
  App.Collections = App.Collections || {};
  App.Models = App.Models || {};
  App.Views = App.Views || {};

  // A photo is...a photo...These belong in a collection that belongs to a
  // campaign. Relations are a bit tricky in Backbone but not impossible.
  App.Models.Photo = Backbone.Model.extend({

    initialize: function() {
      _.bindAll(this, 'checkLiked', 'checkFollowing', 'toggleLike',
        'toggleFollow');
      if (!gon.logged_in) {
        this.set("user_has_liked", false);
        this.set("user_is_following", "none");
      }
    },

    // Internal: Check if the user has liked this photo or not - update model
    // data accordingly.
    checkLiked: function() {
      $.ajax({
        type: "GET",
        url: "https://api.instagram.com/v1/media/" + this.get("uid"),
        data: {
          access_token: gon.access_token
        },
        success: _.bind(function(data) {
          this.set("user_has_liked", data.data.user_has_liked);
        }, this),
        // This won't get called right now because we are using JSONP anyway.
        error: _.bind(function() {
          // Default to false.
          this.set("user_has_liked", false);
        }, this),
        dataType: "jsonp"
      });
    },

    // Internal: Check if the user followed this photo's user or not - update
    // model data accordingly.
    checkFollowing: function() {
      $.ajax({
        type: "GET",
        url: "https://api.instagram.com/v1/users/" + this.get("user").uid + "/relationship",
        data: {
          access_token: gon.access_token
        },
        success: _.bind(function(data) {
          // Will be one of "follows", "requested", or "none"
          this.set("user_is_following", data.data.outgoing_status);
        }, this),
        // This won't get called right now because we are using JSONP anyway.
        error: _.bind(function() {
          // Default to false.
          this.set("user_is_following", "none");
        }, this),
        dataType: "jsonp"
      });

    },

    // Public: Toggle liking this photo.
    toggleLike: function() {
      var method;
      if (this.get('user_has_liked')) {
        method = "DELETE";
      } else {
        method = "POST";
      }
      Analytics.trackEvent('Photo', 'Toggled Like', method);

      $.ajax({
        type: method,
        url: Routes.like_user_path(),
        data: {
          uid: this.get("uid")
        },
        success: _.bind(function(data) {
          this.set("user_has_liked", !this.get("user_has_liked"));
        }, this),
        error: _.bind(function() {
          alert("Whoops! Something went wrong trying to do that. Refresh the page and try again");
          Analytics.trackEvent('Photo', 'Toggled Like', 'failed');
        }, this)
      });
    },

    toggleFollow: function() {
      data = {uid: this.get("user").uid};

      switch (this.get("user_is_following")) {
        case "none":
          data.relationship_action = "follow";
          break;
        case "follows":
          data.relationship_action = "unfollow";
          break;
        default:
          data.relationship_action = "follow";
      }

      Analytics.trackEvent('Photo', 'Toggled Follow', data.relationship_action);

      $.ajax({
        type: "POST",
        url: Routes.follow_user_path(),
        data: data,
        success: _.bind(function(data) {
          this.set("user_is_following", data.data.outgoing_status);
        }, this),
        error: _.bind(function() {
          alert("Whoops! Something went wrong trying to do that. Refresh the page and try again");
          Analytics.trackEvent('Photo', 'Toggled Follow', 'failed');
        }, this)
      });
    },

    comment: function(text, callback) {
      if (typeof callback === "undefined") { callback = function() {}; }
      Analytics.trackEvent('Photo', 'Add comment', 'Submitting comment');
      $.ajax({
        type: "POST",
        url: Routes.comment_user_path(),
        data: {
          uid: this.get("uid"),
          text: text
        },
        success: function() {
          Analytics.trackEvent('Photo', 'Add comment', 'Succeeded');
          callback();
        },
        // This won't get called right now because we are using JSONP anyway.
        error: function() {
          alert("Whoops! Something went wrong trying to do that. Refresh the page and try again");
          Analytics.trackEvent('Photo', 'Add comment', 'Failed');
        }
      });
    }

  });

  App.Collections.Photos = Backbone.Collection.extend({
    model: App.Models.Photo,

    url: function() {
      return Routes.leaderboard_campaign_path(this.campaign.get("id"));
    },

    initialize: function(models, options) {
      if (typeof options.campaign === "undefined" || typeof options.campaign === "undefined") {
        throw "You must supply a Campaign model to a Photo collection.";
      }
      this.campaign = options.campaign;
    }

  });

  App.Views.Photo = Backbone.View.extend({

    className: "photo",
    templateName: "leaderboardPhotoTemplate",

    events: {
      'mouseenter': 'hover',
      'click a.like': 'like',
      'click a.follow': 'follow',
      'click a.comment': 'comment' 
    }, 

    initialize: function() {
      _.bindAll(this, 'hover');

      this.model.view = this;

      this.listenTo(this.model, 'change:user_has_liked', this.render);
      this.listenTo(this.model, 'change:user_is_following', this.render);

    },

    // Internal: Do stuff on hover (update photo info). Only do it once.
    hover: function() {
      if (!this.hovered) {
        this.model.checkLiked();
        this.model.checkFollowing();
        this.hovered = true;
        this.$(".icon-spinner").addClass("icon-spin");
      }
      Analytics.trackEvent('Photo', 'Hovered');
    },

    render: function() {
      var json = this.model.toJSON();
      json.score = json.score.toFixed(2);
      if (json.user_has_liked === false || Modernizr.touch) {
        json.like = "<i class='icon-thumbs-up'></i>";
      } else if (typeof json.user_has_liked === "undefined") {
        json.like = "<i class='icon-spinner'></i>";
      } else {
        // Not false, not undefined, must be true.
        json.like = "<i class='icon-thumbs-down'></i>";
      }

      if (Modernizr.touch) {
        json.following = "Follow";
      } else if (typeof json.user_is_following === "undefined") {
        json.following = "<i class='icon-spinner'></i>";
      } else {
        switch(json.user_is_following) {
          case "none":
            json.following = "Follow";
            break;
          case "requested":
            json.following = "Requested";
            break;
          case "follows":
            json.following = "Unfollow";
            break;
          default:
            json.following = "Follow";
        }
      }

      if (this.model.collection) {
        json.position = this.model.collection.indexOf(this.model) + 1;
      }

      this.$el.html(ich[this.templateName](json));

      if (!json.position) {
        this.$(".position").hide();
      }


      return this;
    },

    like: function(e) {
      if (!gon.logged_in) {
        $("#signinModal").modal('show');
      } else {
        this.model.toggleLike();
      }
      e.preventDefault();
    },

    follow: function(e) {
      if (!gon.logged_in) {
        $("#signinModal").modal('show');
      } else {
        if (this.model.get("user_is_following") !== "requested") {
          this.model.toggleFollow();
        }
      }
      e.preventDefault();
    },

    comment: function(e) {
      if (!gon.logged_in) {
        $("#signinModal").modal('show');
      } else {
        var modalData = {
          caption: this.model.get("caption"),
          image: this.model.get("thumbnail_url")
        };

        $("#commentModal .modal-body").html(ich.modalCommentTemplate(modalData));
        $("#commentModal .comment").on("click", _.bind(function(e) {
          var text = $("#comment-text").val(),
              button = $(e.target);
          button.button();
          if (text === "") {
            alert("You forgot to write the comment!");
          } else {
            button.button('loading');
            this.model.comment($("#comment-text").val(), function() {
              $("#commentModal").modal("hide");
              button.button('reset');
            });
          }
        }, this));
        $("#commentModal").modal("show").on("hide", function() {
          $("#commentModal .comment").off("click");
        });
        Analytics.trackEvent('Photo', 'Add comment', 'Modal shown');
      }
      e.preventDefault();
    }

  });


})();
