# Taggregator

This is the open-source version of the code that powers [Tagstar][]. It is
rough around the edges and may not be platform-independent, as it is largely
the same as it was when it was running in a single environment for Tagstar.

Taggregator is probably not that useful as a project. Rather, it is a building
block for making something new.

## What is it?

Taggregator is a tool for running competitions (campaigns) on Instagram. It
uses a combination of the Instagram REST and realtime APIs to pull in photos
around hashtags, score them according to a formula, and present them in a 
leaderboard for users to see. Users can also opt to receive a daily email
(sent manually by admins) that contain the latest competitions.

**Everything is done in sets of 3**. The design works with 3 active
competitions at a time and has not been tested for any other scenario.

## Requirements

Taggregator should run fine on Heroku provided you ensure you have enough
addons to meet the following requirements:

 - Ruby 2.0.0.
 - Rails 3.2.13.
 - PostgreSQL.
 - Redis.
 - Memcache.
 - Instagram app credentials with permission to use the commenting API.
 - A service for sending email in production. [SendGrid][] is set up by default.

## Configuration

The app is configured through a combination of YAML in `config/config.yml` and
environment variables for more sensitive configuration (like credentials and
API keys). Configuration variables are well documented in `config/config.yml`,
you should make sure all environment configuration variables are set; the app
does not check.

The first user that signs in will be an admin user.

## Scheduled tasks

In development `clockwork` will queue photo metric updates, and check the
status of the daily email (whether it needs to be sent or not).

In production, it is up to you how you want to achieve the same results. You
can run clockwork in the background, or if you're on Heroku you can achieve
satisfactory results using their scheduler (though metrics won't be updated as
fast as is ideal).

Look at `config/clockwork.rb` to see what needs to be run regularly. There are
corresponding rake tasks available.

## Code warnings

### Design assets

You'll notice a lot of the design has reference to 'Tagstar', and is very
specific to how Tagstar was origianlly designed. You will need to remove and
change this (obviously) to make something that suits you.

### Instagram comment API

The app assumes that your Instagram API credentials have the ability to comment
on photos. This is something you have to apply to Instagram to receive. If you
don't have this, expect a few exceptions and unexpected behaviour. It should
be easy to find where this happens (try `app/models/photo.rb`).

### Getting photos in to Taggregator.

Taggregator has the ability to subscribe to realtime updates on new photos from
Instagram. This is a manual process an admin can do, and whether or not the
new photos match a campaign, they will be inserted into the database. Therefore
it is important to _be careful_ as if you use popular hashtags not only will
you flood your DB with photos but you will also hit your Instagram API limit
immediately.

Instead, the recommended way of running Taggregator is as follows:

 - Choose a default hashtag (`config/config.yml`) that is uncommonly used
   day-to-day e.g. #taggregator. 
 - Create a realtime subscription to this hashtag.
 - Use that hashtag in conjunction with others across all your campaigns. That
   way you will receive all the photos for those campaigns without also
   receiving others, and they will probably be photos from your users rather
   than random people.

### JSON Serialization.

Taggregator makes use of ActiveModel serializers (see `app/serializers`), but
has to do a bunch of ugly things to make them useable outside the standard
situations they are intended for. I'm not sure they were the best choice to
solve the problem of custom JSON. There are better solutions out there now.

### Deploying on Heroku.

It is possible to deploy Taggregator on Heroku, but it is largely untested.
To circumvent the need for a worker, Sidekiq is spawned as part of the Unicorn
configuration. This means you must pay careful attention to your dyno memory
usage as it may end up being too high.

You can configure the number of Unicorn workers with the `WEB_CONCURRENCY`
environment variable. Default if unset is 3 (see `config/unicorn.rb`).

There is an issue with `js-routes` and precompiling assets on Heroku.
See [this tip](https://coderwall.com/p/ljnwpg) for a possible solution.

### Alternative landing pages

There are 3 landing pages in `app/views/campaigns/split_tests`.
`original_design` statistically converted the most users, so that is set as the
default. You can swap by changing which one is rendered in the campaigns
controller.

For split testing, we used [the split gem](https://github.com/andrew/split).

## Running tests

`guard` will load Spork and autorun your tests any time a file changes.
You'll need to run `foreman` first too to load up stuff like Redis.

If you have Growl installed and listening on localhost, you will also get
notifications.

## Looking at emails that are sent during development

When running in development, emails are not actually sent. Instead they are
caught by [MailCatcher](http://mailcatcher.me/) which is started up with
Foreman along with the rest of the app.

To view emails sent locally, visit
[http://localhost:1080](http://localhost:1080).

[Tagstar]: http://tagstar.co
[SendGrid]: https://addons.heroku.com/sendgrid
