# Health checks served by the Allgood engine at /healthcheck (mounted in
# config/routes.rb). The page answers 200 only when every check passes and
# 503 otherwise, so a single URL tells monitors whether the app is healthy.

check "Database is reachable and answers queries" do
  answer = ApplicationRecord.connection_pool.with_connection do |connection|
    connection.select_value("SELECT 1")
  end
  make_sure answer == 1, "A trivial SELECT should return 1"
end

check "Database migrations are all applied" do
  # check_all_pending! raises when any migration is pending, across every
  # configured database for this environment.
  make_sure ActiveRecord::Migration.check_all_pending!.nil?
end

check "Job queue is live" do
  adapter = ActiveJob::Base.queue_adapter
  if adapter.is_a?(ActiveJob::QueueAdapters::SolidQueueAdapter)
    cutoff = SolidQueue.process_alive_threshold.ago
    make_sure SolidQueue::Process.where(last_heartbeat_at: cutoff..).exists?,
      "At least one Solid Queue process should have sent a heartbeat since #{cutoff}"
  else
    # In-process adapters (test, async, inline) execute jobs without a
    # separate worker, so a configured adapter is all that liveness means.
    make_sure adapter.present?, "An Active Job queue adapter should be configured"
  end
end

check "Disk-backed storage is writable" do
  service = ActiveStorage::Blob.service
  probe_key = "foundation-healthcheck-#{SecureRandom.uuid}"
  service.upload(probe_key, StringIO.new("probe"))
  written = service.exist?(probe_key)
  service.delete(probe_key)
  make_sure written, "The #{service.class.name.demodulize} storage service should accept a small write"
end
