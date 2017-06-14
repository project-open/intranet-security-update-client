# /packages/intranet-security-update-client/www/connect-to-asus.tcl
#
# Copyright (C) 2004 ]project-open[
# The code is based on ArsDigita ACS 3.4
#

ad_page_contract {
    Determine the email account on ]po[ set for this system
    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/admin/backup/index" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [auth::require_login]

set page_title [lang::message::lookup "" intranet-security-update-client.Connect_to_ASUS "Connect to ASUS"]
set context_bar [im_context_bar $page_title]
set context ""



# ------------------------------------------------------
# Connect to server and check if there is a user_id for system_id
# ------------------------------------------------------
 
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

# ad_return_complaint 1 "<pre>[ns_quotehtml $update_xml]</pre>"

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

# ------------------------------------------------------
# Format user-friendly page
# ------------------------------------------------------




