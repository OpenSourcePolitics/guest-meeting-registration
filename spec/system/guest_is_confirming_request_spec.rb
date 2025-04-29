# frozen_string_literal: true

require "spec_helper"

describe "Guest user is confirming the account", type: :system do
  include_context "with a component"
  let(:manifest_name) { "meetings" }
  let!(:meeting) do
    create :meeting, :published,
           component:,
           enable_guest_registration: true,
           enable_cancellation: true,
           registrations_enabled: true,
           registration_form_enabled: false,
           available_slots: 20
  end
  let!(:registration) { create(:guest_meeting_registration, organization:, meeting:) }

  def meeting_path
    resource_locator(meeting).path
  end

  def confirmation_url(confirmation_token)
    "#{meeting_path}/guest-registration/confirm/#{confirmation_token}"
  end

  it "Successfully creates the user" do
    expect { visit confirmation_url(registration.confirmation_token) }.to change(Decidim::User, :count).by(1)
                                                                                                       .and change(Decidim::Meetings::Registration, :count).by(1)
                                                                                                                                                           .and change(Decidim::Follow, :count).by(1)
  end

  it "displays the correct message" do
    visit confirmation_url(registration.confirmation_token)
    expect(page).to have_content(I18n.t("registrations.create.success", scope: "decidim.meetings"))
  end

  it "resets the confirmation token" do
    visit confirmation_url(registration.confirmation_token)
    expect(registration.reload.confirmation_token).to be_nil
  end

  it "sends the cancellation email" do
    expect { visit confirmation_url(registration.confirmation_token) }.to have_enqueued_job(Decidim::GuestMeetingRegistration::SendCancellationJob)
  end

  context "when user exists" do
    let!(:user) { create(:user, organization:) }
    let!(:registration) { create(:guest_meeting_registration, email: user.email, name: user.name, organization:, meeting:) }

    it "assigns the request to existing user" do
      expect { visit confirmation_url(registration.confirmation_token) }.not_to change(Decidim::User, :count)
    end
  end

  context "when form is invalid" do
    let!(:registration) { create(:guest_meeting_registration, organization:, meeting:, form_data: {}) }

    it "displays the form" do
      visit confirmation_url(registration.confirmation_token)
      expect(page).to have_content(I18n.t("answer.invalid", scope: "decidim.forms.questionnaires"))
    end
  end

  it "displays the invalid message" do
    visit confirmation_url("FOOBAR")
    expect(page).to have_content(I18n.t("registrations.create.invalid", scope: "decidim.meetings"))
  end
end
