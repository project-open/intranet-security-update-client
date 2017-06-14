# /packages/intranet-update-client/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Main page of the software update service

    @author frank.bergmann@project-open.com
    @creation-date Apr 2005
} {
    { show_only_new_p 1 }
    { show_master_p 1 }
    { show_help_p 1 }
}

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set return_url "[ad_conn url]?[ad_conn query]"
set page_title [lang::message::lookup "" intranet-security-update-client.Automatic_Software_updates "Automatic Software Updates"]
set context_bar [im_context_bar $page_title]

set projop "<span class=brandsec>&#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&#91;</span>"
set po "<span class=brandsec>&#93;</span><span class=brandfirst>po</span><span class=brandsec>&#91;</span>"
set po_wiki "http://www.project-open.com/en"

# Redirects to ASUS terms & conditions if not yet agreed
set asus_verbosity [im_security_update_asus_status]


# ------------------------------------------------------------
# Determine the version of the intranet-core package
# ------------------------------------------------------------

set core_version [im_core_version]
set system_id [im_system_id]
set service_url "http://www.project-open.net/intranet-asus-server/update-list"
set full_url [export_vars -base $service_url {system_id core_version}]

# ------------------------------------------------------------
# Fetch the update.xml file from the remote server
# ------------------------------------------------------------

set update_xml ""
set error_msg ""
set login_status "error"

set httpget_timeout 2
set httpget_max_redirection 1
if { [catch {
    set update_xml [im_httpget $full_url $httpget_timeout $httpget_max_redirection]
} errmsg] } {
    set msg "Error while accessing the URL '$service_url'.<br>
    Please check your URL. The following error was returned: <br>
    <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>"

    if {$show_master_p} {
	ad_return_complaint 1 $msg
    } else {
	doc_return 200 "text/html" "<html><body>$msg</body></html>"
    }
    ad_script_abort
}	

# Check for empty update
if {"" == $update_xml} {
    set msg  "Found an empty XML file accessing the URL '$service_url'.<br>
    This means that your server(!) was not able to access the URL.<br>
    Please check the the Internet and firewall configuration of your
    server and verify that the 'nsd' (Linux) or 'nsd4' (Windows) 
    process has access to the URL."

    if {$show_master_p} {
	ad_return_complaint 1 $msg
    } else {
	doc_return 200 "text/html" "<html><body>$msg</body></html>"
    }
    ad_script_abort
}	

# Check whether it's a HTML or an XML
if {![regexp {<([^>]*)>\s*<([^>]*)>\s*<([^>]*)>} $update_xml match tag1 tag2 tag3]} {
    set msg "Error while retreiving update information from
    URL '$service_url'.<br>The retreived files doesn't seem to be a XML or HTML file:<br>
    <pre>$update_xml</pre>"

    if {$show_master_p} {
	ad_return_complaint 1 $msg
    } else {
	doc_return 200 "text/html" "<html><body>$msg</body></html>"
    }    
    ad_script_abort
}

# Check if the file was an error
if {[string tolower $tag1] eq "/table" || [string tolower $tag1] eq "html" || [string tolower $tag2] eq "html" || [string tolower $tag3] eq "html"} {
    set msg "
	Error while retreiving update information from URL<br>
	'$service_url'.<br>
	The retreived result seems to be a HTML document and not an XML document.<br>
	Please check the URL above and/or send an error report to 
	<a href=\"mailto:support@project-open.com\">support@project-open.com</a>.
	<br>&nbsp;</br>
	Here is what the server returned:
	<br>&nbsp;</br>
	<pre>$update_xml</pre>
    "

    if {$show_master_p} {
	ad_return_complaint 1 $msg
    } else {
	doc_return 200 "text/html" "<html><body>$msg</body></html>"
    }    
    ad_script_abort
}

# ------------------------------------------------------------
# Parse the XML file and generate the HTML table
#

# Sample record:
#
# <po_software_update>
#   <login>
#     <login_status>ok</login_status>
#     <login_message>Successful Login</login_message>
#   </login>
#  <account>
#  </account>
#  <update_list>
#   <update>
#     <package_name>intranet-wiki</package_name>
#     <package_url>http://www.project-open.com/product/modules/km/wiki.html</package_url>
#     <package_version>3.0.0</package_version>
#     <po_version>3.0.beta8</po_version>
#     <po_version_url></po_version_url>
#     <is_new>t</is_new>
#     <release_date>2005-04-18</release_date>
#     <update_urgency format="text/plain">New Package</update_urgency>
#     <forum_url>http://sourceforge.net/forum/forum.php?thread_id=1240473&forum_id=295937</forum_url>
#     <forum_title>New Wiki Module</forum_title>
#     <whats_new>
#       See package description. Please also install the "wiki" module (below).
#     </whats_new>
#   </update>
# </update_list>


