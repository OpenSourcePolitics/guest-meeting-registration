# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    module AccountRegistration
      def call
        if form.invalid?
          user = registration_request

          if user.present?

            user.assign_attributes(
              email: form.email,
              name: form.name,
              nickname: form.nickname,
              password: form.password,
              password_updated_at: Time.current,
              tos_agreement: form.tos_agreement,
              newsletter_notifications_at: form.newsletter_at,
              accepted_tos_version: form.current_organization.tos_version,
              locale: form.current_locale,
              confirmed_at: nil
            )
            user.extended_data.delete("attend_meetings")

            if user.save
              user.send_confirmation_instructions
              return broadcast(:ok, user)
            end
          end
        end
        super
      end

      # check if the user has ever tried to participate to a meeting, and if so, we try to find the first record that has a
      # user associated
      def registration_request
        existing_request = Decidim::GuestMeetingRegistration::RegistrationRequest.where(organization: form.current_organization, email: form.email)

        if existing_request.exists?
          user = existing_request.where.not(user: nil).first.try(:user)

          return user if user.present? && user.extended_data.with_indifferent_access.fetch(:attend_meetings, false)
        end
      end
    end
  end
end
