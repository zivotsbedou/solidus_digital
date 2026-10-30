# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::DigitalsController, type: :controller do
  describe "#show" do
    let(:order) { create(:order_ready_to_ship, line_items_attributes: [{variant: digital.variant}]) }
    let(:digital) { create(:digital) }
    let(:link) { create(:digital_link, digital: digital, line_item: order.line_items.first) }

    it "raises not found for an unknown secret" do
      expect { get :show, params: {secret: "NotReal00000000000000000000000"} }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "sends the file and counts the download" do
      get :show, params: {secret: link.secret}

      expect(response.body).to eq("digital content")
      expect(response.headers["Content-Disposition"]).to start_with("attachment; filename=\"#{digital.attachment.filename}\"")
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(link.reload.access_counter).to eq(1)
    end

    it "refuses links of unpaid orders" do
      stub_spree_preferences(layout: "application")
      order.update!(payment_state: "balance_due")
      get :show, params: {secret: link.secret}

      expect(response).to have_http_status(:forbidden)
      expect(response).to render_template(:unauthorized)
    end

    context "with a protected PDF" do
      let(:digital) { create(:digital, :drm) }

      it "sends the buyer copy with its license page" do
        get :show, params: {secret: link.secret}

        expect(SolidusDigital::TestingSupport.pdf_pages(response.body).second).to include("Licensed to: #{order.email}")
      end
    end
  end
end
