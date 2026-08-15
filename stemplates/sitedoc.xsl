<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" />
    <xsl:template match="/sitedoc">
        <html>
            
            <body>
                <div id="container">
                    
                    <div id="content">
                         <table width="0" cellpadding="0" cellspacing="4">
                            <tr> 

                                <td valign="top">
                                    <div id="right">
                                        <div class="box_padding">
                                            
                                            <div id="maincontent_box">

                                                <p>
                                                     <font size="+3">Page Under Construction!</font>
                                                </p>

                                                <p>
			                                        <font size="+1">Welcome</font> to the Physics Library Collaborative Documentation Center!  All of the documentation items here are editable by all Physics Library users, each supervised by an object owner.  All who consider themselves experienced and knowledgeable are encouraged to improve and expand upon the documentation here.
			                                    </p>
                                                
                                                <p>

			                                        <i>Note: Feel free to start new site documentation.  The steps for doing this are : (1) click on the "create new" link below and fill in the metadata and data for the initial document on the next page, (2) save the object and click "publish" for it on your "collaborations" page (3) notify the administration that you'd like to make your object a site-wide documentation object using the <a href="mailto:{//globals/feedback_email}">feedback email</a>.  Pending approval, the document will then show up on this page. </i>

			                                    </p>
                                                
                                            </div>
                                        </div>
                                        
                                    </div>
                                </td>
                            </tr>
                            <tr> 
                                <td>
                                    <div id="latest_padding">
                                        <div id="latest">
                                            <xsl:copy-of select="items/node()" />
                                        </div>
                                    </div> 
                                </td>
                            </tr>
                            <tr> 
                                
                            </tr>
                        </table>
                    </div>
                </div>
                <!-- end container -->
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
