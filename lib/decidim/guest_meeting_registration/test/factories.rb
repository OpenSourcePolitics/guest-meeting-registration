# frozen_string_literal: true

require "decidim/core/test/factories"

FactoryBot.define do
  # factory :guest_meeting_registration_settings, class: "Decidim::GuestMeetingRegistration::Setting" do
  #   organization
  #   enable_guest_registration { false }
  #   enable_registration_confirmation { false }
  #   enable_cancellation { false }
  #
  #   trait :enabled do
  #     enable_guest_registration { true }
  #   end
  #
  #   trait :require_confirmation do
  #     enable_registration_confirmation { true }
  #   end
  #   trait :cancellable do
  #     enable_cancellation { true }
  #   end
  # end

  factory :guest_meeting_registration, class: "Decidim::GuestMeetingRegistration::RegistrationRequest" do
    transient do
      create_registration { true }
      create_follow { true }
    end
    organization
    meeting { create(:meeting, component: create(:meeting_component, organization:)) }
    email { generate(:email) }
    name { generate(:name) }
    cancellation_token { SecureRandom.hex }
    confirmation_token { SecureRandom.hex }
    form_data { { name:, email:, tos_agreement: true } }

    trait :with_user do
      user { create(:user, email:, name:, organization:, extended_data: { attend_meetings: true }) }
    end

    trait :confirmed do
      confirmed_at { Time.zone.now }
    end

    after(:create) do |registration, evaluator|
      if registration.user.present?
        create(:registration, user: registration.user, meeting: registration.meeting) if evaluator.create_registration == true
        create(:follow, user: registration.user, followable: registration.meeting) if evaluator.create_follow == true
      end
    end
  end
end
