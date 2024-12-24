# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::BeginCoverage, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
  let(:aasm_state) { 'auto_renewing' }
  let(:kind) { 'individual' }

  let(:enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      kind: kind,
      family: family,
      aasm_state: aasm_state,
      effective_on: effective_on
    )
  end

  let(:enrollment_hbx_id) { enrollment.hbx_id }

  let(:operation_instance)  { described_class.new }
  let(:result)              { operation_instance.call(params) }

  let(:logger) do
    File.read("#{Rails.root}/log/hbx_enrollments_begin_coverage_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
  end

  let(:job) do
    ::Operations::Transmittable::CreateJob.new.call(
      {
        key: :hbx_enrollments_begin_coverage,
        title: "Request begin coverage of all renewal IVL enrollments.",
        description: "Job that requests begin coverage of all renewal IVL enrollments.",
        publish_on: DateTime.now,
        started_at: DateTime.now
      }
    ).success
  end

  let(:request_transmission) do
    operation_instance.request_transmission
  end

  let(:request_transaction) do
    operation_instance.request_transaction
  end

  let(:params) do
    {
      enrollment_gid: enrollment.to_global_id.uri.to_s,
      job_gid: job.to_global_id.uri.to_s
    }
  end

  describe 'with invalid params' do
    context 'without params' do
      let(:params) { nil }

      it 'returns failure monad' do
        expect(result.failure).to eq("Invalid input params: #{params}. Expected a hash.")
      end
    end

    context 'without enrollment_gid' do
      let(:params) { {} }

      it 'returns failure monad' do
        expect(result.failure).to eq("Missing enrollment_gid in params: #{params}.")
      end
    end

    context 'without job_gid' do
      let(:params) { { enrollment_gid: enrollment.to_global_id.uri.to_s } }

      it 'returns failure monad' do
        expect(result.failure).to eq("Missing job_gid in params: #{params}.")
      end
    end

    context 'invalid input enrollment gid' do
      let(:params) do
        {
          enrollment_gid: 'invalid-enrollment-gid',
          job_gid: job.to_global_id.uri.to_s
        }
      end

      it 'returns failure monad' do
        expect(result.failure).to eq("No HbxEnrollment found with given global ID: #{params[:enrollment_gid]}")
      end
    end

    context 'with shop enrollment' do
      let(:kind) { 'employer_sponsored' }

      it 'returns failure monad' do
        expect(result.failure).to eq("Invalid Enrollment kind: #{kind}. Expected an IVL enrollment kinds.")
      end
    end

    context 'with invalid aasm_state' do
      before :each do
        result
      end

      let(:aasm_state) do
        ['actively_renewing', 'coverage_canceled', 'coverage_enrolled', 'coverage_expired', 'coverage_terminated', 'coverage_termination_pending', 'inactive', 'renewing_contingent_enrolled', 'shopping', 'void'].sample
      end

      it 'returns failure monad and also logs the error msg' do
        msg = "Invalid Transition request. Failed to begin coverage for enrollment hbx id #{enrollment.hbx_id}."
        expect(result.failure).to eq(msg)
        expect(logger).to include(msg)
      end

      it 'updates status on response transmission' do
        response_transmission = operation_instance.response_transmission
        process_status = response_transmission.process_status
        expect(process_status.latest_state).to eq(:failed)
        process_state = process_status.process_states.last
        expect(process_state.event).to eq('failed')
        expect(process_state.state_key).to eq(:failed)
      end

      it 'adds errors on response transmission' do
        response_transmission = operation_instance.response_transmission
        expect(
          response_transmission.transmittable_errors.last.key
        ).to eq(:enrollment_begin_coverage)
      end

      it 'updates status on response transaction' do
        response_transaction = operation_instance.response_transaction
        process_status = response_transaction.process_status
        expect(process_status.latest_state).to eq(:failed)
        process_state = process_status.process_states.last
        expect(process_state.event).to eq('failed')
        expect(process_state.state_key).to eq(:failed)
      end

      it 'adds errors on response transaction' do
        response_transaction = operation_instance.response_transaction
        expect(
          response_transaction.transmittable_errors.last.key
        ).to eq(:enrollment_begin_coverage)
      end
    end

    context 'when transmission creation fails' do
      let(:job_process_status) { job.process_status }
      let(:transmission_process_status) { request_transmission.process_status }

      before :each do
        allow(
          ::Operations::Transmittable::CreateTransmission
        ).to receive(:new).and_return(
          double('CreateTransmission', call: Failure('Failed to create transmission due to invalid params.'))
        )

        result
      end

      it 'returns a failure monad' do
        expect(result.failure).to eq('Failed to create transmission due to invalid params.')
      end

      it 'does not create transmission' do
        expect(job.transmissions.count).to eq(0)
        expect(operation_instance.request_transmission).to be_nil
        expect(Transmittable::Transmission.count).to eq(0)
      end

      it 'creates an error associated to the job' do
        expect(job.transmittable_errors.count).to eq(1)
        expect(job.transmittable_errors.first.key).to eq(:create_request_transmission)
        expect(Transmittable::Error.all.count).to eq(1)
        expect(Transmittable::Error.first.errorable).to eq(job)
      end

      it 'updates the process status and creates new process state associated to the job' do
        expect(job_process_status.reload.latest_state).to eq(:failed)
        expect(job_process_status.process_states.count).to eq(2)
        expect(job_process_status.process_states.last.state_key).to eq(:failed)
      end
    end

    context 'when transaction creation fails' do
      let(:job_process_status) { job.process_status }
      let(:transmission_process_status) { request_transmission.process_status }

      before :each do
        allow(
          ::Operations::Transmittable::CreateTransaction
        ).to receive(:new).and_return(
          double('CreateTransaction', call: Failure('Failed to create transaction due to invalid params.'))
        )

        result
      end

      it 'returns a failure monad' do
        expect(result.failure).to eq('Failed to create transaction due to invalid params.')
      end

      it 'does not create transaction' do
        expect(request_transmission.transactions.count).to eq(0)
        expect(operation_instance.request_transaction).to be_nil
        expect(Transmittable::Transaction.count).to eq(0)
      end

      it 'creates an error associated to the job and transmission' do
        expect(request_transmission.transmittable_errors.count).to eq(1)
        expect(request_transmission.transmittable_errors.first.key).to eq(:create_request_transaction)
        expect(job.transmittable_errors.count).to eq(1)
        expect(job.transmittable_errors.first.key).to eq(:create_request_transaction)
        expect(Transmittable::Error.all.count).to eq(2)
        expect(Transmittable::Error.all.map(&:errorable).sort).to eq([request_transmission, job].sort)
      end

      it 'updates the process status and creates new process state associated to the job' do
        expect(job_process_status.reload.latest_state).to eq(:failed)
        expect(job_process_status.process_states.count).to eq(2)
        expect(job_process_status.process_states.last.state_key).to eq(:failed)
        expect(transmission_process_status.latest_state).to eq(:failed)
        expect(transmission_process_status.process_states.count).to eq(2)
        expect(transmission_process_status.process_states.last.state_key).to eq(:failed)
      end
    end
  end

  describe 'with valid params' do
    before :each do
      result
    end

    it 'returns success message' do
      msg = "Successfully began coverage for enrollment hbx id #{enrollment.hbx_id}."
      expect(result.success).to eq(msg)
      expect(logger).to include(msg)
    end

    context 'request transmission and transaction' do
      it 'creates transmission with correct association' do
        expect(request_transmission).to be_a(::Transmittable::Transmission)
        expect(request_transmission.transmission_id).to eq(enrollment.hbx_id)
        expect(request_transmission.job).to eq(job)
      end

      it 'associates newly created transmission to job' do
        expect(job.transmissions.first).to eq(request_transmission)
      end

      it 'creates transaction with correct associations' do
        expect(request_transaction).to be_a(::Transmittable::Transaction)
        expect(request_transaction.transaction_id).to eq(enrollment.hbx_id)
        expect(request_transaction.transactable).to eq(enrollment)
      end

      it 'creates join table record between transmission and transaction' do
        expect(
          ::Transmittable::TransactionsTransmissions.where(
            transaction_id: request_transaction.id,
            transmission_id: request_transmission.id
          ).count
        ).to eq(1)
      end

      it 'associates newly created transaction to enrollment' do
        expect(enrollment.transactions.first).to eq(request_transaction)
      end
    end

    context 'response transmission and transaction' do
      it 'creates transmission with correct association' do
        expect(operation_instance.response_transmission).to be_a(::Transmittable::Transmission)
        expect(operation_instance.response_transmission.job).to eq(job)
      end

      it 'associates newly created response transmission to job' do
        expect(job.transmissions.count).to eq(2)
        expect(job.transmissions.pluck(:key)).to include(:hbx_enrollment_begin_coverage_response)
      end

      it 'creates response transaction with correct associations' do
        expect(operation_instance.response_transaction).to be_a(::Transmittable::Transaction)
        expect(operation_instance.response_transaction.transactable).to eq(enrollment)
      end

      it 'creates join table record between transmission and transaction' do
        expect(operation_instance.response_transaction.transmissions).to be_one
        expect(
          operation_instance.response_transaction.transmissions.first
        ).to eq(operation_instance.response_transmission)
      end

      it 'associates both request/response transmission and transaction to enrollment' do
        request_transmission_transmission_id = operation_instance.request_transmission.transmission_id
        response_transmission_transmission_id = operation_instance.response_transmission.transmission_id
        request_transaction_transaction_id = operation_instance.request_transaction.transaction_id
        response_transaction_transaction_id = operation_instance.response_transaction.transaction_id
        expect(request_transmission_transmission_id).to eq(response_transmission_transmission_id)
        expect(request_transaction_transaction_id).to eq(response_transaction_transaction_id)
        expect(request_transmission_transmission_id).to eq(enrollment_hbx_id)
        expect(response_transmission_transmission_id).to eq(enrollment_hbx_id)
        expect(request_transaction_transaction_id).to eq(enrollment_hbx_id)
        expect(response_transaction_transaction_id).to eq(enrollment_hbx_id)
      end
    end
  end

  after :all do
    file_path = "#{Rails.root}/log/hbx_enrollments_begin_coverage_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    File.delete(file_path) if File.file?(file_path)
  end
end
