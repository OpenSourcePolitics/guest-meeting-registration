# frozen_string_literal: true

require "spec_helper"

describe "Admin manages registration settings", type: :system do
  let(:manifest_name) { "meetings" }

  let!(:questionnaire) { create(:questionnaire) }
  let!(:meeting) { create :meeting, scope:, component: current_component, questionnaire:, registrations_enabled: true, registration_form_enabled: true }

  include_context "when managing a component as an admin"
  def registrations_edit_path
    Decidim::EngineRouter.admin_proxy(component).edit_meeting_registrations_path(meeting_id: meeting.id)
  end

  it "enables the registration settings" do
    visit registrations_edit_path

    check I18n.t("activemodel.attributes.meeting.enable_guest_registration")
    check I18n.t("activemodel.attributes.meeting.enable_registration_confirmation")
    check I18n.t("activemodel.attributes.meeting.enable_cancellation")

    expect(meeting).not_to be_enable_guest_registration
    expect(meeting).not_to be_enable_registration_confirmation
    expect(meeting).not_to be_enable_cancellation

    click_on "Save"
    meeting.reload

    expect(meeting).to be_enable_guest_registration
    expect(meeting).to be_enable_registration_confirmation
    expect(meeting).to be_enable_cancellation
  end

  it "disables the registration settings" do
    meeting.update!(
      enable_guest_registration: true,
      enable_cancellation: true,
      enable_registration_confirmation: true
    )

    visit registrations_edit_path

    uncheck I18n.t("activemodel.attributes.meeting.enable_guest_registration")
    uncheck I18n.t("activemodel.attributes.meeting.enable_registration_confirmation")
    uncheck I18n.t("activemodel.attributes.meeting.enable_cancellation")

    expect(meeting).to be_enable_guest_registration
    expect(meeting).to be_enable_registration_confirmation
    expect(meeting).to be_enable_cancellation

    click_on "Save"
    meeting.reload

    expect(meeting).not_to be_enable_guest_registration
    expect(meeting).not_to be_enable_registration_confirmation
    expect(meeting).not_to be_enable_cancellation
  end
end
