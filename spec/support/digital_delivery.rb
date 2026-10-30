# frozen_string_literal: true

require 'pdf-reader'

RSpec.configure do |config|
  config.include ActiveJob::TestHelper
  config.before do
    ActiveJob::Base.queue_adapter = :test
    ActionMailer::Base.default_url_options = { host: 'shop.example.com', protocol: 'https' }
  end
end

module SolidusDigital
  module TestingSupport
    # Reads a protected PDF the way a viewer does: decrypt with the empty user password, then extract text.
    def self.pdf_pages(data)
      Dir.mktmpdir do |dir|
        File.binwrite("#{dir}/in.pdf", data)
        system('qpdf', '--decrypt', "#{dir}/in.pdf", "#{dir}/out.pdf", exception: true)
        PDF::Reader.new("#{dir}/out.pdf").pages.map(&:text)
      end
    end
  end
end
