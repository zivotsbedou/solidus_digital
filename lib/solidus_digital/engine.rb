# frozen_string_literal: true

module SolidusDigital
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name "solidus_digital"

    initializer "solidus_digital.zeitwerk_ignore_deface_overrides", before: :eager_load! do |app|
      app.autoloaders.main.ignore(root.join("app/overrides"))
    end

    initializer "solidus_digital.pub_sub", after: "spree.core.pub_sub" do |app|
      app.reloader.to_prepare do
        Spree::Bus.register(:digital_links_created)
        SolidusDigital::DeliverySubscriber.new.subscribe_to(Spree::Bus)
      end
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
