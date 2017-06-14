# /intranet-security-update-client/tcl/intranet-exchange-rate-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_library {
    Checks for security update messages on a central security
    update server.

    @author frank.bergmann@project-open.com
    @creation-date  January 1st, 2006
}


# ----------------------------------------------------------------------
# Get Exchange Rate from Update Server
# ----------------------------------------------------------------------

ad_proc -public im_security_update_exchange_rate_sweeper { } {
    Checks if exchange rates haven't been updated in a certain time.
} {
    ns_log Notice "im_security_update_exchange_rate_sweeper: Starting"

    # Determine every how many days we want to update
    set max_days_since_update [parameter::get_from_package_key -package_key intranet-security-update-client -parameter ExchangeRateDaysBeforeUpdate -default 1]

    # Check for the last update
    set last_update_julian ""
    set now_julian ""
    set last_update_sql "
	select	to_char(max(day), 'J') as last_update_julian,
		to_char(now(), 'J') as now_julian
	from	im_exchange_rates
	where	manual_p = 't'
    "
    db_0or1row last_update $last_update_sql

    if {"" == $last_update_julian} { 
	ns_log Error "im_security_update_exchange_rate_sweeper: Didn't find last exchange rate update"
	db_string log "select acs_log__debug('im_security_update_exchange_rate_sweeper', 'Did not find last exchange rate update. Please perform at least one update manually.')"
	return
    }

    set days_since_update [expr {$now_julian - $last_update_julian}]
    ns_log Notice "im_security_update_exchange_rate_sweeper: days_since_update=$days_since_update, max_days_since_update=$max_days_since_update"
    if {$days_since_update > $max_days_since_update} {

	set currency_update_url [im_security_update_get_currency_update_url]
	ns_log Notice "im_security_update_exchange_rate_sweeper: Updating ..."

	if { [catch {
	    set update_xml [im_httpget $currency_update_url]
	} err_msg] } {
	    ns_log Error "im_security_update_exchange_rate_sweeper: Error retreiving file: $err_msg"
	    db_string log "select acs_log__debug('im_security_update_exchange_rate_sweeper', 'Error retreiving currency file: [ns_quotehtml $err_msg].')"
	    return
	}

	# Parse the file and update exchange rates
	im_security_update_update_currencies -update_xml $update_xml

	# Write out a log message
	db_string log "select acs_log__debug('im_security_update_exchange_rate_sweeper', 'Successfully updated exchange rates')"

    } else {
	ns_log Notice "im_security_update_exchange_rate_sweeper: NOT UPDATING: days_since_update: days_since_update < $max_days_since_update"
    }
    ns_log Notice "im_security_update_exchange_rate_sweeper: Finished"
}


# ------------------------------------------------------------
# Get the Currency Update file
# ------------------------------------------------------------

ad_proc im_security_update_get_currency_update_url { } {
    Get the URL from which we can retreive an update XML file.
} {
    set currency_update_url [parameter::get_from_package_key -package_key "intranet-exchange-rate" -parameter "ExchangeRateUpdateUrl" -default "http://www.project-open.net/intranet-asus-server/exchange-rates.xml"]

    # Construct the URL
    set system_id [im_system_id]
    set full_url [export_vars -base $currency_update_url {system_id}]

    return $full_url
}

# ------------------------------------------------------------
# Parse the XML file and generate the HTML table
# ------------------------------------------------------------

# Sample record:
#
#<asus_reply>
#<error>ok</error>
#<error_message>Success</error_message>
#<exchange_rate iso="AUD" day="2009-04-05">0.713603</exchange_rate>
#<exchange_rate iso="CAD" day="2009-04-05">0.805626</exchange_rate>
#<exchange_rate iso="EUR" day="2009-04-05">1.342500</exchange_rate>
#</asus_reply>


