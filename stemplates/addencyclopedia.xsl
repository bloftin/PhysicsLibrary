<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" />
    <xsl:template match="/addencyclopedia">
        <html>
            <body>
                <div id="container">

                     This page is under construction and adding entries is disabled until site is more stable.

                     Notes and caveats for adding encyclopedia entries:

                    <p />

                    <ul>
                        <li><b>Please search for your topic before you attempt to add!</b>.  You <b>can</b> write alternate entries, if justified. </li>
                        <li>Check the requests list (or the pulldown below). Your entry may fulfill a request.</li>
                        <li>Experimental:  You can use TeX-style international trigraphs (i.e., <b>\&quot;o</b> to make <b>&#x00F6;</b>) in your entry.</li>

                    </ul>
                    
                    <hr />

                    <p/>

                    <form method="post" action="{//globals/main_url}/" enctype="multipart/form-data" accept-charset="UTF-8">

		                <font color="#ff0000" size="+1"><xsl:copy-of select="error"/></font>
		
		                Type: <xsl:copy-of select="tbox"/>

		                Title:  <xsl:element name="input">
                                    <xsl:attribute name="type">text</xsl:attribute>
                                    <xsl:attribute name="name">title</xsl:attribute>
                                    <xsl:attribute name="value"><xsl:value-of select="title"/></xsl:attribute>
                                    <xsl:attribute name="size">50</xsl:attribute>
				                </xsl:element>
	                
                        <br />

		                    <font size="-2">(Examples, corollaries, derivations, and results <b>must</b> be attached to a parent.)</font>

		                <br />

		                <br />
		
                        Contains own proof (for theorems):
                                <xsl:element name="input">
                                    <xsl:attribute name="type">checkbox</xsl:attribute>
                                    <xsl:attribute name="name">self</xsl:attribute>
                                    
                                    <xsl:if test="self='on'">
                                        <xsl:attribute name="checked">checked</xsl:attribute>
                                    </xsl:if>
                                </xsl:element>
                        <br />

                        <br />

		                Fill a request with this entry: <xsl:copy-of select="fillreq" />

   
                        Classification (See <a target="physicslibrary.popup" href="{//globals/main_url}/?op=mscbrowse">PACS (fix bad link)</a>):

                        <br />
                    
                            <xsl:element name="input">
                                <xsl:attribute name="type">text</xsl:attribute>
                                <xsl:attribute name="name">class</xsl:attribute>
                                <xsl:attribute name="value"><xsl:value-of select="class"/></xsl:attribute>
                                <xsl:attribute name="size">75</xsl:attribute>
                            </xsl:element>
                    
                        <br />

                        <font size="-2">(examples: "pacs:11F02", "pacs:11F02, pacs:11F03, pacs:05R16". "pacs:" can be ommitted, assumed by default.)</font>


		                <br /> <br />

                        <!--====================-->
                        <!-- ASSOCIATIONS TABLE -->
                        <!--====================-->

                        <table> <font face="sans-serif">

                            <tr><td colspan="2" align="center">
                                Associations (<a href="{//globals/main_url}/?op=assocguidelines">Guidelines</a>)
                            </td></tr>		

                            <tr>
                                <td>Synonyms:</td>
                                
                                <td> 
                                    <xsl:element name="input">
                                        <xsl:attribute name="type">text</xsl:attribute>
                                        <xsl:attribute name="name">synonyms</xsl:attribute>
                                        <xsl:attribute name="value"><xsl:value-of select="synonyms"/></xsl:attribute>
                                        <xsl:attribute name="size">40</xsl:attribute>
                                    </xsl:element>
                                </td>
                            </tr>

                            <tr>
                                <td>Defines:</td>
                                
                                <td> 
                                    <xsl:element name="input">
                                        <xsl:attribute name="type">text</xsl:attribute>
                                        <xsl:attribute name="name">defines</xsl:attribute>
                                        <xsl:attribute name="value"><xsl:value-of select="defines"/></xsl:attribute>
                                        <xsl:attribute name="size">40</xsl:attribute>
                                    </xsl:element>
                                </td>
                            </tr>
                            <tr>
                                <td>Related*:</td>
                                
                                <td> 
                                    <xsl:element name="input">
                                        <xsl:attribute name="type">text</xsl:attribute>
                                        <xsl:attribute name="name">related</xsl:attribute>
                                        <xsl:attribute name="value"><xsl:value-of select="related"/></xsl:attribute>
                                        <xsl:attribute name="size">40</xsl:attribute>
                                    </xsl:element>
                                </td>
                            </tr>
                            <tr>
                                <td>Keywords:</td>
                                
                                <td> 
                                    <xsl:element name="input">
                                        <xsl:attribute name="type">text</xsl:attribute>
                                        <xsl:attribute name="name">keywords</xsl:attribute>
                                        <xsl:attribute name="value"><xsl:value-of select="keywords"/></xsl:attribute>
                                        <xsl:attribute name="size">40</xsl:attribute>
                                    </xsl:element>
                                </td>
                            </tr>
                            <tr>
                            <td colspan="2" align="right">
                                * <font size="-2">Canonical names only! (I.e. "PascalsRule" instead of "Pascal's Rule")</font>.
                            </td>
                            </tr>

                        </font> </table>
                        
                        <br />
                            
                        Pronunciation:

                         
                        <xsl:element name="input">
                            <xsl:attribute name="type">text</xsl:attribute>
                            <xsl:attribute name="name">pronounce</xsl:attribute>
                            <xsl:attribute name="value"><xsl:value-of select="pronounce"/></xsl:attribute>
                            <xsl:attribute name="size">40</xsl:attribute>
                        </xsl:element>


                        <br /> <br />
                        <!--=========================-->
                        <!-- preview (if we have one -->
                        <!--=========================-->

                        <xsl:if test="preview">

                            Preview: 

                            <xsl:copy-of select="showpreview" />

                            <br /><br />

                        </xsl:if>
                               
                        Preamble (new commands, nonstandard packages):

                        <br />

                        <table width="0" cellpadding="0" cellspacing="4">
                        <tr> 
                            <td>
                                <textarea name="preamble" cols="60" rows="8"><xsl:value-of select="preamble"/></textarea>
                            </td>

                            <td valign="top">
                                <input type="submit" name="getpre" value="get preamble" />
                            </td>
                        </tr>
                        </table>

                        <br />

                        Content (edit your LaTeX here. See <a href="{//globals/main_url}/?op=getobj&amp;from=collab&amp;id=28">PhysicsLibrary Content and Style Guide</a>
                            , or <a href="http://aux.physicslibrary.org/doc/faq.html#r_tex" target="syntax_win">Syntax Help</a>
                        ):

                        <br />
                        <table width="0" cellpadding="0" cellspacing="4">
                            <tr>
                                <td>
                                    <textarea name="data" cols="80" rows="20"><xsl:value-of select="data"/></textarea>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <input TYPE="submit" name="preview" VALUE="preview" /> 
                                    <input type="hidden" name="id" value="{id}"/>
                                    <input type="hidden" name="op" value="{op}"/>
                                    <input type="hidden" name="version" value="0"/>
                                    <input type="hidden" name="table" value="objects"/>
                                    <input type="hidden" name="from" value="objects"/>

                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <xsl:if test="preview">
                                        <input TYPE="submit" name="post" VALUE="save changes" />
                                    </xsl:if>
                                </td>
                            </tr>
                            
                        </table>
                        
                    <!--=====================-->
                    <!-- corrections manager -->
                    <!--=====================-->

                    <xsl:if test="corrections">
                    
                        <xsl:copy-of select="corrections"/>

                    </xsl:if>

                    <!--==============-->
                    <!-- file manager -->
                    <!--==============-->

                    <xsl:if test="fmanager">
                    
                        <xsl:copy-of select="fmanager"/>

                    </xsl:if>


	                </form>

                </div>
                <!-- end container -->
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