if { [catch {
    set tree [xml_parse -persist $update_xml]
    set root_node [xml_doc_get_first_node $tree]
    set root_name [xml_node_get_name $root_node]    
} errmsg] } {
    set msg "Error parsing update information at '$service_url'.<br>
    Please check your URL. The following error was returned: <br>
    <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>"
    if {$show_master_p} {
	ad_return_complaint 1 $msg
    } else {
	doc_return 200 "text/html" "<html><body>$msg</body></html>"
    }
    ad_script_abort
}	


if { $root_name ne "po_software_update" } {
    set msg "Expected <po_software_update> as root node of update.xml file, found: '$root_name'"
    if {$show_master_p} {
	ad_return_complaint 1 $msg
    } else {
	doc_return 200 "text/html" "<html><body>$msg</body></html>"
    }    
    ad_script_abort
}

set ctr 0
set debug ""
set root_nodes [xml_node_get_children $root_node]
set login_status [[$root_node selectNodes {//login_status}] text]
set login_message [[$root_node selectNodes {//login_message}] text]
set version_html ""

foreach root_node $root_nodes {
    set root_node_name [xml_node_get_name $root_node]
    ns_log Notice "retreive-update-list: node_name=$root_node_name"
    switch $root_node_name {
	# Information about the successfull/unsuccessful login 
	# process
	login {
	    # Ignore. Info is extracted via XPath above
	}
	# Information about the customers account, such as an expriation,
	# payment information etc.
	account {
	    # not used yet
	}
	update_list {
	    set version_list [list]
	    set version_nodes [xml_node_get_children $root_node]
	    foreach version_node $version_nodes {
		set version_node_name [xml_node_get_name $version_node]
		if {$version_node_name eq "update"} {
		    set package_name [apm_tag_value -default "" $version_node package_name]
		    set package_url [apm_tag_value -default "" $version_node package_url]
		    set po_version [apm_tag_value $version_node po_version]
		    set po_version_url [apm_tag_value $version_node po_version_url]
		    set is_new [apm_tag_value -default "" $version_node is_new]
		    set release_date [apm_tag_value -default "" $version_node release_date]
		    set whats_new [apm_tag_value -default "" $version_node whats_new]
		    set update_urgency [apm_tag_value -default "" $version_node update_urgency]
		    set download_url [apm_tag_value -default "" $version_node download_url]
		    set forum_url [apm_tag_value -default "" $version_node forum_url]
		    set forum_title [apm_tag_value -default "" $version_node forum_title]
		    set update_url [export_vars -base "/intranet-security-update-client/download-install-update" {{url $download_url}}]
		    if {"" eq $download_url} { set update_url "" }
		    set package_formatted $package_name
		    if {"" != $package_url} {set package_formatted "<a href=\"$package_url\" target=\"_parent\">$package_name</a>" }
		    set po_version_formatted $po_version
		    if {"" != $po_version_url} {set po_version_formatted "<a href=\"$po_version_url\" target=\"_parent\">$po_version</a>" }
		    # Skip this item if it's not "new"
		    if {$show_only_new_p} {
			if {$is_new != "t" } { continue }
		    }

		    set update_html "Not available"
		    if {"" ne $update_url} {
			set update_html "<a href=\"$update_url\" title=\"Update\" class=\"button\" target=\"_parent\">Update</a>"
		    }
		    append version_html "
			<tr $bgcolor([expr {$ctr % 2}])>
			  <td>$update_html &nbsp;</td>
			  <td>$package_formatted</td>
			  <td><nobr>$po_version_formatted</nobr></td>
			  <td><nobr>$release_date</nobr></td>
			  <td><a href=\"$forum_url\" target=\"_parent\">$forum_title</a></td>
                    "
		    if {$show_help_p} {
			append version_html "
			  <td>$update_urgency</td>
                          <td>$whats_new</td>
                        "
		    }
		    append version_html "
			</tr>
		    "
		    incr ctr
		}
	    }
	}
	default {
	    ns_log Notice "retreive-update-list.tcl: ignoring root node '$root_node_name'"
	}
    }
}


xml_doc_free $tree

