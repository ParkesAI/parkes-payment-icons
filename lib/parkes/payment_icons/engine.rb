# frozen_string_literal: true

module Parkes
  module PaymentIcons
    class Engine < ::Rails::Engine
      initializer "parkes.payment_icons.helpers" do
        ActiveSupport.on_load(:action_view) do
          include Parkes::PaymentIcons::Helper
        end
      end
    end
  end
end
