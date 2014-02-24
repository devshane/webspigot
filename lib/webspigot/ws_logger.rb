require 'logger'

class WsLogger
  def initialize
    @logger = Logger.new(STDOUT)
  end

  def debug(what)
    @logger.debug(what)
  end

  def warn(what)
    @logger.warn(what)
  end

  def error(what)
    @logger.error(what)
  end
end
