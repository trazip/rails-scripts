name = ask("What is the name of your app?")
description = ask("What is the description of your app?")

# Add routes if they don't exist
routes_content = <<-RUBY
  get "webmanifest"    => "pwa#manifest"
  get "service-worker" => "pwa#service_worker"
RUBY

inject_into_file 'config/routes.rb', before: /end$/ do
  routes_content unless File.read('config/routes.rb').include?(routes_content)
end

# Create controller if it doesn't exist
unless File.exist?('app/controllers/pwa_controller.rb')
  create_file 'app/controllers/pwa_controller.rb' do
    <<~RUBY
class PwaController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection

  def service_worker
  end

  def manifest
  end
end
    RUBY
  end
end

# Create views directory if it doesn't exist
FileUtils.mkdir_p('app/views/pwa') unless Dir.exist?('app/views/pwa')

# Create manifest file if it doesn't exist
unless File.exist?('app/views/pwa/manifest.json.erb')
  create_file 'app/views/pwa/manifest.json.erb' do
    <<~ERB
{
  "name": "#{name}",
  "icons": [
    {
      "src": "<%= image_url("app-icon-192.png") %>",
      "type": "image/png", 
      "sizes": "192x192"
    },
    {
      "src": "<%= image_url("app-icon-512.png") %>",
      "type": "image/png",
      "sizes": "512x512"
    },
    {
      "src": "<%= image_url("app-icon-512.png") %>",
      "type": "image/png",
      "sizes": "512x512",
      "purpose": "maskable"
    }
  ],
  "start_url": "/",
  "display": "standalone",
  "scope": "/",
  "description": "#{description}",
  "theme_color": "#ffffff",
  "background_color": "#ffffff"
}
    ERB
  end
end

# Create service worker file if it doesn't exist
unless File.exist?('app/views/pwa/service_worker.js')
  create_file 'app/views/pwa/service_worker.js' do
    "console.log('Hello from the service worker!')"
  end
end

# Download icons if they don't exist
unless File.exist?('app/assets/images/app-icon-192.png')
  run "curl -L https://raw.githubusercontent.com/trazip/pwa_setup/master/images/app-icon-192.png -o app/assets/images/app-icon-192.png"
end

unless File.exist?('app/assets/images/app-icon-512.png')
  run "curl -L https://raw.githubusercontent.com/trazip/pwa_setup/master/images/app-icon-512.png -o app/assets/images/app-icon-512.png"
end

# Remove existing viewport meta tag if it exists
gsub_file 'app/views/layouts/application.html.erb', /<meta name="viewport".*?>(\r?\n|\r)?/, ''


# Add meta tags if they don't exist
meta_content = <<-HTML
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no, user-scalable=no">
    <meta name="mobile-web-app-capable" content="yes">
    <%= tag.link rel: "manifest", href: webmanifest_path(format: :json) %>
    <%= tag.link rel: "icon", href: image_url("app-icon-512.png"), type: "image/png" %>
    <%= tag.link rel: "apple-touch-icon", href: image_url("app-icon-512.png") %>

HTML

inject_into_file 'app/views/layouts/application.html.erb', before: '<%= csrf_meta_tags %>' do
  meta_content unless File.read('app/views/layouts/application.html.erb').include?(meta_content)
end

say "PWA setup completed successfully!", :green
