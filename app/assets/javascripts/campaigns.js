(function() {

  window.App = window.App || {};
  App.Collections = App.Collections || {};
  App.Models = App.Models || {};
  App.Views = App.Views || {};

  // A campaign is a group of photos
  App.Models.Campaign = Backbone.Model.extend({

    initialize: function() {
      this.photos = new App.Collections.Photos([], {campaign: this});
    },

    // Public: Returns all the tags for this campaign as a sentence.
    tagsAsSentence: function() {
      return _.map(this.get("tags"), function(tag) {
        return "#" + tag.name;
      }).to_sentence();
    }

  });

  App.Collections.Campaigns = Backbone.Collection.extend({
    model: App.Models.Campaign,

    url: Routes.campaigns_path()

  });

  App.Views.Campaign = Backbone.View.extend({

    className: "campaign span4",
    templateName: "campaignTemplate",

    initialize: function() {
      this.model.view = this;

      this.listenTo(this.model.photos, 'add', this.addOnePhoto);
      this.listenTo(this.model.photos, 'reset', this.addAllPhotos);

      _.bindAll(this, 'droppedOn');

    },

    render: function() {
      var json = this.model.toJSON();
      json.end_date = moment(json.end_date).fromNow();

      json.tags_sentence = this.model.tagsAsSentence();

      this.$el.html(ich[this.templateName](json)).droppable({
        drop: this.droppedOn
      });

      // Scroll is not bubbled, so we have to bind it directly.
      this.$(".photo-wrapper").scroll(_.bind(_.once(this.trackScroll), this));

      this.model.photos.fetch();

      return this;
    },

    addOnePhoto: function(photo) {
      var view = new App.Views.Photo({model: photo});
      this.$(".photos").append(view.render().el);
    },

    addAllPhotos: function() {
      this.$(".photos").empty();
      if (this.model.photos.length === 0) {
        this.$(".photos").text("No photos in this competition yet. Go out there and take one!");
        this.$(".view-more").hide();
      } else {
        this.model.photos.each(this.addOnePhoto, this);
      }
    },

    // Internal: Callback when a photo is dropped onto this campaign.
    droppedOn: function(event, ui) {
      var photoView = ui.draggable.data('view');
      photoView.addToCampaign(this.model);
    },

    // Internal: Track when the leaderboard is scrolled & fire off an analytics
    // event.
    //
    // Only track once.
    trackScroll: function() {
      Analytics.trackEvent('Leaderboard', 'Scrolled', this.model.get('name'));
    }

  });

})();