ad_proc im_security_update_update_currencies { 
    -update_xml:required
} {
    Parses the XML file and updates the currency entries.
    This process is run both by a page and a background 
    sweeper process.
} {
    set html ""
    set tree [xml_parse -persist $update_xml]
    set root_node [xml_doc_get_first_node $tree]
    set root_name [xml_node_get_name $root_node]
    if {$root_name ne "asus_reply" } {
	append html "Expected &lt;asus_reply&gt; as root node of update.xml file, found: '$root_name'"
	return $html
    }

    set ctr 0
    set debug ""
    set root_nodes [xml_node_get_children $root_node]
    append html "</ul><h2>Login Status</h2><ul>"

    # login_status = "ok" or "fail"
    set login_status [[$root_node selectNodes {//error}] text]
    set login_message [[$root_node selectNodes {//error_message}] text]
    append html "<li>Login Status: $login_status"
    append html "<li>Login Message: $login_message"
    append html "<br>&nbsp;<br>"
    append html "</ul><h2>Processing Data</h2><ul>"

    foreach root_node $root_nodes {
	
	set root_node_name [xml_node_get_name $root_node]
	ns_log Notice "im_security_update_update_currencies: node_name=$root_node_name"
	
	switch $root_node_name {
	    
	    # Information about the successfull/unsuccessful SystemID
	    error {
		# Ignore. Info is extracted via XPath above
	    }
	    error_message {
		# Ignore. Info is extracted via XPath above
	    }
	    exchange_rate {
		# <exchange_rate iso="CAD" day="2009-04-05">0.805626</exchange_rate>
		set currency_code [apm_attribute_value -default "" $root_node iso]
		set currency_day [apm_attribute_value -default "" $root_node day]
		set exchange_rate [xml_node_get_content $root_node]
				
		# Insert values into the Exchange Rates table
		if {"" != $currency_code && "" != $currency_day} {
		    set currency_exists_p [util_memoize [list db_string currency_exists "select count(*) from currency_codes where iso = '$currency_code' and supported_p = 't'"]]
                    if {!$currency_exists_p} {
                        continue
                    }
                    append html "<li>exchange_rate($currency_code,$currency_day) = $exchange_rate...\n"

		    db_dml delete_entry "
				delete  from im_exchange_rates
				where   day = :currency_day::date and
					currency = :currency_code
		    "
		
		    if {[catch {
			db_dml insert_rates "
				insert into im_exchange_rates (
					day,
					currency,
					rate,
					manual_p
				) values (
					:currency_day::date,
					:currency_code,
					:exchange_rate,
					't'
				)
		        "
			# Delete the automatically generated entries before and after the new entry
			im_exec_dml invalidate "im_exchange_rate_invalidate_entries (:currency_day::date, :currency_code)"
		    } err_msg]} {
			append html "Error adding rates to currency '$currency_code':<br><pre>$err_msg</pre>"
		    }
	
		    # The dollar exchange rate is always 1.000, because the dollar
		    # is the reference currency. So we kan update the dollar as "manual"
		    # to avoid messages that dollar is oudated.
		    db_dml update_dollar "
			update	im_exchange_rates
			set	manual_p = 't'
			where	currency = 'USD' and day = :currency_day::date
		    "
		    append html "Success</li>\n"
		}
	    }
	    
	    default {
		ns_log Notice "load-update-xml-2.tcl: ignoring root node '$root_node_name'"
	    }
	}
    }

    append html "<li>Freeing document nodes</li>\n"
    xml_doc_free $tree

    # Fill holes (= days without manual entries)
    im_exec_dml fill_holes "im_exchange_rate_fill_holes()"
    
    return $html
}


# ------------------------------------------------------------
#
# ------------------------------------------------------------


ad_proc im_exchange_rate_update_component { } {
    Shows a a component mainly consisting of an IFRAME.
    Passes on the version numbers of all installed packages
    in order to be able to retreive relevant messages
} {
    set return_url [ad_conn url]
    set sec_verbosity [im_security_update_asus_status]
    if {0 == $sec_verbosity} {

	set content "
	[lang::message::lookup "" intranet-exchange-rate.Exchange_ASUS_Disabled "
		<p>
		You have chosen to disabled 'Full ASUS'. 
		</p><p>
		However, Automatic Exchange Rate update 
		requires 'Full ASUS' in order to automatically update exchange rates.
		</p>
	"]
	<form action='/intranet-security-update-client/user-agreement'>
	[export_vars -form {return_url}]
	<input type=submit value='[lang::message::lookup "" intranet-exchange-rate.Enable_Full_ASUS "Update ASUS"]'>
	</form>
	"

    } else {

	set content "
	[lang::message::lookup "" intranet-exchange-rate.Exchange_ASUS_Disclaimer "
		<p>
		This service allows you to automatically update your
		exchange rates from our exchange rate server.<br>
		By using this service you accept that we provide this 
		service 'as is' and don't accept any liability for 
		incorrect data and any consequences of using them.
		</p>
	"]
	<form action='/intranet-security-update-client/get-exchange-rates'>
	[export_vars -form {return_url}]
	<input type=submit value='[lang::message::lookup "" intranet-exchange-rate.Button_Get_Exchange_Rates_Now "Get Exchange Rates Now"]'>
	</form>
        "

	set return_url [im_url_with_query]
	set package_key "intranet-security-update-client"
	set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
	set enabled_p [parameter::get_from_package_key -package_key intranet-security-update-client -parameter ExchangeRateSweeperEnabledP -default 0]
	set days_before_update [parameter::get_from_package_key -package_key intranet-security-update-client -parameter ExchangeRateDaysBeforeUpdate -default 0]
	set last_update [db_string last_update "select max(day::date) from im_exchange_rates where manual_p = 't'" -default "never"]
	# append content "<br>\n"
	append content "<h2>[lang::message::lookup "" intranet-exchange-rate.Automatic_Updates_Status "Automatic Update Status"]</h2>\n"
	append content "
		<table>
		<tr>	<td>[lang::message::lookup "" intranet-exchange-rate.Last_Update "Last Update:"]</td>
			<td>$last_update</td>
		</tr>
		<tr>	<td>[lang::message::lookup "" intranet-exchange-rate.Automatic_Updates_Enabled_p "Automatic Update Enabled?"]</td>
			<td>$enabled_p</td>
		</tr>
		<tr>	<td>[lang::message::lookup "" intranet-exchange-rate.Automatic_Updates_Days "Automatic Update Every N Days:"]</td>
			<td>$days_before_update</td>
		</tr>
		</table>
	<form action='/shared/parameters' method=GET>
	[export_vars -form {return_url package_id}]
	<input type=submit value='[lang::message::lookup "" intranet-exchange-rate.Edit_Parameters "Edit Parameters"]'>
	</form>
	"

	append content "<h2>[lang::message::lookup "" intranet-exchange-rate.Automatic_Update_History "Automatic Update History"]</h2>\n"
	append content "<ul>\n"
	set log_sql "
		select	*,
			to_char(log_date, 'YYYY-MM-DD HH24:MI') as log_date_pretty
		from	acs_logs
		where	log_key = 'im_security_update_exchange_rate_sweeper'
		order by log_date DESC
		LIMIT 10
	"
	db_foreach last_logs $log_sql {
	    append content "<li>$log_date_pretty: $message</li>\n"
	}
	append content "</ul>"
    }

    return $content
}



