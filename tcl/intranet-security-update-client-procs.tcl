# /tcl/intranet-security-update-client-procs.tcl
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


ad_proc im_security_update_package_look_up_table { } {
    Returns a look up table (LUT) mapping ]po[ package names
    into a two-letter abbreviation.
    Used to "compress" package names, because the securty-update 
    client can only deal with 2048 characters in the URL.
} {

    # Define a Look-Up-Table for package names.
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
	auth-ldap			bc
	auth-ldap-adldapsearch		bd
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
	events				bo
	faq				bq
	general-comments		br
	intranet-amberjack		ca
	intranet-audit			cb
	intranet-big-brother		cc
	intranet-bug-tracker		cd
	intranet-calendar		ce
	intranet-calendar-holidays	cf
	intranet-confdb			cg
	intranet-contacts		ch
	intranet-core			ci
	intranet-cost			cj
	intranet-cost-center		ck
	intranet-crm-tracking		cl
	intranet-cust-baselkb		cm
	intranet-cust-cambridge		cn
	intranet-cust-issa		co
	intranet-cust-lexcelera		cp
	intranet-cust-projop		cq
	intranet-cust-reinisch		cr
	intranet-cvs-integration	cs
	intranet-dw-light		ct
	intranet-dynfield		cu
	intranet-exchange-rate		cv
	intranet-expenses		cw
	intranet-expenses-workflow	cx
	intranet-filestorage		cy
	intranet-forum			cz
	intranet-freelance		da
	intranet-freelance-invoices	db
	intranet-freelance-rfqs		dc
	intranet-freelance-translation	dd
	intranet-ganttproject		de
	intranet-helpdesk		df
	intranet-hr			dg
	intranet-invoices		dh
	intranet-invoices-templates	di
	intranet-mail-import		dj
	intranet-material		dk
	intranet-milestone		dl
	intranet-nagios			dm
	intranet-notes			dn
	intranet-notes-tutorial		do
	intranet-ophelia		dp
	intranet-otp			dq
	intranet-payments		dr
	intranet-pdf-htmldoc		ds
	intranet-release-mgmt		dt
	intranet-reporting		du
	intranet-reporting-cubes	dv
	intranet-reporting-dashboard	dw
	intranet-reporting-finance	dx
	intranet-reporting-indicators	dy
	intranet-reporting-translation	dz
	intranet-reporting-tutorial	ea
	intranet-riskmanagement		eb
	intranet-search-pg		ec
	intranet-search-pg-files	ed
	intranet-security-update-client	ee
	intranet-security-update-server	ef
	intranet-simple-survey		eg
	intranet-soap-lite-server	eh
	intranet-spam			ei
	intranet-sql-selectors		ej
	intranet-sysconfig		ek
	intranet-timesheet2		el
	intranet-timesheet2-invoices	em
	intranet-timesheet2-task-popup	en
	intranet-timesheet2-tasks	eo
	intranet-timesheet2-workflow	ep
	intranet-tinytm			eq
	intranet-trans-invoices		er
	intranet-translation		es
	intranet-trans-project-wizard	et
	intranet-trans-quality		eu
	intranet-ubl			ev
	intranet-update-client		ew
	intranet-update-server		ex
	intranet-wiki			ey
	intranet-workflow		ez
	intranet-xmlrpc			fa
	lars-blogger			xa
	mail-tracking			xb
	notifications			xc
	organizations			xd
	oryx-ts-extensions		xe
	postal-address			xf
	ref-countries			xg
	ref-language			xh
	ref-timezones			xi
	ref-us-counties			xj
	ref-us-states			xk
	ref-us-zipcodes			xl
	rss-support			xm
	search				xn
	simple-survey			xo
	telecom-number			xp
	trackback			xq
	wiki				xr
	workflow			xs
	xml-rpc				xt
    }
    return $lut_list
}


ad_proc im_security_update_client_component { } {
    Shows a a component mainly consisting of an IFRAME.
    Passes on the version numbers of all installed packages
    in order to be able to retreive relevant messages
} {
    set current_user_id [ad_maybe_redirect_for_registration]
    set action_url "/intranet-security-update-client/update-preferences"
    set return_url [ad_conn url]

    set package_key "intranet-security-update-client"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set sec_url_base [parameter::get -package_id $package_id -parameter "SecurityUpdateServerUrl" -default "http://projop.dnsalias.com/intranet-security-update-server/index"]
    set sec_verbosity [parameter::get -package_id $package_id -parameter "SecurityUpdateVerboseP" -default "0"]

    global tcl_platform
    set os_platform [lindex $tcl_platform(os) 0]
    set os_version [lindex $tcl_platform(osVersion) 0]
    set os_machine [lindex $tcl_platform(machine) 0]

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
	append sec_url "os_platform=[string trim $os_platform]&"
	append sec_url "os_version=[string trim $os_version]&"
	append sec_url "os_machine=[string trim $os_machine]&"

	# extract the PostgreSQL version
	# psql (PostgreSQL) 8.0.8 \ncontains support for command-line editing
	set postgres_version "undefined"
	catch {set postgres_version [exec psql --version]} errmsg
	if {[regexp {([0-9]+\.[0-9]+\.[0-9]+)} $postgres_version match v]} { set postgres_version $v}
	append sec_url "pg_version=[string trim $postgres_version]&"
    }

    append sec_url "sid=[im_system_id]"

    set security_update_l10n [lang::message::lookup "" intranet-security-update-client.Security_Updates "Security Updates"]
    set no_iframes_l10n [lang::message::lookup "" intranet-security-update-client.Your_browser_cant_display_iframes "Your browser can't display IFrames. Please click for here for <a href=\"$sec_url_base\">security update messages</a>."]

    set anonymous_selected ""
    set verbose_selected ""
    if {0 == $sec_verbosity} {
	set anonymous_selected "checked"
    } else {
	set verbose_selected "checked"
    }

    set ttt {
    <pre>$sec_url</pre>
	<pre>[string length $sec_url]</pre>
    }


    # Check for upgrades to run
    set upgrade_message "<b>You are running core version: [im_core_version] </b><br><br>"
    append upgrade_message [im_check_for_update_scripts]


    set sec_html "

	$upgrade_message

	<iframe src=\"$sec_url\" width=\"90%\" height=\"200\" name=\"$security_update_l10n\">
	  <p>$no_iframes_l10n</p>
	</iframe>
	
	<form action=\"$action_url\" method=POST>
	    <input type=\"radio\" name=\"verbosity\" value=\"1\" $verbose_selected>Detailed
	    [im_gif help "Choose this option for detailed security information. With this option the security update service transmits information about your configuration that might help us to assess your &#93project-open&#91; system configuration including package versions and operating system version information. It also includes your email address so that we can alert your in special situations."]
	    <input type=\"radio\" name=\"verbosity\" value=\"0\" $anonymous_selected>Anonymous
	    [im_gif help "Choose this option if you prefer not to reveal any information to &#93project-open&#91; that might identify you or your organization."]
	    <input type=\"hidden\" name=\"return_url\" value=\"$return_url\">
	    <input type=\"submit\" name=\"submit\" value=\"OK\">
	</form>
    "

    return $sec_html
}
