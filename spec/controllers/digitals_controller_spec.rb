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

    it "counts the download and redirects to a short-lived file URL" do
      get :show, params: {secret: link.secret}

      expect(response).to redirect_to(%r{/rails/active_storage/disk/.+/#{digital.attachment.filename}})
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(link.reload.access_counter).to eq(1)
    end

    it "refuses links of unpaid orders on a standalone page" do
      order.update!(payment_state: "balance_due")
      get :show, params: {secret: link.secret}

      expect(response).to have_http_status(:forbidden)
      expect(response).to render_template(:unauthorized, layout: false)
    end

    it "lets the buyer of a paid order get fresh links by e-mail" do
      link.update_columns(access_counter: 3, created_at: 1.year.ago)

      expect { post :resend, params: {secret: link.secret} }.to have_enqueued_mail(Spree::DigitalMailer, :download_links_email).with(order)
      expect(response).to render_template(:resent, layout: false)
      expect(link.reload.access_counter).to eq(0)
      expect(link).not_to be_expired
    end

    it "sends no links for unpaid orders" do
      order.update!(payment_state: "balance_due")

      expect { post :resend, params: {secret: link.secret} }.not_to have_enqueued_mail(Spree::DigitalMailer, :download_links_email)
      expect(response).to have_http_status(:forbidden)
    end

    context "with a protected PDF" do
      let(:digital) { create(:digital, :drm) }

      it "sends the buyer copy with its license page" do
        get :show, params: {secret: link.secret}

        expect(response.headers["Content-Disposition"]).to start_with('attachment; filename="book.pdf"')
        expect(SolidusDigital::TestingSupport.pdf_pages(File.binread(response.stream.to_path)).second).to include("Licensed to: #{order.email}")
      end

      it "opens it in the browser when configured" do
        stub_spree_preferences(SolidusDigital.config, disposition: "inline")
        get :show, params: {secret: link.secret}

        expect(response.headers["Content-Disposition"]).to start_with('inline; filename="book.pdf"')
      end
    end
  end
end
