# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    module UpdateRegistrations
      protected

      def attributes
        extra_params = {}
        if form.registrations_enabled
          extra_params = {
            available_slots: form.available_slots,
            reserved_slots: form.reserved_slots,
            registration_terms: form.registration_terms,
            customize_registration_email: form.customize_registration_email,
            enable_guest_registration: form.enable_guest_registration,
            enable_registration_confirmation: form.enable_registration_confirmation,
            enable_cancellation: form.enable_cancellation,
            disable_account_confirmation: form.disable_account_confirmation
          }
          extra_params.merge!(registration_email_custom_content: form.registration_email_custom_content) if form.customize_registration_email
        end
        super.merge(extra_params)
      end
    end
  end
end
