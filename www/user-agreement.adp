<master>
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin</property>


<table width="70%">
<tr>
<td>

<h1>@page_title;noquote@</h1>


<p>
Before you can use the @po;noquote@ ASUS
(Automatic Security Update Service) you need to agree 
to the following terms and conditions of this service.
</p>

<br>
<h2>The Automatic Software Update Service</h2>

<p>
The ASUS service checks your system for known security flaws
and bugs. As a result of this check, ASUS will display a
message with the status of the system and possibly update 
recomendations.
</p>

<br>
<h2>Data Collection</h2>
<p>
In order to check your system we need to collect data from 
your installation. 
This information includes the version of your @po;noquote@ 
packages, your operating system and your PostgreSQL database.
Also, we will generate an anonymous unique ID for your hardware 
and your @po;noquote@ installation and transmit the number of
users in your system in order to maintain statistics about
the product.
Collecting your email address will allow us to alert you 
in case of critical security threads.
</p>


<br>
<h2>Limitation of Data Collection</h2>
<p>
You can also choose to limit the collected data to anonymous
system information only. In this case please select 
'Limit ASUS to anonymous data' below.
</p>



<br>
<h2>Disable ASUS</h2>
<p>
You can also decide to disable ASUS completely. In order to do
so please go now to Admin (at the left navigation bar) -&gt; 
Portlet Components, click on "Security Update Client Component",
and set the component to "Not Enabled".
</p>



<br>
<h2>Warranty and Disclaimer</h2>
<p>
@po;noquote@ makes no representations or warrenties regarding the accuracy or completeness
of the information provided by ASUS. @po;noquote@ disclaims all warranties in connection
with the ASUS, and will not be liable for any damage of loss resulting from your use
of the service or the product.

</td>
</tr>
<tr>
<td>

<br>

<form action=update-preferences>
<input type=radio name=verbosity value=1 checked>Enable full Automatic Security Update Service (ASUS)<br>
<input type=radio name=verbosity value=0>Limit ASUS to anonymous data<br>
<br>
<input type=submit value="Enable ASUS">
</form>

</td>
</tr>
</table>

