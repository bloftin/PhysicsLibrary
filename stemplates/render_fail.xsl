<xsl:template match="render_fail">

	<font size="+1" color="#ff0000">

		This entry is broken!  Please report this to the author (by <a href="{//globals/main_url}/?op=correct&amp;from=objects&amp;id={id}">filing a correction</a>).  In the meantime, you can see if another rendering mode works.

	</font>

</xsl:template>
