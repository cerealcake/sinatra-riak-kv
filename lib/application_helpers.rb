module ApplicationHelpers

  def logger
    @logger ||= ApplicationHelpers.logger_for(self.class.name)
  end

  @loggers = {}

  class << self
    def logger_for(classname)
      @loggers[classname] ||= configure_logger_for(classname)
    end

    def configure_logger_for(classname)
      logger = Logger.new(STDOUT)
      logger.progname = classname
      logger
    end
  end

  def warning(warning)
    logger.warn "warning:"
    return true
  end

  def error (error)
    logger.error "error:"
    abort
  end

  def prompt (question,visible=true)
     print "Input : "
     password=ask(question) {|q| q.echo = visible }
  end

  def notify (notification)
     logger.info "notify:"
  end

end
