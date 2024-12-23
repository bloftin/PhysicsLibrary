<xsl:template match="entries">

	<xsl:call-template name="paddingtable">
		<xsl:with-param name="content">

	<xsl:call-template name="clearbox">

		<xsl:with-param name="title">All Encyclopedia Entries, Ordered by 
			<xsl:if test="@mode = 'created'">Creation</xsl:if>
			<xsl:if test="@mode = 'modified'">Last Revision</xsl:if>
		Date</xsl:with-param>

		<xsl:with-param name="content">
		
			<xsl:for-each select="entry">

				<xsl:if test="../@mode = 'created'"><xsl:value-of select="cdate"/></xsl:if>
				<xsl:if test="../@mode = 'modified'"><xsl:value-of select="mdate"/></xsl:if> - 

				<a href="{href}"><xsl:apply-templates select="title/mathytitle"/></a>
				by 
				<a href="{uhref}"><xsl:value-of select="username"/></a> 
				
				<br/>

			</xsl:for-each>
		
		</xsl:with-param>

	</xsl:call-template>  <!-- clearbox -->
	
	</xsl:with-param>
	</xsl:call-template>  <!-- paddingtable -->

</xsl:template>
