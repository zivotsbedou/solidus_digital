# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::DigitalMailer do
  it 'lists one link per download with its limits' do
    order = create(:order_ready_to_ship, line_items_attributes: [{ variant: create(:variant, digitals: [create(:digital)]) }])
    order.digital_line_items.each(&:create_digital_links)
    mail = described_class.download_links(order)

    expect(mail.subject).to eq("#{order.store.name}: downloads for order #{order.number}")
    expect(mail.from).to eq([order.store.mail_from_address])
    expect(mail.text_part.body.decoded).to include("https://shop.example.com/digital/#{order.digital_links.first.secret}", 'Each link works for 2 days.')
  end
end
