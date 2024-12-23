<xsl:template match="sitedoc">

 <xsl:call-template name="paddingtable">
  <xsl:with-param name="content">
   
  <xsl:call-template name="clearbox">
    <xsl:with-param name="title">PlanetPhysics Collaborative Documentation</xsl:with-param>
	<xsl:with-param name="content">
		<font size="+1">Welcome</font> to the PlanetPhysics Collaborative Documentation Center!  Until the Documentation Center is ready please refer to <a href="http://planetmath.org/?op=sitedoc">PlanetMath docuemtation</a> since there is a lot of related information.
<p/>    

  <xsl:for-each select="item">
	    <xsl:apply-templates select="."/>
      </xsl:for-each>

    </xsl:with-param>

  </xsl:call-template>

  </xsl:with-param>
  
 </xsl:call-template>

</xsl:template>

<xsl:template match="item">

  <xsl:value-of select="series/@ord"/>.
  
  <a>
    <xsl:attribute name="href"> 
	 <xsl:value-of select="object/@href"/>
	</xsl:attribute>

	 <!--<xsl:value-of select="object/@title"/>-->
     <xsl:apply-templates select="title/mathytitle"/>
  </a>	
  
	contributed by 
	
  <a>
    <xsl:attribute name="href">  
	 <xsl:value-of select="user/@href"/>
	</xsl:attribute>

	<xsl:value-of select="user/@name"/>
  </a>
  
  <br/>

</xsl:template>
