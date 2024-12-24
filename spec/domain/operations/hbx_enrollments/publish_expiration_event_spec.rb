# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::PublishExpirationEvent, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  before :each do
    DatabaseCleaner.clean
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:effective_on) { TimeKeeper.date_of_record.prev_year.beginning_of_year }
  let(:aasm_state) { 'coverage_selected' }
  let!(:enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_unassisted,
      family: family,
      aasm_state: aasm_state,
      effective_on: effective_on
    )
  end

  let(:transmittable_job) do
    ::Operations::Transmittable::CreateJob.new.call(
      {
        key: :hbx_enrollments_expiration,
        title: "Request expiration of all active IVL enrollments.",
        description: "Job that requests expiration of all active IVL enrollments.",
        publish_on: DateTime.now,
        started_at: DateTime.now
      }
    ).success
  end

  let(:params) { { enrollment: enrollment, job: transmittable_job } }

  let(:operation_instance) { described_class.new }
  let(:result) { operation_instance.call(params) }

  describe '#call' do
    context 'with invalid params' do
      context 'when params is not a hash' do
        let(:params) { nil }

        it 'returns a failure' do
          expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
        end
      end

      context 'when enrollment is not a valid object' do
        let(:params) { { enrollment: 'enrollment' } }

        it 'returns a failure' do
          expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
        end
      end

      context 'when job is not a valid object' do
        let(:params) { { enrollment: enrollment, job: 'transmittable_job' } }

        it 'returns a failure' do
          expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
        end
      end
    end

    context 'with valid params' do
      before :each do
        result
      end

      it 'returns success' do
        expect(result.success).to eq(
          "Successfully published expiration event: events.individual.enrollments.expire_coverages.expire for enrollment with hbx_id: #{enrollment.hbx_id}."
        )
      end
    end
  end
end
