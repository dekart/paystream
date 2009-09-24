module Paystream
  module PaymentModel
    def self.included(base)
      base.class_eval do
        cattr_accessor  :action_codes
        @@action_codes = {}

        attr_accessor   :secret
        
        validates_presence_of :secret

        validate :check_secret

        before_save :check_confirmation
      end

      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
      def action_code(action, action_params = nil)
        [
          Paystream.config["prefix"],
          self.action_codes.index(action),
          action_params
        ].compact.join("")
      end
    end

    module InstanceMethods
      def message_without_prefix
        message.gsub(/^#{Regexp.quote(Paystream.config["prefix"])}/i, "")
      end

      def action
        @action ||= @@action_codes[message_without_prefix.mb_chars[0..1].to_s]
      end

      def action_params
        @action_params ||= message_without_prefix.mb_chars[2..-1].to_s
      end

      protected

      def check_confirmation
        if self.logic.nil? || self.logic == 0
          self.confirmed = true
        end
      end

      def check_secret
        if self.secret != Paystream.config["secret"]
          self.errors.add(:secret, :invalid)
        end
      end
    end
  end
end