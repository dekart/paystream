PayStream SMS Payment Processor
===============================

Small controller & view extension to ease [PayStream](http://paystream.ru/)
SMS payment processing.

Usage
-----

1) Configure your partner in the config/paystream.yml file:

    development:
      prefix: "+123"
      secret: "mysupersecret123"
    production:
      wallet: "+456"
      secret: "myproductionsecret"

2) Create new model to store received SMS messages, include Paystream::PaymentModel module,
and define action codes:

    class SmsPayment < ActiveRecord::Base
      include Paystream::PaymentModel

      self.action_codes = {
        "01" => :my_action,
        "02" => :other_action
      }
    end

  Sample migration can be found in the db/migrate/001_create_sms_payments.rb file

3) Add new action to your payment controller:

    class PaymentsController < ApplicationController
      # Disable forgery protection for action
      skip_before_filter :verify_authenticity_token, :only => :sms_payment

      ...

      def sms_payment
        paystream(SmsPayment) do |sms|
          sms.action(:my_action) do |payment|
            # Your action code goes here

            sms.reply "This is my reply" # Sends well-formatted reply to SMS sender
          end

          sms.action(:other_action) do |payment|
            # Other action
          end
        end
      end
    end

4) Add acction to your routes:

    ActionController::Routing::Routes.draw do |map|
      ...

      map.resources :payments, :collection => {:sms_payment => :post}

      ...
    end

5) Profit! :)

Avanced Usage
-------------

You can define custom blocks to dispatch uncommon situations. In your controller:

  def sms_payment
    paystream(SmsPayment) do |sms|
      ...

      sms.error(:unknown_action) do |payment|
        # Dispatch all unknown action codes here
      end

      sms.error(:unconfirmed_payment) do |payment|
        # Dispatch calls with MT payment logic
      end

      sms.error(:invalid_request) do |payment|
        # Dispatch requests with wrong secret
      end
    end
  end

You can automatically generate prefixed payment codes to display in your views:

    <%= SmsPayment.action_code(:my_action) %> #=> +12301
    <%= SmsPayment.action_code(:my_action, "command") %> #=> +12301command

Testing
-------

No tests yet :( You can fork this plugin at GitHub (http://github.com/dekart/paystream)
and add your own tests. I'll be happy to accept patches!

Installing the plugin
------------------

    ./script/plugin install git://github.com/dekart/paystream.git

Credits
-------

Written by [Alex Dmitriev](http://railorz.ru)
