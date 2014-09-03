require 'spec_helper'
require 'pry'

describe Spree::Gateway::Realex do

  before do
    Spree::Gateway.update_all(active: false)
    Spree::Config[:currency] = "GBP"
    @gateway = Spree::Gateway::Realex.create!(name: 'Realex Gateway', environment: 'sandbox', active: true)
    @gateway.preferences = {
        login: 'X',
        password: 'Y'
    }
    @gateway.save!

    country = create(:country, name: 'United Kingdom', iso_name: 'UNITED KINGDOM', iso3: 'GBR', iso: 'GB', numcode: 826)
    state   = create(:state, name: 'Bristol', abbr: 'BS', country: country)
    address = create(:address,
      firstname: 'John',
      lastname:  'Doe',
      address1:  "St George's Rd",
      city:      'Bristol',
      zipcode:   'BS1 5UA',
      phone:     '(555)555-5555',
      state: state,
      country: country
    )

    order = create(:order_with_totals, bill_address: address, ship_address: address)

    #random order id to avoid duplicate transactions
    timestamp = Time.now.strftime '%Y%m%d%H%M%S'
    order_id = "#{timestamp}#{rand 1000}"
    order.update_attribute('id', order_id)
    order.update!

    # https://github.com/Shopify/active_merchant/blob/master/lib/active_merchant/billing/gateways/realex.rb#L239
    Spree::CreditCard.class_eval do
      attr_accessor :issue_number
    end
    @credit_card = create(:credit_card,
      verification_value: '123',
      number:             '5425232820001308',
      month:              4,
      year:               Time.now.year + 1,
      name:               'Steve Smith',
      cc_type:            'mastercard',
      issue_number:       '1'
    )

    @payment = create(:payment, source: @credit_card, order: order, payment_method: @gateway, amount: 10.00)
    @payment.payment_method.environment = 'test'

    @options = {order_id: order.id}
  end

  context '.provider_class' do
    it 'is a Realex gateway' do
      expect(@gateway.provider_class).to eq ::ActiveMerchant::Billing::RealexGateway
    end
  end

  describe 'authorize' do
    it 'return a success response with an authorization code' do
      result = @gateway.authorize(500, @credit_card, @options)

      expect(result.success?).to be_truthy
      auth_code = [@options[:order_id],
                   result.params['pasref'],
                   result.params['authcode']].join(';')
      expect(result.authorization).to match auth_code
      expect(result.message).to eq 'Successful'
    end

    shared_examples 'a valid credit card' do
      it 'work through the spree payment interface' do
        Spree::Config.set auto_capture: false
        expect(@payment.log_entries.size).to eq(0)

        @payment.process!

        expect(@payment.log_entries.size).to eq(1)
        expect(@payment.state).to eq 'pending'
      end
    end

    context 'when the card is a mastercard' do
      before do
        @credit_card.number = '5425232820001308'
        @credit_card.cc_type = 'mastercard'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end

    context 'when the card is a visa' do
      before do
        @credit_card.number = '4263971921001307'
        @credit_card.cc_type = 'visa'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end

    context 'when the card is a switch' do
      before do
        @credit_card.number = '6331101999990073'
        @credit_card.cc_type = 'switch'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end

    context 'when the card is an amex' do
      before do
        @credit_card.number = '374101012180018'
        @credit_card.verification_value = '1234'
        @credit_card.cc_type = 'amex'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end

    context 'when the card is a solo' do
      before do
        @credit_card.number = '633478111298873700'
        @credit_card.cc_type = 'solo'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end
  end

  context 'purchase' do
    it 'return a success response with an authorization code' do
      result =  @gateway.purchase(500, @credit_card, @options)
      expect(result.success?).to be_truthy
      auth_code = [@options[:order_id],
                   result.params['pasref'],
                   result.params['authcode']].join(';')
      expect(result.authorization).to match auth_code
    end
  end

  context 'void' do
    before do
      Spree::Config.set(auto_capture: true)
    end

    it 'work through the spree credit_card / payment interface' do
      expect(@payment.log_entries.size).to eq(0)
      @payment.process!
      expect(@payment.log_entries.size).to eq(1)
      expect(@payment.state).to eq 'completed'

      @payment.void_transaction!
      expect(@payment.state).to eq 'void'
    end
  end
end