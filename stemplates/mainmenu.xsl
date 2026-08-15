<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output omit-xml-declaration="yes"/>
<xsl:template match="/mainmenu">

<center>
    <font size="-1"><i>Sections</i></font>
</center>

<ul> 
<li><a href="/encyclopedia">Encyclopedia</a></li>
<li><a href="/?op=browse;from=papers">Papers</a></li>
</ul>
 
<center>
    <font size="-1"><i>talkback</i></font>
</center>

<ul> 
<li><a href="/?op=viewpolls">Polls</a><br /></li>
<li><a href="/?op=forums">Forums</a><br /></li>
<li><a href="https://github.com/bloftin/PhysicsLibrary/issues">Bug Reports</a><br /></li>
</ul>

<center>
    <font size="-1"><i>Information</i></font>
</center>

<ul>				
<li><a href="/?op=license">Legalese</a></li>
<li><a href="/?op=about">About</a></li>
</ul>

</xsl:template>
</xsl:stylesheet>
