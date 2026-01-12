require 'rack'

use Rack::Static, urls: [''], root: 'build', index: 'index.html'

run lambda { |env|
  path = env['PATH_INFO']
  file = File.join('build', path)
  
  # Try with .html extension if no extension
  if !File.exist?(file) && !path.include?('.')
    file = File.join('build', "#{path}.html")
  end
  
  if File.exist?(file) && !File.directory?(file)
    [200, {'Content-Type' => Rack::Mime.mime_type(File.extname(file))}, [File.read(file)]]
  else
    [404, {'Content-Type' => 'text/html'}, ['Not Found']]
  end
}
