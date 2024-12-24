# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish event to begin IVL enrollment coverage
    class PublishBeginCoverageEvent
      include EventSource::Command
      include Dry::Monads[:do, :result]

      # @param [Hash] params
      # @option params [Hash] :enrollment, :job
      # @return [Dry::Monads::Result]
      # @example params: { enrollment: HbxEnrollment.new, job: Transmittable::Job.new }
      def call(params)
        values              = yield validate(params)
        event               = yield build_event(values)
        result              = yield publish_event(values[:enrollment], event)

        Success(result)
      end

      private

      def validate(params)
        if params.is_a?(Hash) && params[:enrollment].is_a?(::HbxEnrollment) && params[:job].is_a?(::Transmittable::Job)
          Success(params)
        else
          Failure("Invalid input params: #{params}. Expected a hash.")
        end
      end

      def build_event(values)
        event(
          'events.individual.enrollments.begin_coverages.begin',
          attributes: {
            enrollment_gid: values[:enrollment].to_global_id.uri,
            job_gid: values[:job].to_global_id.uri
          }
        )
      end

      def publish_event(enrollment, event)
        event.publish
        Success("Successfully published begin coverage event: #{event.name} for enrollment with hbx_id: #{enrollment.hbx_id}.")
      end
    end
  end
end
