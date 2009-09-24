module Paystream
  class << self
    def config
      YAML.load_file(File.join(Rails.root, "config", "paystream.yml"))[Rails.env]
    end
  end

  module ControllerExtension
    def self.included(base)
      base.helper_method :paystream
    end

    def paystream(*args, &block)
      unless @paystream
        payment_model = args.first or raise ArgumentError.new("Payment model is not defined")

        @paystream = Processor.new(payment_model, self)
      end

      block_given? ? @paystream.process!(&block) : @paystream
    end

    class Processor
      def initialize(payment_model, controller)
        @payment_model  = payment_model
        @controller     = controller

        @actions  = {}
        @errors   = {}

        if controller.request.query_parameters[:action] == "mt_status"
          @payment = @payment_model.find_by_sms_id(controller.params[:smsid])

          @payment.confirmed = (controller.params[:pay_status] == "ok")
        else
          @payment = @payment_model.new(
            :message        => controller.params[:msg],
            :secret         => controller.params[:skey],
            :sms_id         => controller.params[:smsid],
            :income         => controller.params[:cost],
            :currency       => controller.params[:currency],
            :sent_at        => Time.parse(controller.params[:date]),
            :operator_id    => controller.params[:operator_id],
            :operator_name  => controller.params[:operator],
            :user_cost      => controller.params[:abonent_cost],
            :number         => controller.params[:num],
            :user_number    => controller.params[:user_id],
            :user_currency  => controller.params[:abonent_currency],
            :logic          => controller.params[:logic]
          )
        end
      end

      def action(key, valid_numbers = nil, &block)
        @actions[key] = block
      end

      def error(key, &block)
        @errors[key] = block
      end

      def process!
        yield(self)

        if @payment.save
          if @payment.confirmed?
            if @actions[@payment.action]
              @actions[@payment.action].call(@payment)
            else
              error!(:unknown_action)
            end
          else
            error!(:unconfirmed_payment)
          end
        else
          error!(:invalid_request)
        end
      end

      def reply(text)
        if text.length > text.mb_chars.length # Text with multibyte characters
          if text.mb_chars.length > 70
            raise ArgumentError.new(
              "Response text is too long: #{text.mb_chars.length} chars (maximum is 70 chars for UTF strings)"
            )
          end
        else
          if text.mb_chars.length > 160
            raise ArgumentError.new(
              "Response text is too long: #{text.mb_chars.length} chars (maximum is 160 chars for ASCII strings)"
            )
          end
        end

        @controller.send(:render, :text => "status: reply\n\n#{text}")
      end

      def error!(key)
        if @errors[key]
          @errors[key].call(@payment)
        else
          reply(@controller.t("paystream.errors.#{key}"))
        end
      end
    end
  end
end