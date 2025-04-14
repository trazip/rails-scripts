# Ask for Cloudinary URL

cloudinary_url = ask('Please enter your Cloudinary URL:')

# Check and add dotenv-rails gem
gemfile_path = File.join(Dir.pwd, 'Gemfile')
if File.exist?(gemfile_path)
  gemfile_content = File.read(gemfile_path)

  unless gemfile_content.include?('dotenv-rails')
    inject_into_file "Gemfile", after: "group :development, :test do" do
      "\n  gem \"dotenv-rails\""
    end
  end
end

run 'bundle install'

# Check and create .env file
env_path = File.join(Dir.pwd, '.env')
gitignore_path = File.join(Dir.pwd, '.gitignore')
    
create_file '.env' unless File.exist?(env_path)

# Add .env to .gitignore if not present
if File.exist?(gitignore_path)
  gitignore_content = File.read(gitignore_path)
  unless gitignore_content.include?('.env')
    append_to_file '.gitignore' do
      "\n.env"
    end
  end
end


# Add cloudinary gem
unless gemfile_content.include?('cloudinary')
  inject_into_file "Gemfile", before: "group :development, :test do" do
    <<~RUBY
      gem 'cloudinary', '~> 2.3'

    RUBY
  end
end

# Add Cloudinary URL to .env
env_content = File.read(env_path)
unless env_content.include?('CLOUDINARY_URL')
  append_to_file '.env' do
    "\nCLOUDINARY_URL=#{cloudinary_url}"
  end
end

# Run Active Storage installation
run 'rails active_storage:install'
run 'rails db:drop db:create db:migrate'

# Add Cloudinary configuration to storage.yml
storage_yml_path = File.join(Dir.pwd, 'config', 'storage.yml')
if File.exist?(storage_yml_path)
  storage_content = File.read(storage_yml_path)
  unless storage_content.include?('cloudinary:')
    gsub_file 'config/storage.yml', 
              /local:\n\s+service: Disk\n\s+root: <%= Rails\.root\.join\("storage"\) %>/,
              <<~YAML.chomp
                local:
                  service: Disk
                  root: <%= Rails.root.join("storage") %>

                cloudinary:
                  service: Cloudinary
                  folder: <%= Rails.env %>
              YAML
  end
end

# Update environment files
environment_files = {
  development: File.join(Dir.pwd, 'config', 'environments', 'development.rb'),
  production: File.join(Dir.pwd, 'config', 'environments', 'production.rb')
}

environment_files.each do |env, path|
  if File.exist?(path)
    gsub_file "config/environments/#{env}.rb",
              /config\.active_storage\.service = :local/,
              'config.active_storage.service = :cloudinary'
  end
end

say 'Cloudinary and Active Storage have been successfully installed!', :green
