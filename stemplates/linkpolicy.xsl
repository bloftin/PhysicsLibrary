<xsl:template match="linkpolicy">

	<xsl:call-template name="paddingtable">
		<xsl:with-param name="content">

			<xsl:call-template name="makebox">
				<xsl:with-param name="title">Edit Linking Policy</xsl:with-param>
				<xsl:with-param name="content">

					<table width="100%" cellpadding="4"><tr><td>

					<form method="post" action="{//globals/main_url}/">

						<p>
							Linking policy for '<xsl:value-of select="@title"/>':
						</p>

						<p>
							<textarea name="policy" rows="16" cols="80"><xsl:value-of select="policy"/></textarea>
						</p>

						<input type="hidden" name="op" value="linkpolicy"/>
						<input type="hidden" name="from" value="{from}"/>
						<input type="hidden" name="id" value="{id}"/>

						<center>
							<input type="submit" name="submit" value="save"/>
						</center>

					</form>

					</td></tr></table>

				</xsl:with-param>
			</xsl:call-template>
		</xsl:with-param>
	</xsl:call-template>

</xsl:template>
