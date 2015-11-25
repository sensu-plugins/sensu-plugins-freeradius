#! /usr/bin/env ruby
#
#   metrics-freeradius.rb
#
# DESCRIPTION:
#   This plugin collects metrics from a FreeRADIUS server
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   metrics-freeradius.rb -h radius_server -p status_port -k status_secret
#
# NOTES:
#   FreeRADIUS status server needs to be enabled.
#   See http://wiki.freeradius.org/config/Status for details
#
# LICENSE:
#   Copyright Eric Heydrick <eheydrick@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'open3'
require 'socket'

# Collect FreeRADIUS metrics
class FreeRADIUSMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.freeradius"

  option :hostname,
         description: 'FreeRADIUS server hostname',
         short: '-h HOSTNAME',
         long: '--hostname HOSTNAME',
         default: 'localhost'

  option :port,
         description: 'FreeRADIUS status port',
         short: '-p PORT',
         long: '--port PORT',
         default: 18_121

  option :secret,
         description: 'FreeRADIUS status secret',
         short: '-k SECRET',
         long: '--secret SECRET',
         default: 'adminsecret'

  def collect_status
    stdout, result = Open3.capture2("echo \"Message-Authenticator = 0x00, FreeRADIUS-Statistics-Type = 1, Response-Packet-Type = Access-Accept\" | radclient -x #{config[:hostname]}:#{config[:port]} status #{config[:secret]}")
    unknown 'Unable to get FreeRADIUS status' unless result.success?
    stdout
  end

  def run
    metrics = {}
    collect_status.each_line do |line|
      if line =~ /FreeRADIUS-Total/
        value = line.split(' ')[2]
        metrics['total_access_requests'] = value if line =~ /FreeRADIUS-Total-Access-Requests/
        metrics['total_access_accepts'] = value if line =~ /FreeRADIUS-Total-Access-Accepts/
        metrics['total_access_rejects'] = value if line =~ /FreeRADIUS-Total-Access-Rejects/
        metrics['total_access_challenges'] = value if line =~ /FreeRADIUS-Total-Access-Challenges/
        metrics['total_auth_responses'] = value if line =~ /FreeRADIUS-Total-Auth-Responses/
        metrics['total_duplicate_requests'] = value if line =~ /FreeRADIUS-Total-Duplicate-Requests/
        metrics['total_malformed_requests'] = value if line =~ /FreeRADIUS-Total-Malformed-Requests/
        metrics['total_auth_invalid_requests'] = value if line =~ /FreeRADIUS-Total-Auth-Invalid-Requests/
        metrics['total_auth_dropped_requests'] = value if line =~ /FreeRADIUS-Total-Auth-Dropped-Requests/
        metrics['total_auth_unknown_requests'] = value if line =~ /FreeRADIUS-Total-Auth-Unknown-Requests/
      end
    end

    metrics.each do |k, v|
      output "#{config[:scheme]}.#{k}", v
    end
    ok
  end
end
