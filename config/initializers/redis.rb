# Pre-emptively require some code. There is a race condition open with
# threaded code and Rails right now:
# https://github.com/rails/rails/issues/7770
require "active_record/relation"
require 'active_record/associations/association_scope'

$redis = Redis.new
