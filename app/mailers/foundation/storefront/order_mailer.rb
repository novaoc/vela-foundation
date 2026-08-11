# frozen_string_literal: true

module Foundation
  module Storefront
    class OrderMailer < ApplicationMailer
      helper Foundation::StorefrontHelper

      def receipt(order)
        @order = order
        @token = ReceiptAccess.token_for(order)
        headers["Message-ID"] = "<storefront-order-#{order.public_reference}@#{Rails.configuration.x.foundation[:domain]}>"
        mail(to: order.email, subject: "Receipt for order #{order.public_reference}")
      end
    end
  end
end
