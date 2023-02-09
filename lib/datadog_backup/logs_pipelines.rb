# frozen_string_literal: true

module DatadogBackup
  # Logs pipeline specific overrides for backup and restore.
  class LogsPipelines < Resources
    def all
      get_all
    end

    def backup
      LOGGER.info("Starting diffs on #{::DatadogBackup::ThreadPool::TPOOL.max_length} threads")
      futures = all.map do |logs_pipeline|
        Concurrent::Promises.future_on(::DatadogBackup::ThreadPool::TPOOL, logs_pipeline) do |pipeline|
          id = pipeline[id_keyname]
          get_and_write_file(id)
        end
      end

      watcher = ::DatadogBackup::ThreadPool.watcher
      watcher.join if watcher.status

      Concurrent::Promises.zip(*futures).value!
    end

    def initialize(options)
      super(options)
      @banlist = %w[modified_at url].freeze
    end

    private

    def api_version
      'v1'
    end

    def api_resource_name
      'logs/config/pipelines'
    end

    def id_keyname
      'id'
    end
  end
end
