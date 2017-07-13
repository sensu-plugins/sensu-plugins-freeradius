require 'json'

# encoding: utf-8
module SensuPluginsFreeradius
  # This defines the version of the gem
  module Version
    MAJOR = 1
    MINOR = 0
    PATCH = 0

    VER_STRING = [MAJOR, MINOR, PATCH].compact.join('.')

    NAME   = 'sensu-plugins-freeradius'.freeze
    BANNER = "#{NAME} v%s".freeze

    module_function

    def version
      format(BANNER, VER_STRING)
    end

    def json_version
      {
        'version' => VER_STRING
      }.to_json
    end
  end
end
