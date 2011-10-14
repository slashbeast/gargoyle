#!/usr/bin/haserl
<?
	# This program is copyright � 2008 Eric Bishop and is distributed under the terms of the GNU GPL
	# version 2.0 with a special clarification/exception that permits adapting the program to
	# configure proprietary "back end" software provided that all modifications to the web interface
	# itself remain covered by the GPL.
	# See http://gargoyle-router.com/faq.html#qfoss for more information
	eval $( gargoyle_session_validator -c "$COOKIE_hash" -e "$COOKIE_exp" -a "$HTTP_USER_AGENT" -i "$REMOTE_ADDR" -r "login.sh" -t $(uci get gargoyle.global.session_timeout) -b "$COOKIE_browser_time"  )
	gargoyle_header_footer -h -s "firewall" -p "qosdownload" -c "internal.css" -j "qos.js table.js" qos_gargoyle firewall gargoyle -i qos_gargoyle
?>


<script>
<!--
       var direction = "download";
       protocolMap = new Object;
<?
       sed -e '/^#/ d' -e 's/\([^ ]*\) \(.*\)/protocolMap\["\1"\]="\2";/' /etc/l7-protocols/l7index


	if [ -h /etc/rc.d/S50qos_gargoyle ] ; then
		echo "var qosEnabled = true;"
	else
		echo "var qosEnabled = false;"
	fi
?>

//-->
</script>

