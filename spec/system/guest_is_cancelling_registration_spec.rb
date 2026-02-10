# frozen_string_literal: true

require "spec_helper"

describe "Admin manages registration settings", type: :system do
  include_context "with a component"
  let(:manifest_name) { "meetings" }
  let!(:meeting) { create :meeting, :published, component:, enable_guest_registration: true, enable_cancellation: true, address: nil, latitude: nil, longitude: nil }
  let!(:registration) { create(:guest_meeting_registration, :with_user, organization:, meeting:) }

  before do
    meeting.update!(
      registrations_enabled: true,
      registration_form_enabled: true,
      available_slots: 20,
      registration_terms: {
        en: "A legal text",
        es: "Un texto legal",
        ca: "Un text legal"
      }
    )
  end

  around do |example|
    previous = Capybara.raise_server_errors

    Capybara.raise_server_errors = false
    example.run
    Capybara.raise_server_errors = previous
  end

  def meeting_path
    resource_locator(meeting).path
  end

  def cancellation_url(cancellation_token)
    "#{meeting_path}/guest-registration/cancellation/#{cancellation_token}"
  end

  it "cancels the registration" do
    expect { visit cancellation_url(registration.cancellation_token) }.to change(Decidim::GuestMeetingRegistration::RegistrationRequest, :count).by(-1)
  end

  it "displays a success message" do
    visit cancellation_url(registration.cancellation_token)
    expect(page).to have_content(I18n.t("cancellation.success", scope: "decidim.guest_meeting_registration"))
  end

  it "displays an error message" do
    visit cancellation_url(registration.cancellation_token)
    visit cancellation_url(registration.cancellation_token)
    expect(page).to have_content(I18n.t("cancellation.error", scope: "decidim.guest_meeting_registration"))
  end

  it "cancels the follow" do
    expect { visit cancellation_url(registration.cancellation_token) }.to change(Decidim::Follow, :count).by(-1)
  end

  it "cancels the meeting registration" do
    expect { visit cancellation_url(registration.cancellation_token) }.to change(Decidim::Meetings::Registration, :count).by(-1)
  end

  it "raise error if token not found" do
    visit cancellation_url("invalid_token")
    expect(page).to have_content(I18n.t("cancellation.error", scope: "decidim.guest_meeting_registration"))
  end

  it "raise error if token exists, but not belongs to correct meeting" do
    registration = create(:guest_meeting_registration, organization:)
    visit cancellation_url(registration.cancellation_token)
    expect(page).to have_content(I18n.t("cancellation.error", scope: "decidim.guest_meeting_registration"))
  end
end
