# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Family do
  describe '#trigger_async_publish' do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, crm_notifiction_needed: true) }
    let(:primary_member) { family.primary_applicant }

    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_update_family_save).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:async_publish_updated_families).and_return(enabled_or_disabled)
      family.trigger_async_publish
    end

    context 'enabled' do
      let(:enabled_or_disabled) { true }

      it 'does not reset crm_notifiction_needed' do
        expect(family.crm_notifiction_needed).to be_truthy
      end
    end

    context 'disabled' do
      let(:enabled_or_disabled) { false }

      it 'resets crm_notifiction_needed' do
        expect(family.crm_notifiction_needed).to be_falsey
      end
    end
  end
end
