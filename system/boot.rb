begin
  require "byebug"
rescue LoadError
end

$LOAD_PATH.unshift File.expand_path("../system", __dir__)

require_relative "../system/site/container"

Site::Container.finalize!
