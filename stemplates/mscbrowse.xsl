<xsl:template match="mscset">
    <xsl:call-template name="clearbox">
        <xsl:with-param name="title">
		 	<xsl:choose>
				<xsl:when test="tdesc">
					<xsl:value-of select="tdesc"/> by subject
				</xsl:when>
				<xsl:otherwise>
					Browsing PACS
				</xsl:otherwise>
			</xsl:choose>
		</xsl:with-param>
        <xsl:with-param name="content">

			<!-- search box if we are browsing categories only -->

			<xsl:if test="not(tdesc)"> 
				<table align="center" border="0"><td>
				<form method="get">
					<xsl:attribute name="action"><xsl:value-of select="//globals/main_url"/>/</xsl:attribute>
				<input type="hidden" name="op" value="mscsearch"/>
				<input type="text" name="mscterm" value=""/>
				<input type="submit" value="search"/>
				<input type="checkbox" name="leaves" checked="1" /> leaves only
				<br />
				<font size="-2">(Case insensitive substrings, use '-' to exclude)</font>
				</form>
				</td></table>
			</xsl:if>
			
            <p>

			<!-- print header -->

            <font size="+1">
            <xsl:choose>
                <xsl:when test="parent">
                    <xsl:value-of select="parent/id"/> - <xsl:value-of select="parent/desc"/>
                </xsl:when>
                <xsl:otherwise>Top Level Categories</xsl:otherwise>
            </xsl:choose>
         </font>
            </p>

			<!-- browse content pane -->

            <table border="0" width="100%">

				<!-- display MSC node content -->

                <xsl:if test="mscnode">
                    <xsl:for-each select="mscnode">
                        <tr valign="top">
                            <xsl:apply-templates select="."/>
                        </tr>
                    </xsl:for-each>

                </xsl:if>

				<!-- display MSC leaf content -->

                <xsl:if test="mscleaf">
                    <tr>
                        <td>
                            <ol>
                                <xsl:for-each select="mscleaf">
                                    <li><xsl:apply-templates select="."/></li>
                                </xsl:for-each>
                            </ol>
                        </td>
                    </tr>
					
                </xsl:if>

				<!-- navigation buttons -->
				
				<tr>
					<td align="center" colspan="6">
						[ 
							
							<xsl:if test="parent">
								
								<a>
									<xsl:attribute name="href"><xsl:value-of select="parent/@href"/></xsl:attribute>up</a>
										
									|
                   			</xsl:if>
									
							<a>

                				<xsl:if test="mscleaf">
									<xsl:attribute name="href">/browse/<xsl:value-of select="mscleaf[1]/domain"/>/</xsl:attribute>top</xsl:if>

                				<xsl:if test="mscnode">
									<xsl:attribute name="href">/browse/<xsl:value-of select="mscnode[1]/domain"/>/</xsl:attribute>top</xsl:if>

							</a>
								
						] 
					</td>
				</tr>

            </table>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!--============== -->
<!-- node template -->
<!--============== -->

<xsl:template match="mscnode">
    <td>
        <font face="monospace" size="+1">
			<xsl:choose>
			<xsl:when test="haschild or count > 0">
            	<a>
            	    <xsl:attribute name="href">/browse/<xsl:value-of select="domain"/>/<xsl:value-of select="id"/>/</xsl:attribute>
						
                	<xsl:value-of select="id"/>
            	</a>
			</xsl:when>
			<xsl:otherwise>
				<b><xsl:value-of select="id"/></b>
			</xsl:otherwise>
			</xsl:choose>
			
        </font>
    </td>
    <td>-</td>
    <td>
        <xsl:value-of select="comment"/>
    </td>
	<xsl:if test="count">
   		<td>-</td>
    	<td align="right">
        <xsl:value-of select="count"/>
    	</td>
    	<td>
        	item<xsl:if test="count &gt; 1">s</xsl:if>
    	</td>
	</xsl:if>
</xsl:template>

<!--============== -->
<!-- leaf template -->
<!--============== -->

<xsl:template match="mscleaf">
    <a>
        <xsl:attribute name="href">
            /?op=getobj&amp;from=<xsl:value-of select="domain"/>&amp;id=<xsl:value-of select="id"/>
        </xsl:attribute>
		<xsl:apply-templates select="title/mathytitle"/>
    </a>
    <font size="-1"> owned by
    <a>
        <xsl:attribute name="href"><xsl:value-of select="owner/@href"/></xsl:attribute>
        <xsl:value-of select="owner"/>
    </a>
    </font>
</xsl:template>

