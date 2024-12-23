<xsl:template match="mainmenu">

	<table width="100%" border="0" cellpadding="4" cellspacing="0">
		<tr>
			<td>
				<center>
					<font size="-1"><i>sections</i></font>
				</center>
				
				<a href="/encyclopedia">Encyclop&#230;dia</a><br />
				<a href="{//globals/main_url}/?op=browse&amp;from=papers">Papers</a><br />
				<a href="{//globals/main_url}/?op=browse&amp;from=books">Books</a><br />
				<a href="{//globals/main_url}/?op=browse&amp;from=lec">Expositions</a><br />

				<br /> 

		
				<center>
					<font size="-1"><i>meta</i></font>
				</center>
				
				<a href="{//globals/main_url}/?op=reqlist">Requests</a> 
					<xsl:text> </xsl:text>
					<font size="-2"><xsl:value-of select="requests"/></font><br />
				<a href="{//globals/main_url}/?op=orphanage">Orphanage</a> 
					<xsl:text> </xsl:text>
					<font size="-2"><xsl:value-of select="orphans"/></font><br />
				<xsl:if test="//globals/classification_supported = 1">
					<a href="{//globals/main_url}/?op=unclassified">Unclass'd</a> 
						<xsl:text> </xsl:text>
						<font size="-2"><xsl:value-of select="unclassified"/></font><br />
				</xsl:if>

				<a href="{//globals/main_url}/?op=unproven">Unproven</a> 
					<xsl:text> </xsl:text>
					<font size="-2"><xsl:value-of select="unproven"/></font><br />
				<a href="{//globals/main_url}/?op=globalcors">Corrections</a> 
					<xsl:text> </xsl:text>
					<font size="-2"><xsl:value-of select="corrections"/></font><br />
			
				<br />
		
				<center>
					<font size="-1"><i>talkback</i></font>
				</center>
				
				<a href="{//globals/main_url}/?op=viewpolls">Polls</a><br />
				<a href="{//globals/main_url}/?op=forums">Forums</a><br />
				<a href="{//globals/main_url}/?op=feedback">Feedback</a><br />
				<a href="{//globals/bug_url}">Bug Reports</a><br />
			

				<br /> 

				<center>
					<font size="-1"><i>downloads</i></font>
				</center>

				<a href="{//globals/static_site}/snapshots/">Snapshots</a><br />
				<a href="{//globals/static_site}/newsletters/">Newsletters</a><br />
				<!-- a href="{//globals/static_site}/book/">PP Book</a><br / -->

<a href="{//globals/static_site}/stats/">Statistics</a>

<br />
				<br />
				
				<center>
					<font size="-1"><i>information</i></font>
				</center>
				
				<a href="{//globals/main_url}/?op=sitedoc">Docs</a><br />
		
				<xsl:if test="//globals/classification_supported = 1">
					<a href="{//globals/main_url}/browse/categories/">Classification</a><br />
				</xsl:if>
		
				<a href="{//globals/main_url}/?op=oldnews">News</a><br />
				<a href="{//globals/main_url}/?op=license">Legalese</a><br />
				<a href="{//globals/main_url}/?op=about">History</a><br />
				<a href="{//globals/static_site}/ChangeLog">ChangeLog</a><br />
				<a href="http://planetx.cc.vt.edu/AsteroidMeta/PlanetPhysics">TODO List</a><br />

			</td>
		</tr>
	</table>

</xsl:template>
