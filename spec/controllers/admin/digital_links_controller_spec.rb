# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::Admin::DigitalLinksController do
  stub_authorization!

  let(:order) { create(:order_ready_to_ship, line_items_attributes: [{variant: create(:variant, digitals: [create(:digital)])}]) }
  let!(:digital_link) { create(:digital_link, access_counter: 3, line_item: order.line_items.first) }

  it "resets the download limits and e-mails the links again" do
    expect {
      post :reset, params: {order_id: order.number}
    }.to have_enqueued_mail(Spree::DigitalMailer, :download_links_email).with(order)

    expect(digital_link.reload.access_counter).to eq(0)
    expect(response).to redirect_to(spree.edit_admin_order_path(order))
  end
end
