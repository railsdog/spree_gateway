#
# RealEx (GB)  is a supported Gateway by active_merchant
#
#     https://github.com/Shopify/active_merchant#supporte#d-direct-payment-gateways
#
# ActiveMerchant::Billing::RealexGateway :
#
# Realex works using the following
#
#   login - The unique id of the merchant
#   password - The secret is used to digitally sign the request
#   account - This is an optional third part of the authentication process and is used if the merchant wishes to
#   distinguish cc traffic from the different  sources by using a different account. This must be created in advance
Spree::CreditCard.class_eval do
  # https://github.com/Shopify/active_merchant/blob/master/lib/active_merchant/billing/gateways/realex.rb#L239
  attr_accessor :issue_number
end

module Spree
  class Gateway::Realex < Gateway

    preference :login, :string
    preference :password, :string
    preference :account, :string

    def provider_class
      ActiveMerchant::Billing::RealexGateway
    end

    def purchase(money, creditcard, gateway_options)
      provider.purchase(money, creditcard, gateway_options)
    end

    def authorize(money, creditcard, gateway_options)
      provider.authorize(money, creditcard, gateway_options)
    end

    def capture(money, response_code, gateway_options)
      provider.capture(money, response_code, gateway_options)
    end

  end
end
