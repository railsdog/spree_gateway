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


module Spree
  class Gateway::Realex < Gateway

    preference :login, :string
    preference :password, :string

    def provider_class
      ActiveMerchant::Billing::RealexGateway
    end
  end
end
