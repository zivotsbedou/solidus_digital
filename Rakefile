# frozen_string_literal: true

require "bundler/gem_tasks"
require "solidus_dev_support/rake_tasks"
SolidusDevSupport::RakeTasks.install

task default: "extension:specs"

# The generated dummy app does not link Solidus backend assets, which the admin views render.
Rake::Task["extension:test_app"].enhance do
  File.open("spec/dummy/app/assets/config/manifest.js", "a") { |manifest| manifest.puts "//= link solidus_backend_manifest.js" }
end
