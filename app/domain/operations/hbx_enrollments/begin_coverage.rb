# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Begin IVL enrollment coverage
    class BeginCoverage
      include ::Operations::Transmittable::TransmittableUtils

      attr_reader :logger, :hbx_enrollment, :job, :request_transaction, :request_transmission, :response_transaction, :response_transmission

      # @param [Hash] params
      # @option params [Hash] :enrollment_gid
      # @option params [Hash] :transmittable_identifiers
      # @return [Dry::Monads::Result]
      # @example params: {
      #   enrollment_gid: 'gid://enroll/HbxEnrollment/65739e355b4dc03a97f26c3b',
      #   job_gid: 'gid://enroll/Transmittable::Job/65739e355b4dc03a97f26c3b'
      # }
      def call(params)
        _params                      = yield validate(params)
        @hbx_enrollment              = yield find_enrollment
        @job                         = yield find_job_by_global_id(@job_gid)

        # create transmission and transaction for request
        request_transmission_params  = yield construct_request_transmission_params(hbx_enrollment, job)
        @request_transmission        = yield create_request_transmission(request_transmission_params, job)
        request_transaction_params   = yield construct_request_transaction_params(hbx_enrollment)
        @request_transaction         = yield create_request_transaction(request_transaction_params, job)

        # create transmission and transaction for response
        response_transmission_params = yield construct_response_transmission_params
        @response_transmission       = yield create_response_transmission(response_transmission_params, { job: job, transmission: request_transmission })
        response_transaction_params  = yield construct_response_transaction_params
        @response_transaction        = yield create_response_transaction(response_transaction_params, { job: job, transaction: request_transaction})
        begin_coverage_msg           = yield begin_coverage
        _response_updated_result     = yield update_status(begin_coverage_msg,
                                                        :succeeded,
                                                        { transaction: response_transaction, transmission: response_transmission })

        Success(begin_coverage_msg)
      end

      private

      def construct_request_transmission_params(enrollment, job)
        Success(
          {
            job: job,
            key: :hbx_enrollment_begin_coverage_request,
            title: "Transmission request to begin coverage enrollment with hbx id: #{enrollment.hbx_id}.",
            description: "Transmission request to begin coverage enrollment with hbx id: #{enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'initial',
            state_key: :initial,
            correlation_id: enrollment.hbx_id
          }
        )
      end

      def construct_request_transaction_params(enrollment)
        Success(
          {
            transmission: request_transmission,
            subject: enrollment,
            key: :hbx_enrollment_begin_coverage_request,
            title: "Enrollment begin coverage request transaction for #{enrollment.hbx_id}.",
            description: "Transaction request to begin coverage of enrollment with hbx id: #{enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'initial',
            state_key: :initial,
            correlation_id: enrollment.hbx_id
          }
        )
      end

      def validate(params)
        @logger = Logger.new(
          "#{Rails.root}/log/hbx_enrollments_begin_coverage_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )

        logger.info "Processing begin coverage request with params: #{params}"

        unless params.is_a?(Hash)
          msg = "Invalid input params: #{params}. Expected a hash."
          logger.error msg
          return Failure(msg)
        end

        if params[:enrollment_gid].blank?
          msg = "Missing enrollment_gid in params: #{params}."
          logger.error msg
          return Failure(msg)
        end

        if params[:job_gid].blank?
          msg = "Missing job_gid in params: #{params}."
          logger.error msg
          return Failure(msg)
        end

        @hbx_enrollment_gid       = params[:enrollment_gid]
        @job_gid                  = params[:job_gid]

        Success(params)
      end

      def find_enrollment
        hbx_enrollment = GlobalID::Locator.locate(@hbx_enrollment_gid)

        if hbx_enrollment.blank?
          Failure(
            "No HbxEnrollment found with given global ID: #{@hbx_enrollment_gid}"
          )
        elsif !hbx_enrollment.is_ivl_by_kind?
          Failure("Invalid Enrollment kind: #{hbx_enrollment.kind}. Expected an IVL enrollment kinds.")
        else
          Success(hbx_enrollment)
        end
      end

      def construct_response_transmission_params
        Success(
          {
            job: job,
            key: :hbx_enrollment_begin_coverage_response,
            title: "Transmission response to begin coverage for enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
            description: "Transmission response to begin coverage for enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'received',
            state_key: :received,
            correlation_id: hbx_enrollment.hbx_id
          }
        )
      end

      def construct_response_transaction_params
        Success(
          {
            transmission: response_transmission,
            subject: hbx_enrollment,
            key: :hbx_enrollment_begin_coverage_response,
            title: "Transaction response to begin coverage for enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
            description: "Transaction response to begin coverage for enrollment with hbx id: #{hbx_enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'received',
            state_key: :received,
            correlation_id: hbx_enrollment.hbx_id
          }
        )
      end

      def begin_coverage
        if hbx_enrollment.may_begin_coverage?
          hbx_enrollment.begin_coverage!
          msg = "Successfully began coverage for enrollment hbx id #{hbx_enrollment.hbx_id}."
          logger.info msg
          Success(msg)
        else
          msg = "Invalid Transition request. Failed to begin coverage for enrollment hbx id #{hbx_enrollment.hbx_id}."
          add_errors(:enrollment_begin_coverage, msg, { transaction: response_transaction, transmission: response_transmission })
          status_result = update_status(msg, :failed, { transaction: response_transaction, transmission: response_transmission })
          return status_result if status_result.failure?
          logger.error msg
          Failure(msg)
        end
      end
    end
  end
end
