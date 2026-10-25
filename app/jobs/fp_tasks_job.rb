# A job that processes a record (an Atlas or Snapshot, given by id) with
# fp-tasks. Calls that might succeed later (5xx, timeouts) are retried; when
# retries run out, or fp-tasks rejects the input (4xx), the record is marked
# failed. Subclasses define `record`.
class FpTasksJob < ApplicationJob
  retry_on Faraday::ServerError, Faraday::ConnectionFailed, wait: :polynomially_longer, attempts: 5 do |job, error|
    job.give_up(error)
  end

  discard_on Faraday::ClientError do |job, error|
    job.give_up(error)
  end

  def give_up(error)
    logger.warn("Failing #{record.class.name} #{record.slug}: #{error.class}: #{error.response_body || error.message}")
    record.mark_failed!
  end
end
