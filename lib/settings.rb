require "yaml"
require "ostruct"
require "pathname"
raw_config = File.read(Pathname.new(__FILE__).join("..", "..", "config", "settings.yml"))

class Settings < OpenStruct
  def method_missing args
    false
  end
end

settings = YAML.load(raw_config)
SETTINGS = Settings.new(settings)
