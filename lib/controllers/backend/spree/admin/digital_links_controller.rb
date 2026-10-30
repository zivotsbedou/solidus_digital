# frozen_string_literal: true

module Spree
  module Admin
    class DigitalLinksController < Spree::Admin::BaseController
      before_action :load_order

      # Gives the buyer fresh download limits and e-mails the links again.
      def reset
        authorize! :update, @order
        Spree::OrderMutex.with_lock!(@order) { Spree::DigitalLink.resend(@order) }
        flash[:success] = t("spree.digitals.downloads_reset")
        redirect_to spree.edit_admin_order_path(@order)
      rescue Spree::OrderMutex::LockFailed
        flash[:error] = t("spree.order_mutex_admin_error")
        redirect_to spree.edit_admin_order_path(@order)
      end

      private

      def load_order
        @order = Spree::Order.find_by!(number: params[:order_id])
      end
    end
  end
end
