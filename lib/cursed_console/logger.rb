require 'logger'

module CursedConsole

  LOG_FILE = "/tmp/cursed_console.log"

  class Logger
    include Singleton

    attr_reader :logger

    def initialize
      @logger = ::Logger.new(LOG_FILE, shift_age = 'daily', shift_size = 1048576)
    end

    def self.info(message)
      instance.logger.info(message)
    end

    def self.debug(message)
      instance.logger.info(message)
    end

    def self.warn(message)
      instance.logger.warn(message)
    end

    def self.fatal(message)
      instance.logger.fatal(message)
    end

    def self.error(message)
      instance.logger.error(message)
    end

  end

end
