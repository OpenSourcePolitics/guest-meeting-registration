# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/guest_meeting_registration/version"

Gem::Specification.new do |s|
  s.version = Decidim::GuestMeetingRegistration.version
  s.authors = ["Alexandru Emil Lupu"]
  s.email = ["contact@alecslupu.ro"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/decidim/decidim-module-guest_meeting_registration"
  s.required_ruby_version = "~> 3.2"

  s.name = "decidim-guest_meeting_registration"
  s.summary = "A decidim guest_meeting_registration module"
  s.description = "This module allows you to add guest meeting registrations.."

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").select do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w(app/ config/ db/ lib/ LICENSE-AGPLv3.txt Rakefile README.md))
    end
  end

  s.add_dependency "decidim-core", "~> 0.29"
  s.add_dependency "decidim-meetings", "~> 0.29"
  s.add_dependency "deface", ">= 1.9"
  s.metadata["rubygems_mfa_required"] = "true"
end
