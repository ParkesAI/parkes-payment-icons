# frozen_string_literal: true
# SPDX-License-Identifier: Apache-2.0

module Parkes
  module PaymentIcons
    module Helper
      # Read the bundled asset inventory once, never per render.
      ICON_PATHS = Dir.glob("*/*.svg", base: File.expand_path("../../../app/assets/images/payment_icons", __dir__))
        .to_h { |path| [path, "payment_icons/#{path}".freeze] }.freeze
      private_constant :ICON_PATHS

      def payment_icon_tag(name, variant: :logo, **options)
        asset = payment_icon_asset(name, variant)
        image_tag(asset, { alt: name.to_s.tr("_-", " ").capitalize }.merge(options))
      end

      def payment_icon_path(name, variant: :logo, **options)
        image_path(payment_icon_asset(name, variant), options)
      end

      private

      def payment_icon_asset(name, variant)
        unless [name, variant].all? { |value| value.is_a?(String) || value.is_a?(Symbol) }
          raise ArgumentError, "Payment icon name and variant must be strings or symbols"
        end

        key = "#{variant.to_s.tr('_', '-')}/#{name.to_s.tr('_', '-')}.svg"
        ICON_PATHS.fetch(key) do
          raise ArgumentError, "Unknown payment icon #{name.inspect} with variant #{variant.inspect}"
        end
      end
    end
  end
end
