<xsl:template match="frontpage">

	<!-- box for news, PlanetPhysics "about" blurb -->

	<xsl:call-template name="clearbox">
		<xsl:with-param name="title">Welcome!</xsl:with-param>
		<xsl:with-param name="content">

			<table width="100%">
			<tr><td>
				<table width="100%" cellpadding="0" cellspacing="3">
					<tr><td valign="top"> 
<div id="cse-search-results"></div>
<script type="text/javascript">
  var googleSearchIframeName = "cse-search-results";
  var googleSearchFormName = "cse-search-box";
  var googleSearchFrameWidth = 600;
  var googleSearchDomain = "www.google.com";
  var googleSearchPath = "/cse";
</script>
<script type="text/javascript" src="http://www.google.com/afsonline/show_afs_search.js"></script>
					
						<!-- floating news table -->
						
						<table bgcolor="#d8d8d8" width="30%" align="right">
							<tr><td align="center">
							
							<font size="-2">News</font>
							
							</td></tr> 
							
							<tr><td> 
							
								<font size="-2"> 
								
									<xsl:for-each select="news/item">
										<p class="newstitle">
										<xsl:choose>
											<xsl:when test="position()=1">
												<b><a href="{href}"><xsl:value-of select="title"/></a></b> on 
											</xsl:when>
											<xsl:otherwise>
												<a href="{href}"><xsl:value-of select="title"/></a> on 
											</xsl:otherwise>
										</xsl:choose>
										<xsl:value-of select="date"/>
										</p> 

									</xsl:for-each>
									
           						</font> 
								
								<font size="-2"> 
								
									<div align="right"> 
									<a href="{//globals/main_url}/?op=oldnews">more...</a>&nbsp; 
									</div> 
								</font>
							</td></tr>
						</table>

   						<!-- about pm -->

						PlanetPhysics is a virtual community which aims to help make physics knowledge more accessible.  PlanetPhysics's content is created collaboratively: the main feature is the <a href="/encyclopedia">physics encyclopedia</a> with entries written and reviewed by members.   The entries are contributed under the terms of the <a href="{//globals/main_url}/?op=license">GNU Free Documentation License</a> (FDL) in order to preserve the rights of both the authors and readers in a sensible way.


						<p>
						
						PlanetPhysics entries are written in <a href="http://www.latex-project.org/">LaTeX</a>, the <i>lingua franca</i> of the worldwide mathematics community.  All of the entries are automatically cross-referenced with each other, and the entire corpus is kept updated in real-time.

						</p>	
   
						<p> 
						
						In addition to the physics encyclopedia, there are <a href="{//globals/main_url}/?op=browse&amp;from=books">books</a>, <a href="{//globals/main_url}/?op=browse&amp;from=lec">expositions</a>, <a href="{//globals/main_url}/?op=browse&amp;from=papers">papers</a>, and <a href="{//globals/main_url}/?op=forums">forums</a>.  You also might want to check out encyclopedia <a href="{//globals/main_url}/?op=reqlist">requests</a> if you'd like to see something we don't have.  
						</p>
						
						<p>
						
						Accounts are free and required to do anything other than browse, so <a href="{//globals/main_url}/?op=newuser">sign up</a>! It only takes a minute.

						For more information, see the <a href="http://www.planetmath.org/?op=getobj&amp;from=collab&amp;id=35">FAQ</a>, other <a href="{//globals/main_url}/?op=sitedoc">documentation</a>, or <a href="http://scholar.lib.vt.edu/theses/available/etd-09022003-150851/">``the PlanetMath thesis''</a>.  
						</p>
						
						<p>
						PlanetPhysics runs <a href="http://aux.planetmath.org/noosphere">Noosphere</a>.

						</p>

		
					</td></tr>
				</table> 
				
			</td></tr>
			</table> 
		</xsl:with-param>
	</xsl:call-template>

	<!-- messages -->

	<xsl:call-template name="clearbox">

		<xsl:with-param name="title">Latest Messages</xsl:with-param>

		<xsl:with-param name="content">
		
			<xsl:for-each select="messages/message">

				<xsl:value-of select="date"/> - 

				<a href="{ohref}" title="go to the parent object or forum containing this message"><img alt="parent" src="{//globals/image_url}/object.png" border="0"/></a>
				<xsl:text> </xsl:text>

				<xsl:if test="href != thref">
					<a href="{thref}" title="go to the top of the thread containing this message"><img alt="thread top" src="{//globals/image_url}/uparrow.png" border="0"/></a>
					<xsl:text> </xsl:text>
				</xsl:if>

				<a href="{href}"><xsl:value-of select="title"/></a> 
				by 
				<a href="{uhref}"><xsl:value-of select="username"/></a> 
				
				<br/>

			</xsl:for-each>

			<p/> 

			<center>
				<a href="{//globals/main_url}/?op=messageschrono">(see more)</a>
			</center>

		</xsl:with-param>

	</xsl:call-template>

</xsl:template>
