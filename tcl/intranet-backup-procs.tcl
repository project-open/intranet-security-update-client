# /intranet-security-update-client/tcl/intranet-backup-procs.tcl
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
# Check backup files on Projop for the given system_id
# ------------------------------------------------------------


ad_proc im_security_update_backup_component { 
} {
    Retreive the list of backup files on Projop and generate
    a list of these files.
} {

    # fraber 151209 - disabled
    return ""

    set system_id [im_system_id]
    set service_base_url "http://www.project-open.net/intranet-asus-server/backup-files.xml"
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
    
    # Sample record:
    #
    #<asus_reply>
    #<error>ok</error>
    #<error_message>Success</error_message>
    #<file size="23456">pg_dump.asdf.wetr.2013-01-01.120000.sql</file>
    #</asus_reply>
    
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

    # login_status = "ok" or "fail"
    set login_status [[$root_node selectNodes {//error}] text]
    set login_message [[$root_node selectNodes {//error_message}] text]
    append html "<ul>"
    append html "<li>ASUS Login Status: $login_status"
    append html "<li>ASUS Login Message: $login_message"
    append html "</ul>"

    template::multirow create backup_files_sec_update filename file_body extension date size

    foreach root_node $root_nodes {
	
	set root_node_name [xml_node_get_name $root_node]
	ns_log Notice "im_security_update_backup_component: node_name=$root_node_name"
	
	switch $root_node_name {
	    file {
		#<file size="23456">pg_dump.asdf.wetr.2013-01-01.120000.sql</file>
		set file_size [apm_attribute_value -default "" $root_node size]
		set file_date [apm_attribute_value -default "" $root_node date]
		set file_name [xml_node_get_content $root_node]
		set file_extension ""
		template::multirow append backup_files_sec_update \
		    $file_name \
		    $file_name \
		    $file_extension \
		    $file_date \
		    $file_size
	    }
	    default {
		# ignore all other tags except for "file"...
		ns_log Notice "im_security_update_backup_component: ignoring root node '$root_node_name'"
	    }
	}
    }
    
    set actions [list \
		     [lang::message::lookup "" intranet-core.ASUS_Upload_latest_backup_dump "Upload Latest Backup Dump"] \
		     [export_vars -base upload-latest-dump] \
		     [lang::message::lookup "" intranet-core.ASUS_Upload_latest_backup_dump_msg "Upload the most recent backup dump to www.project-open.net"] \
    ]
    
    set bulk_actions [list \
			  [lang::message::lookup "" intranet-core.Backup_Delete "Delete"] \
			  "delete-pgdump" \
			  [lang::message::lookup "" intranet-core.Backup_Delete_checked_backup_dumps "Remove checked backup dumps"] \
    ]


    template::list::create \
	-name backup_files_sec_update \
	-key filename \
	-elements [list \
		       file_body [list \
				      label [lang::message::lookup "" intranet-core.Backup_File_Name "File Name"] \
				     ] \
		       extension [list \
				      label [lang::message::lookup "" intranet-core.Backup_Type "Type"] \
				     ] \
		       date [list \
				 label [lang::message::lookup "" intranet-core.Backup_Date "Date"] \
				] \
		       size [list \
				 label [lang::message::lookup "" intranet-core.Backup_Size "Size"] \
				 html { align right } \
				] \
		      ] \
	-bulk_actions $bulk_actions \
	-bulk_action_method post \
	-bulk_action_export_vars { return_url } \
	-actions $actions

    # Compile and execute the listtemplate
    eval [template::adp_compile -string {<listtemplate name="backup_files_sec_update"></listtemplate>}]
    set form_html $__adp_output
    append html $form_html

    xml_doc_free $tree
    set saas_url "http://www.project-open.com/en/services/project-open-hosting-saas.html"
    return "
<table class=backup_table>
<tr>
<td width=600>
$html
</td>
<td width=250>
	<h3>ASUS Backup</h3>
	This portlet allows you to copy your local backups to a remote \]project-open\[ server.
	A remote copy allows \]po\[ to provide you with a <a href='$saas_url'>SaaS server</a>
	within short notice in case your \]po\[ server should fail.
	<ul>
	<li><b>Upload Latest Backup Dump</b>: Selects the latest backup dump and transfers the dump to the \]po\[ server.
	</ul>
	<ul>
	<li><b>Delete</b>: Delete one or more selected backup dumps.
	</ul>
</td>
</tr>
</table>
"

}

