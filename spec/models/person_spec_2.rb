# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Person, type: :model do
  let(:person) do
    FactoryBot.create(
      :person,
      :with_consumer_role,
      :with_active_consumer_role,
      crm_notifiction_needed: false
    )
  end

  describe '#check_crm_updates' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:async_publish_updated_families).and_return(enabled_or_disabled)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(true)
      person.first_name = 'Changed first name'
      person.save!
    end

    context 'enabled' do
      let(:enabled_or_disabled) { true }

      it 'does not set crm_notifiction_needed' do
        expect(person.crm_notifiction_needed).to be_falsey
      end
    end

    context 'disabled' do
      let(:enabled_or_disabled) { false }

      it 'sets crm_notifiction_needed' do
        expect(person.crm_notifiction_needed).to be_truthy
      end
    end
  end
end
