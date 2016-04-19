#! /usr/bin/env ruby
#
#  check-freeradius-radclient.rb
#
# DESCRIPTION:
#   This plugin reports results of FreeRADIUS radclient call
#
# OUTPUT:
#   check result
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   check-freeradius-radclient.rb -H radius_server -u aaa_username -p aaa_password -s radius_secret
#
# NOTES:
#   The AAA account needs to be created.
#
# LICENSE:
#   Copyright 2016 Glen Johnson <gsfjohnson@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'English'
require 'sensu-plugin/check/cli'

class CheckFreeRadiusRadclient < Sensu::Plugin::Check::CLI
  option :host,
         short: '-H',
         long: '--host=VALUE',
         description: 'RADIUS server'

  option :port,
         short: '-P',
         long: '--port=VALUE',
         description: 'RADIUS port',
         default: 1812,
         # #YELLOW
         proc: lambda { |s| s.to_i } # rubocop:disable Lambda

  option :user,
         short: '-u',
         long: '--username=VALUE',
         description: 'Username for user validation'

  option :pass,
         short: '-p',
         long: '--password=VALUE',
         description: 'Password for user validation'

  option :secret,
         short: '-s',
         long: '--secret VALUE',
         description: 'RADIUS secret'

  option :timeout,
         short: '-t',
         long: '--timeout VALUE',
         description: 'RADIUS timeout',
         default: 1

  option :retry,
         short: '-r',
         long: '--retry VALUE',
         description: 'RADIUS retries',
         default: 1

  option :help,
         short: '-h',
         long: '--help',
         description: 'Check MySQL replication status',
         on: :tail,
         boolean: true,
         show_options: true,
         exit: 0

  def run
    unknown 'Must specify host'     unless config[:host]
    unknown 'Must specify user'     unless config[:user]
    unknown 'Must specify password' unless config[:pass]
    unknown 'Must specify secret'   unless config[:secret]

    begin
      result = `echo User-Name = #{config[:user]}, User-Password = #{config[:pass]} | radclient -x -r #{config[:retry]} -t #{config[:timeout]} #{config[:host]}:#{config[:port]} auth \"#{config[:secret]}\" 2>&1`
      if $CHILD_STATUS.exitstatus > 0 && result.match('Reply-Message')
        critical result.lines.last(2).join('/').sub(/\n/, ' ').sub(/\t/, ' ')
      elsif $CHILD_STATUS.exitstatus > 0
        critical result.lines.first
      else
        ok result.lines.last
      end
    end
  end
end