<form>
	<fieldset>
		<legend class="sectionheader">QoS (Download) -- Classification Rules</legend>

		<div id='qos_enabled_container' class='nocolumn'>
			<input type='checkbox' id='qos_enabled' onclick="setQosEnabled()" />
			<label id='qos_enabled_label' for='qos_enabled'>Enable Quality of Service (Download Direction)</label>
		</div>
		<div class="indent">
			<p>Quality of Service (QoS) provides a way to control how available bandwidth is allocated.  Connections are classified into
			different &ldquo;service classes,&rdquo; each of which is allocated a share of the available bandwidth.  QoS should be applied
			in cases where you want to divide available bandwidth between competing requirements.  For example if you want
			your VoIP phone to work correctly while downloading videos.  Another case would be if you want your bit torrents
			throttled back when you are web surfing. 
		  </p>
		</div>
		<div class="internal_divider"></div>

		<div id='qos_rule_table_container' class="bottom_gap"></div>
		<div>
			<label class="leftcolumn" id="total_bandwidth_label" for="total_bandwidth">Default Service Class:</label>
			<select class="rightcolumn" id="default_class"></select>
		</div>

		<div>
			<label class="leftcolumn" id="total_bandwidth_label" for="total_bandwidth">Total (Download) Bandwidth:</label>
			<input type="text" class="rightcolumn" id="total_bandwidth" class="rightcolumn" onkeyup="proofreadNumeric(this)"  size='10' maxlength='10' />
			<em>kbit/s</em>

		</div>

		<div id="qos_down_1" class="indent">
			<span id='qos_down_1_txt'>
				<p> Specifying your total bandwidth correctly is crucial to making QoS work.  You should enter the minimum bandwith your ISP
				provides you ignoring "Speedboosting" or other advertised peak values which change in ways that QoS cannot compensate for.
				Entering a number which is too low will result in a connection which is slower then necessary.  Entering a number which is
				too high will	result in QoS not meeting its class requirements.  Since some ISPs don't provide you a guaranteed minimum
				bandwith it may take some experimentation to arrive at a number.  One approach is to start with a number which is half of what you
				think it should be and then test your link under full load and make sure everything works.  Then increase it in steps, testing as
				you go until QoS starts to break down.  You also may see that after your testing QoS works for a while and then stops working.
				This may be because your ISP is getting overloaded due to demands from their other customers so they are no longer
				delivering to you the bandwidth they did during your testing.  The solution, lower this number.

				Note that bandwidth is specified in kilobit/s.  There are 8 kilobits per kilobyte.</p>

				<p>The default service class specifies how packets that do not match any rule should be classified.</p>

				<p>Packets are tested against the rules in the order specified -- rules toward the top have priority.
				As soon as a packet matches a rule it is classified, and the rest of the rules are ignored.  The order of
				the rules can be altered using the arrow controls.</p>
			</span>
			<a onclick='setDescriptionVisibility("qos_down_1")'  id="qos_down_1_ref" href="#qos_down_1">Hide Text</a>
		</div>


		<div class="internal_divider">
			<p>
		</div>

		<div><strong>Add New Classification Rule:</strong></div>
		<div class="indent">
			<div>
				<div class='leftcolumn'>
					<input type='checkbox'  id='use_source_ip' onclick='enableAssociatedField(this,"source_ip", "")' />
					<label id="source_ip_label" for='source_ip'>Source IP:</label>
				</div>
				<input class='rightcolumn' type='text' id='source_ip' onkeyup='proofreadIpRange(this)' size='17' maxlength='31' />
			</div>
			<div>
				<div class='leftcolumn'>
					<input type='checkbox'  id='use_source_port' onclick='enableAssociatedField(this,"source_port", "")'/>
					<label id="source_port_label" for='source_port'>Source Port(s):</label>
				</div>
				<input class='rightcolumn' type='text' id='source_port' onkeyup='proofreadPortOrPortRange(this)' size='17' maxlength='11' />
			</div>
			<div>
				<div class='leftcolumn'>
					<input type='checkbox'  id='use_dest_ip' onclick='enableAssociatedField(this,"dest_ip", "")' />
					<label id="dest_ip_label" for='dest_ip'>Destination IP:</label>
				</div>
				<input class='rightcolumn' type='text' id='dest_ip' onkeyup='proofreadIpRange(this)' size='17' maxlength='31' />
			</div>
			<div>
				<div class='leftcolumn'>
					<input type='checkbox'  id='use_dest_port' onclick='enableAssociatedField(this,"dest_port", "")'  />
					<label id="dest_port_label" for='dest_port'>Destination Port(s):</label>
				</div>
				<input class='rightcolumn' type='text' id='dest_port' onkeyup='proofreadPortOrPortRange(this)' size='17' maxlength='11' />
			</div>

			<div>
				<div class='leftcolumn'>
					<input type='checkbox'  id='use_max_pktsize' onclick='enableAssociatedField(this,"max_pktsize", "")'  />
					<label id="max_pktsize_label" for='max_pktsize'>Maximum Packet Length:</label>
				</div>
				<input class='rightcolumn' type='text' id='max_pktsize' onkeyup='proofreadNumericRange(this,1,1500)' size='17' maxlength='4' />
				<em>bytes</em>
			</div>
			<div>
				<div class='leftcolumn'>
					<input type='checkbox'  id='use_min_pktsize' onclick='enableAssociatedField(this,"min_pktsize", "")'  />
					<label id="min_pktsize_label" for='min_pktsize'>Minimum Packet Length:</label>
				</div>
				<input class='rightcolumn' type='text' id='min_pktsize' onkeyup='proofreadNumericRange(this,1,1500)' size='17' maxlength='4' />
				<em>bytes</em>
			</div>


			<div>
				<div class='leftcolumn'>
					<input type='checkbox'  id='use_transport_protocol' onclick='enableAssociatedField(this,"transport_protocol", "")'  />
					<label id="transport_protocol_label" for='transport_protocol'>Transport Protocol:</label>
				</div>
				<select class='rightcolumn' id="transport_protocol"/>
					<option value="TCP">TCP</option>
					<option value="UDP">UDP</option>
					<option value="ICMP">ICMP</option>
				</select>
			</div>

			<div>
				<div class='leftcolumn'>
					<input type='checkbox'  id='use_connbytes_kb' onclick='enableAssociatedField(this,"connbytes_kb", "")'  />
					<label id="connbytes_kb_label" for='connbytes_kb'>Connection bytes reach:</label>
				</div>
				<input class='rightcolumn' type='text' id='connbytes_kb' onkeyup='proofreadNumericRange(this,0,4194303)' size='17' maxlength='28' />
				<em>kBytes</em>
			</div>

			<div>
				<div class='leftcolumn'>
					<input type='checkbox'  id='use_app_protocol' onclick='enableAssociatedField(this,"app_protocol", "")' />
					<label id="app_protocol_label" for='app_protocol'>Application (Layer7) Protocol:</label>
				</div>
				<select class='rightcolumn' id="app_protocol">
				<?
				sed -e "s/#.*//" -e "s/\([^ ]* \)\(.*\)/<option value='\1'>\2<\/option>/" /etc/l7-protocols/l7index
				?>
				</select>
			</div>

			<div>
				<label class='leftcolumn' id="classification_label" for='class_name' >Set Service Class To:</label>
				<select class='rightcolumn' id="classification">
				</select>
			</div>


			<div id="add_rule_container">
				<input type="button" id="add_rule_button" class="default_button" value="Add Rule" onclick="addClassificationRule()" />
			</div>
	</div>
	</fieldset>

	<fieldset>

		<legend class="sectionheader">QoS (Download) -- Service Classes</legend>
		<div id='qos_class_table_container' class="bottom_gap"></div>

		<div id="qos_down_2" class="indent">
			<span id='qos_down_2_txt'>
				<p>Each service class is specified by three parameters: percent bandwidth at capacity, minimum bandwidth and maximum bandwidth.</p>

				<p><em>Percent bandwidth at capacity</em> is the percentage of the total available bandwidth that should be allocated to this class
				when all available bandwidth is being used.  If unused bandwidth is available, more can (and will) be allocated.
				The percentages can be configured to equal more (or less) than 100, but when the settings are applied the percentages will be adjusted
				proportionally so that they add to 100.</p>

				<p><em>Minimum bandwidth</em> specifies the minimum service this class will be allocated when the link is at capacity.
				For certain applications like VoIP or online gaming it is better to specify a minimum service in bps rather than a percentage.
				QoS will satisfiy the minimum service of all classes first before allocating the remaining service to other waiting classes.
				</p>

				<p><em>Maximum bandwidth</em> specifies an absolute maximum amount of bandwidth this class will be allocated in kbit/s.  Even if unused bandwidth
				is available, this service class will never be permitted to use more than this amount of bandwidth.</p>
			</span>
			<a onclick='setDescriptionVisibility("qos_down_2")'  id="qos_down_2_ref" href="#qos_down_2">Hide Text</a>

		</div>

		<div class="internal_divider"></div>


		<div><strong>Add New Service Class:</strong></div>
		<div class="indent">

			<div>
				<label class='leftcolumn' id="class_name_label" for='class_name'  >Service Class Name:</label>
				<input class='rightcolumn' type='text' id='class_name' onkeyup="proofreadLengthRange(this,1,10)" size='12' maxlength='10' />
			</div>

			<div>
				<label class='leftcolumn' id="percent_bandwidth_label" for='percent_bandwidth' >Percent Bandwidth At Capacity:</label>
				<div class='rightcolumn'>
					<input type='text' id='percent_bandwidth' onkeyup="proofreadNumericRange(this,1,100)"  size='5' maxlength='3' />
					<em>%</em>
				</div>
			</div>

			<div class='nocolumn'>Bandwidth Minimum:</div>
			<div class='indent'>
				<div class='nocolumn'>
					<input type='radio' name="min_radio" id='min_radio1' onclick='enableAssociatedField(document.getElementById("min_radio2"),"min_bandwidth", "")' />
					<label for='min_radio1'>No Bandwidth Minimum</label>
				</div>
				<div>
					<span class='leftcolumn'>
						<input type='radio' name="min_radio" id="min_radio2" onclick='enableAssociatedField(document.getElementById("min_radio2"),"min_bandwidth", "")' />
						<label id="min_bandwidth_label" for='min_radio2'>Bandwidth Minimum:</label>
					</span>
					<span class='rightcolumn'>
						<input type='text' class="rightcolumn" id='min_bandwidth' onkeyup="proofreadNumeric(this)"  size='10' maxlength='10' />
						<em>kbit/s</em>
					</span>
				</div>
			</div>

			<div class='nocolumn'>Bandwidth Maximum:</div>
			<div class='indent'>
				<div class='nocolumn'>
					<input type='radio' name="max_radio" id='max_radio1' onclick='enableAssociatedField(document.getElementById("max_radio2"),"max_bandwidth", "")' />
					<label for='max_radio1'>No Bandwidth Maximum</label>
				</div>
				<div>
					<span class='leftcolumn'>
						<input type='radio' name="max_radio" id="max_radio2" onclick='enableAssociatedField(document.getElementById("max_radio2"),"max_bandwidth", "")' />
						<label id="max_bandwidth_label" for='max_radio2'>Bandwidth Maximum:</label>
					</span>
					<span class='rightcolumn'>
						<input type='text' class="rightcolumn" id='max_bandwidth' onkeyup="proofreadNumeric(this)"  size='10' maxlength='10' />
						<em>kbit/s</em>
					</span>
				</div>
			</div>

			<div id="add_class_container">
				<input type="button" id="add_class_button" class="default_button" value="Add Service Class" onclick="addServiceClass()" />
			</div>
		</div>
	</fieldset>

	<fieldset>

		<legend class="sectionheader">QoS (Download) -- Active Congestion Control</legend>

		<div id='qos_monitor_container' class='nocolumn'>
			<input type='checkbox' id='qos_monenabled' onclick="setQosEnabled()"/>
			<label id='qos_monenabled_label' for='qos_monenabled'>Enable active congestions control (Download Direction)</label>
		</div>

		<div>
			<span class='indent'>
				<input type='checkbox' id='use_ptarget_ip' onclick='enableAssociatedField(this, "ptarget_ip", currentWanGateway)'/>&nbsp;&nbsp;
				<label for='ptarget_ip' id='ptarget_ip_label'>Use non-standard ping target:</label>
				<input type='text' name='ptarget_ip' id='ptarget_ip' onkeyup='proofreadIpRange(this)' size='17' maxlength='31' /> 
			</span>
		</div>

		<div id="qos_down_3" class="indent">
		<span id='qos_down_3_txt'>
			<p>The congestion control observes your download activiy and automatically adjusts your download limit to maintain
                     proper QoS performance.  The control automatically compensates for changes in your ISP's download speed
                     and the demand from your network and results in optimum performance.

			To use this feature set your QoS downlink speed to the maximum speed your ISP can deliver you in the best of
                     circumstances.  The control will maintain the downlink between 20% and 100% of this value as needed to 
			maintain the QoS goals.  You must also enable your upload QoS and set it to 95% of your measured uplink speed. 
                     </p>
		</span>
		<a onclick='setDescriptionVisibility("qos_down_3")'  id="qos_down_3_ref" href="#qos_down_3">Hide Text</a>

		</div>
		<div class="internal_divider"></div>

              <div class="indent">
              <table>
              <tr><td><strong>Congestion Control Status</strong></td></tr>
              <tr><td><span id='qstate'></span></td></tr>
              <tr><td><span id='qllimit'></span></td></tr>
              <tr><td><span id='qollimit'></span></td></tr>
              <tr><td><span id='qload'></span></td></tr>
              <tr><td><span id='qpinger'></span></td></tr>
              <tr><td><span id='qpingtime'></span></td></tr>
              <tr><td><span id='qpinglimit'></span></td></tr>
              <tr><td><span id='qactivecnt'></span></td></tr>
              </table>
              </div>

		<div id="qos_down_4" class="indent">
			<span id='qos_down_4_txt'>
                            <table>
              		<tr><td><strong>Status Help</strong></td></tr>
                            <tr><td>CHECK</td><td>Check to see if the ping target will respond</td></tr>
                            <tr><td>INIT</td><td>Estimate a ping limit</td></tr>
                            <tr><td>WATCH</td><td>Congestion under active control.</td></tr>
                            <tr><td>WAIT</td><td>No Congestion, control idle.<td></tr>
                            <tr><td>FREE</td><td>No competing QoS goals, release limits.</td></tr>
                            <tr><td>CHILL</td><td>Moving to WATCH, stablize with new limit.</td></tr>
                            <tr><td>DISABLE</td><td>Controller is not enabled</td></tr>
                            <tr><td>Link Limit</td><td>The download bandwidth limit currently enforce.</td></tr>
                            <tr><td>Fair Link Limit</td><td>The apparent fair download bandwidth limit.</td></tr>
                            <tr><td>Link Load</td><td>The current traffic in the downlink.</td></tr>
                            <tr><td>Ping</td><td>The round trip time of the last ping.</td></tr>
                            <tr><td>Filtered Ping</td><td>The round trip time filtered.</td></tr>
                            <tr><td>Ping Limit</td><td>The point at which the controller will act to maintian fairness.</td></tr>
                            <tr><td>Active Classes</td><td>Number of download classes with load over 4kbps.</td></tr>
				</table>
			</span>
			<a onclick='setDescriptionVisibility("qos_down_4")'  id="qos_down_4_ref" href="#qos_down_4">Hide Text</a>

		</div>


	</fieldset>


	<div id="bottom_button_container">
		<input type='button' value='Save Changes' id="save_button" class="bottom_button" onclick='saveChanges()' />
		<input type='button' value='Reset' id="reset_button" class="bottom_button" onclick='resetData()'/>
	</div>
	<span id="update_container" >Please wait while new settings are applied. . .</span>
</form>

<!-- <br /><textarea style="margin-left:20px;" rows=30 cols=60 id='output'></textarea> -->

<script>
<!--
	resetData();
//-->
</script>


<?
	gargoyle_header_footer -f -s "firewall" -p "qosdownload"
?>
