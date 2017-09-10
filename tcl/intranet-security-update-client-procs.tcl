# /intranet-security-update-client/tcl/intranet-security-update-client-procs.tcl
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


# ------------------------------------------------------------
#
# ------------------------------------------------------------

ad_proc im_security_update_package_look_up_table { } {
    Returns a look up table (LUT) mapping ]po[ package names
    into a two-letter abbreviation.
    Used to "compress" package names, because the securty-update 
    client can only deal with 2048 characters in the URL.
} {
    # Define a Look-Up-Table for package names.
    # Last code is "fr" for "intranet-trans-invoice-authorization" for ]po[ stuff
    # Last code is "xx" for "xowiki" for OpenACS stuff
    set lut_list {
	acs-admin			aa
	acs-api-browser			ab
	acs-authentication		ac
	acs-automated-testing		ad
	acs-bootstrap-installer		ae
	acs-content-repository		af
	acs-core-docs			ag
	acs-datetime			ah
	acs-developer-support		ai
	acs-events			aj
	acs-kernel			ak
	acs-lang			al
	acs-mail			am
	acs-mail-lite			an
	acs-messaging			ao
	acs-reference			ap
	acs-service-contract		aq
	acs-subsite			ar
	acs-tcl				as
	acs-templating			at
	acs-translations		au
	acs-workflow			av
	ajaxhelper			ba
	ams				bb
	attachments			fc
	auth-ldap			bc
	auth-ldap-adldapsearch		bd
	auth-ldap-openldap		fb
	batch-importer			be
	bug-tracker			bf
	bulk-mail			bg
	calendar			bh
	categories			bi
	chat				bj
	cms				bk
	contacts			bl
	diagram				bm
	ecommerce			bn
	edit-this-page			bs
	events				bo
	faq				bq
	file-storage			fd
	general-comments		br
	intranet-agile			fs
	intranet-amberjack		ca
	intranet-asus-server		fe
	intranet-audit			cb
	intranet-baseline		ff
	intranet-big-brother		cc
	intranet-bug-tracker		cd
	intranet-calendar		ce
	intranet-calendar-holidays	cf
	intranet-checklist		ft
	intranet-confdb			cg
	intranet-contacts		ch
	intranet-core			ci
	intranet-cost			cj
	intranet-cost-center		ck
	intranet-crm-opportunities	fu
	intranet-crm-tracking		cl
	intranet-cvs-import		fv
	intranet-cust-baselkb		cm
	intranet-cust-cambridge		cn
	intranet-cust-issa		co
	intranet-cust-lexcelera		cp
	intranet-cust-projop		cq
	intranet-cust-reinisch		cr
	intranet-cust-versia		fg
	intranet-cvs-integration	cs
	intranet-demo-data		fw
	intranet-department-planner	fx
	intranet-dw-light		ct
	intranet-dynfield		cu
	intranet-earned-value-management fy
	intranet-employee-evaluation	fz
	intranet-estimate-to-complete	ga
	intranet-events			gb
	intranet-exchange-rate		cv
	intranet-expenses		cw
	intranet-expenses-workflow	cx
	intranet-filestorage		cy
	intranet-filestorage-size-indicator gc
	intranet-forum			cz
	intranet-freelance		da
	intranet-freelance-invoices	db
	intranet-freelance-rfqs		dc
	intranet-freelance-translation	dd
	intranet-funambol		fh
	intranet-gantt-editor		gd
	intranet-ganttproject		de
	intranet-gtd-dashboard		fi
	intranet-helpdesk		df
	intranet-horizontal-scaling	ge
	intranet-hr			dg
	intranet-hr-hourly-rates	gf
	intranet-html2pdf		gh
	intranet-icinga2		gi
	intranet-idea-management	gj
	intranet-invoices		dh
	intranet-invoices-templates	di
	intranet-jira			gk
	intranet-mail-import		dj
	intranet-material		dk
	intranet-milestone		dl
	intranet-mylyn			gl
	intranet-nagios			dm
	intranet-navision		gm
	intranet-notes			dn
	intranet-notes-tutorial		do
	intranet-openoffice		gn
	intranet-ophelia		dp
	intranet-otp			dq
	intranet-otrs-integration	go
	intranet-overtime		gp
	intranet-payments		dr
	intranet-pdf-htmldoc		ds
	intranet-planning		fj
	intranet-portfolio-management	fk
	intranet-portfolio-planner	gq
	intranet-procedures		gr
	intranet-project-reminders	gs
	intranet-project-scoring	gt
	intranet-release-mgmt		dt
	intranet-reporting		du
	intranet-reporting-cubes	dv
	intranet-reporting-dashboard	dw
	intranet-reporting-finance	dx
	intranet-reporting-indicators	dy
	intranet-reporting-openoffice	gu
	intranet-reporting-translation	dz
	intranet-reporting-tutorial	ea
	intranet-resource-management	fl
	intranet-rest			fm
	intranet-riskmanagement		eb
	intranet-rss-reader		fn
	intranet-rule-engine		gv
	intranet-scrum			fo
	intranet-search-pg		ec
	intranet-search-pg-files	ed
	intranet-security-update-client	ee
	intranet-security-update-server	ef
	intranet-sharepoint		fp
	intranet-simple-survey		eg
	intranet-slack			gw
	intranet-sla-management		fq
	intranet-soap-lite-server	eh
	intranet-spam			ei
	intranet-sql-selectors		ej
	intranet-sugarcrm		gx
	intranet-sysconfig		ek
	intranet-task-management	gy
	intranet-timesheet2		el
	intranet-timesheet2-interval	gz
	intranet-timesheet2-invoices	em
	intranet-timesheet2-task-popup	en
	intranet-timesheet2-tasks	eo
	intranet-timesheet2-workflow	ep
	intranet-timesheet-reminders	ha
	intranet-tinytm			eq
	intranet-touch-timesheet	hb
	intranet-trans-invoice-authorization	fr
	intranet-trans-invoices		er
	intranet-trans-project-feedback	hc
	intranet-trans-project-wizard	et
	intranet-trans-quality		eu
	intranet-translation		es
	intranet-ubl			ev
	intranet-update-client		ew
	intranet-update-server		ex
	intranet-wall			hd
	intranet-wiki			ey
	intranet-workflow		ez
	intranet-xmlrpc			fa
	lars-blogger			xa
	mail-tracking			xb
	notifications			xc
	oacs-dav			xu
	openacs-default-theme		xv
	organizations			xd
	oryx-ts-extensions		xe
	postal-address			xf
	ref-countries			xg
	ref-currency			xy
	ref-itu				xz
	ref-language			xh
	ref-timezones			xi
	ref-us-counties			xj
	ref-us-states			xk
	ref-us-zipcodes			xl
	rss-support			xm
	search				xn
	sencha-core			ya
	sencha-extjs-v421		yb
	sencha-extjs-v421-dev		yc
	sencha-filestorage		yd
	sencha-member-portlet		ye
	sencha-reporting-portfolio	yf
	sencha-task-editor		yg
	senchatouch-notes		yh
	senchatouch-timesheet		yi
	senchatouch-v242		yj
	simple-survey			xo
	telecom-number			xp
	trackback			xq
	tsearch2-driver			yk
	upgrade-3.0-3.1			za
	upgrade-3.1-3.2			zb
	upgrade-3.2-3.3			zc
	upgrade-3.3-3.4			zd
	upgrade-3.4-3.5			ze
	upgrade-3.5-4.0			zf
	upgrade-4.0-4.1			zg
	upgrade-4.1-5.0			zh
	wiki				xr
	workflow			xs
	xml-rpc				xt
	xotcl-core			xw
	xotcl-request-monitor		yk
	xowiki				xx
    }
    return $lut_list
}


