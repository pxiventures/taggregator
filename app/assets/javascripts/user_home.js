(function() {

  window.App = window.App || {};
  App.Collections = App.Collections || {};
  App.Models = App.Models || {};
  App.Views = App.Views || {};

  // Public: A logged in user's photo.
  App.Models.UserPhoto = Backbone.Model.extend({

    initialize: function() {
      _.bindAll(this, 'addToCampaign');
    },

    // Public: Add this photo to a campaign. Isn't used for
    // now.
    addToCampaign: function(campaign) {
      Analytics.trackEvent('Photo', 'Add to Campaign', 'started');
      $.ajax({
        url: Routes.add_to_campaign_photo_path(this.get("id")),
        type: "POST",
        data: {
          campaign_id: campaign.get("id")
        },
        // We reload the page for now; a cop-out because other parts of the
        // page change.
        success: _.bind(function() { window.location.reload(true); }, this),
        error: function(xhr) {
          Analytics.trackEvent('Photo', 'Add to Campaign', 'failed');
          alert("Sorry, there was a problem adding that photo to that competition: " + xhr.responseText);
        },
        dataType: "json"
      });
    }

  });

  App.Collections.UserPhotos = Backbone.Collection.extend({
    model: App.Models.UserPhoto,

    url: Routes.photos_path({format: "json"})
  });

  App.Campaigns = new App.Collections.Campaigns();
  App.UserPhotos = new App.Collections.UserPhotos();

  // Public: A view of a user's photos; these can be drag & dropped onto
  // campaigns to tag them.
  App.Views.UserPhoto = Backbone.View.extend({

    className: "photo",

    initialize: function() {
      this.model.view = this;

      _.bindAll(this, 'addToCampaign');

      this.listenTo(this.model, 'change', this.render);

    },

    render: function() {
      var json = this.model.toJSON();
      this.$el.html(ich.userPhotoTemplate(json)).css('background-image', 'url(' + this.model.get('thumbnail_url') + ')').draggable({
        revert: true,
        scroll: false,
        helper: 'clone'
      }).data('view', this);
      return this;
    },
    
    // Public: Add the photo this view belongs to to a campaign. Shows a modal
    // for confirmation first.
    addToCampaign: function(campaign) {
      // Open modal
      var modalData = {
        caption: this.model.get("caption"),
        campaign: campaign.get("name"),
        tags: campaign.tagsAsSentence()
      };

      $("#campaignAddModal .modal-body").html(ich.modalCampaignAddTemplate(modalData));
      $("#campaignAddModal .add").on("click", _.bind(function(e) {
        this.model.addToCampaign(campaign);
        $("#campaignAddModal").modal('hide');
      }, this));
      $("#campaignAddModal").modal("show").on("hide", function() {
        $("#campaignAddModal .add").off("click");
      });
      Analytics.trackEvent('Photo', 'Add to Campaign', 'Modal shown');
    }




  });

  App.Views.App = Backbone.View.extend({

    initialize: function() {
      this.listenTo(App.Campaigns, 'add', this.addOneCampaign);
      this.listenTo(App.Campaigns, 'reset', this.addAllCampaigns);

      this.listenTo(App.UserPhotos, 'add', this.addOneUserPhoto);
      this.listenTo(App.UserPhotos, 'reset', this.addAllUserPhotos);

    },

    addOneUserPhoto: function(photo) {
      var view = new App.Views.UserPhoto({model: photo});
      this.$("#yourphotos").append(view.render().el);
    },

    addAllUserPhotos: function() {
      this.$("#yourphotos").empty();
      this.$("#yourphotos").append(ich.photoHelpTextTemplate());
      App.UserPhotos.each(this.addOneUserPhoto);
    },
    
    addOneCampaign: function(campaign) {
      var view = new App.Views.Campaign({model: campaign});

      this.$("#campaigns").append(view.render().el);
    
    },

    addAllCampaigns: function() {
      this.$("#campaigns").empty();
      App.Campaigns.each(this.addOneCampaign, this);
    },

    getParticipatingIn: function() {

      $.ajax({
        type: "GET",
        url: Routes.participating_in_photos_path(),
        success: _.bind(function(html) {
          this.$(".participating-photos").html(html);
        }, this),
        dataType: "html"
      });
    },

  });

  $(function() {
    App.MainView = new App.Views.App({el: $("body")});

    App.MainView.getParticipatingIn();

    App.Campaigns.reset(App.InitialData);
    App.UserPhotos.fetch();

  });


})();
