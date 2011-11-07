$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

require 'cijoe'

# setup middleware
use Rack::CommonLogger

CIJoe::Server.configure do |config|
  puts "CONFIG"
  config.set :project_path, File.expand_path('~/brainstem')
  config.set :show_exceptions, true
  config.set :lock, true
  config.set :use_svn, true
end

 map "/joe" do
    run CIJoe::Server
 end