ad_proc im_security_update_asus_status { 
    { -no_return_value_p 0}
} {
    Returns the status of the ASUS configuration (1=verbose, 0=anonymous)
    OR redirects to the ASUS Terms & Conditions page
    if the ASUS was not configured.
} {
    set return_url [ad_conn url]
    set package_key "intranet-security-update-client"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set sec_verbosity [parameter::get -package_id $package_id -parameter "SecurityUpdateVerboseP" -default "0"]

    # -1 means that the user needs to confirm using the UpdateService
    if {-1 == $sec_verbosity} {
	ad_returnredirect [export_vars -base "/intranet-security-update-client/user-agreement" {return_url}]
    }
    
    # No return value for use as a component when just checking if the ASUS is configured
    if {$no_return_value_p} { return "" }

    return $sec_verbosity
}




ad_proc im_security_update_client_component { } {
    Shows a a component mainly consisting of an IFRAME.
    Passes on the version numbers of all installed packages
    in order to be able to retreive relevant messages
} {
    set current_user_id [auth::require_login]
    set action_url "/intranet-security-update-client/update-preferences"
    set return_url [ad_conn url]

    set package_key "intranet-security-update-client"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set sec_url_base [parameter::get -package_id $package_id -parameter "SecurityUpdateServerUrl" -default "http://www.project-open.net/intranet-asus-server/update-information"]

    # Verbose ASUS configuration?
    # May redirect to user-agreement to confirm ASUS terms & conditions
    set sec_verbosity [im_security_update_asus_status]

    global tcl_platform
    set os_platform [lindex $tcl_platform(os) 0]
    set os_version [lindex $tcl_platform(osVersion) 0]
    set os_machine [lindex $tcl_platform(machine) 0]
    set tcl_version [info patchlevel]
    set aol_version [ns_info version]

    # There's a chance that tcl_platform does not return any results 
    if {[catch {
	if { "" == $os_platform } { set os_platform $::tcl_platform(platform) }
	if { "" == $os_version } { set os_version $::tcl_platform(osVersion) }
	if { "" == $os_machine } { set os_machine $::tcl_platform(machine) }
    } err_msg]} {
	ns_log Error "Error evaluating tcl_platform(platform), tcl_platform(osVersion), tcl_platform(machine)"
    }

    # Load Average
    if {[catch {
	set load_avg [im_exec bash -c "cat /proc/loadavg"]
    } err_msg]} {
	global errorInfo
        ns_log Error "Error evaluating Load Average - $errorInfo"
	set load_avg [lang::message::lookup "" intranet-security-update-client.CantEvaluateLoadAverage "Can't evaluate Load Average"]
    }

    # Add the list of package versions to the URL in order to get 
    # the right messages

    # Define a look up table LUT mapping package names into abbreviations.
    array set lut_hash [im_security_update_package_look_up_table]

    # Go through the list of all packages and add to the URL
    set package_sql "
	select	v.package_key,
	        v.version_name
	from	(	select	max(version_id) as version_id,
				package_key
			from	apm_package_versions
		        group by package_key
	        ) m,
	        apm_package_versions v
	where	m.version_id = v.version_id
    "

    set sec_url "$sec_url_base?"
    db_foreach package_versions $package_sql {

	# copress package name if available in LUT
	if {[info exists lut_hash($package_key)]} { set package_key $lut_hash($package_key) }

	# Check if the version number has the format like: "3.4.0.7.0"
	# In this case we can savely remove the dots between the digits.
	if {[regexp {^[0-9]\.[0-9]\.[0-9]\.[0-9]\.[0-9]$} $version_name match]} {
	    regsub -all {\.} $version_name "" version_name
   	}

	# shorten the "intranet-" and "acs-" prefix from packages to save space
	if {[regexp {^intranet\-(.*)} $package_key match key]} { set package_key "i-$key"}
	if {[regexp {^acs\-(.*)} $package_key match key]} { set package_key "a-$key"}

	append sec_url "p.[string trim $package_key]=[string trim $version_name]&"
    }

    if {0 != $sec_verbosity} {
	append sec_url "email=[string trim [db_string email "select im_email_from_user_id(:current_user_id)"]]&"

	set compname [db_string compname "select company_name from im_companies where company_path='internal'" -default "Tigerpond"]
	append sec_url "compname=[ns_urlencode [string trim $compname]]&"

	# Get the name of the server from the URL pointing to this page.
	set header_vars [ns_conn headers]
	set host [ns_set get $header_vars "Host"]
	append sec_url "host=[ns_urlencode [string trim $host]]&"
    }

    # Get the number of active users for the three most important groups
    foreach g [list "employees" "customers" "freelancers"] {
	set count [db_string emp_count "
		select	count(*)
		from	cc_users u, 
			acs_rels r, 
			membership_rels m, 
			groups g 
		where	lower(group_name) = :g and 
			r.object_id_two = u.user_id and 
			r.object_id_one = g.group_id and 
			u.member_state = 'approved' 
			and r.rel_id = m.rel_id and 
			m.member_state = 'approved'
	"]
	set abbrev [string range $g 0 2]
	append sec_url "g.$abbrev=$count&"
    }

    append sec_url "os_platform=[string trim $os_platform]&"
    append sec_url "os_version=[string trim $os_version]&"
    append sec_url "os_machine=[string trim $os_machine]&"
    append sec_url "pg_version=[string trim [im_database_version]]&"   
    append sec_url "sid=[im_system_id]&"
    append sec_url "hid=[im_hardware_id]"

    set security_update_l10n [lang::message::lookup "" intranet-security-update-client.Release_Status_Information "Release Status Information"]
    set no_iframes_l10n [lang::message::lookup "" intranet-security-update-client.Your_browser_cant_display_iframes "Your browser can't display IFrames. Please click for here for <a href=\"$sec_url_base\">security update messages</a>."]

    set asus_url [export_vars -base "/intranet-security-update-client/retreive-update-list" {{show_master_p 0} {show_help_p 0}}]
    set asus_l10n [lang::message::lookup "" intranet-security-update-client.Security_Updates "ASUS Security Updates"]

    set anonymous_selected ""
    set verbose_selected ""
    if {0 == $sec_verbosity} {
	set anonymous_selected "checked"
    } else {
	set verbose_selected "checked"
    }

    # Check for upgrades to run
    set server_information "[_ intranet-security-update-client.Server_Information]: 
    <ul>
	<li> &#93project-open&#91; [_ intranet-core.Version]: [im_core_version]</li>
	<li>[_ intranet-security-update-client.Platform]: $os_platform</li>
	<li>[_ intranet-security-update-client.OS_Version]: $os_version</li>
	<li>[_ intranet-security-update-client.TCL_Version]: $tcl_version</li>
	<li>[_ intranet-security-update-client.Web_Server_Version]: $aol_version</li>
	<li>[_ intranet-security-update-client.System_Id]: [im_system_id]</li>
	<li>[_ intranet-security-update-client.Load_Average]: $load_avg</li>
    </ul><br><br>"
    set script_list [im_check_for_update_scripts]

    set sec_html "
	<table width='600'>
        <tr valign=top>
	<td width=50%'>
		$server_information
 	</td>
        <td width='50%' valign=top>

		<iframe src=\"$sec_url\" width=\"100%\" height=\"130\" frameBorder=0 name=\"$security_update_l10n\">
		  <p>$no_iframes_l10n</p>
		</iframe>

	<form action=\"$action_url\" method=POST>
	    <input type=\"radio\" name=\"verbosity\" value=\"1\" $verbose_selected>Detailed
	    [im_gif -translate_p 1 help "Choose this option for detailed security information. With this option the security update service transmits information about your configuration that might help us to assess your &#93project-open&#91; system configuration including package versions and operating system version information. It also includes your email address so that we can alert your in special situations."]
	    <input type=\"radio\" name=\"verbosity\" value=\"0\" $anonymous_selected>Anonymous
	    [im_gif -translate_p 1 help "Choose this option if you prefer not to reveal any information to &#93project-open&#91; that might identify you or your organization."]
	    <input type=\"hidden\" name=\"return_url\" value=\"$return_url\">
	    <input type=\"submit\" name=\"submit\" value=\"OK\">
	</form>

        </td>
	</tr>

        <tr><td colspan=2> 
		$script_list 
	</td></tr>

	<tr><td colspan=2 width=500>

		<iframe src=\"$asus_url\" width=\"100%\" height=\"100\" frameBorder=0 name=\"$asus_l10n\">
		  <p>$no_iframes_l10n</p>
		</iframe>

	</td></tr>
	</table>
    "

    return $sec_html
}






# ------------------------------------------------------
# Check if the user is connected
# ------------------------------------------------------

ad_proc im_security_update_connected_email {
} {
    Returns a triple {asus_email asus_error asus_error_message}
    with the email of www.project-open.net account connected
    to the current system_id
} {
    set system_id [im_system_id]
    set service_base_url "http://www.project-open.net/intranet-asus-server/connected-user-account.xml"
    set full_url [export_vars -base $service_base_url {system_id}]
    set update_xml ""
    set error_msg ""
    set login_status "error"
    
    if { [catch {
	set update_xml [im_httpget $full_url]
    } errmsg] } {
	ad_return_complaint 1 "Error while accessing the URL '$service_base_url'.<br>
    Please check your URL. The following error was returned: <br>
    <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>"
	ad_script_abort
	return
    }
    

    # Check for empty update
    if {"" == $update_xml} {
	ad_return_complaint 1 "Found an empty XML file accessing the URL '$service_base_url'.<br>
    This means that your server(!) was not able to access the URL.<br>
    Please check the the Internet and firewall configuration of your
    server and verify that the 'nsd' (Linux) or 'nsd4' (Windows)
    process has access to the URL.<br>"
	ad_script_abort
	return
    }
    
# Check whether it's a HTML or an XML
    if {![regexp {<asus_reply>} $update_xml match]} {
	ad_return_complaint 1 "Error while retreiving update information from
    URL '$service_base_url'.<br>The retreived files doesn't seem to be a valid XML file:<br>
    <pre>[ns_quotehtml $update_xml]</pre>"
	ad_script_abort
	return
    }
    
    # Sample reply:
    #
    # <asus_reply>
    #   <email>ssales@tigerpond.com</email>
    #   <error>invalid_system_id</error>
    #   <error_message>Invalid SystemID '$system_id'</error_message>
    # <asus_reply>
    
    set tree [xml_parse -persist $update_xml]
    set root_node [xml_doc_get_first_node $tree]
    set root_name [xml_node_get_name $root_node]
    if { $root_name ne "asus_reply" } {
	ad_return_complaint 1 "Expected &lt;asus_reply&gt; as root node of update.xml file, found: '$root_name'"
    }
    
    set asus_email [$root_node selectNodes {//email}]
    set asus_error [[$root_node selectNodes {//error}] text]
    set asus_error_message [[$root_node selectNodes {//error_message}] text]
 
    return [list asus_email $asus_email asus_error $asus_error asus_error_message $asus_error_message]
}



