# Health checks served by the Allgood engine at /healthcheck (mounted in
# config/routes.rb). The page answers 200 only when every check passes and
# 503 otherwise, so a single URL tells monitors whether the app is healthy.

runtime_config = Foundation.runtime_config

check "Hosted preview is #{runtime_config.preview? ? 'active' : 'inactive'}" do
  make_sure true, "Runtime mode is reported from the immutable boot configuration"
end

check "Mail mode: #{runtime_config.mail_mode(provider: Rails.application.config.action_mailer.delivery_method)}" do
  # Reporting mail mode must never attempt a network delivery.
  make_sure Rails.application.config.action_mailer.delivery_method.present?,
    "Action Mailer should have an explicit delivery provider"
end

check "Storage mode: #{runtime_config.storage_mode}" do
  service = ActiveStorage::Blob.service
  safe_production_service = !service.is_a?(ActiveStorage::Service::DiskService)
  make_sure runtime_config.production_storage_configured? &&
    (!runtime_config.production? || runtime_config.preview? || safe_production_service),
    "Production requires ACTIVE_STORAGE_SERVICE to name a configured non-disk cloud service"
end

check "Storefront simulator is #{Foundation.storefront_simulator? ? 'active' : 'inactive'}" do
  make_sure true, "Payment mode is reported without contacting Stripe"
end

check "Solid Queue runs #{runtime_config.queue_mode}" do
  make_sure true, "Queue process topology is reported from SOLID_QUEUE_IN_PUMA"
end

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

check "Configured storage is writable" do
  service = ActiveStorage::Blob.service
  probe_key = "foundation-healthcheck-#{SecureRandom.uuid}"
  written = false
  begin
    service.upload(probe_key, StringIO.new("probe"))
    written = service.exist?(probe_key)
  ensure
    service.delete(probe_key)
  end
  make_sure written, "The #{service.class.name.demodulize} storage service should accept a small write"
end

unless Rails.env.test?
  check "Enabled storefront payment configuration is ready" do
    result = Foundation::Storefront::Readiness.call
    make_sure result.ready?, result.errors.join("; ")
  end
end
