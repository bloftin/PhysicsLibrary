<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" />
    <xsl:template match="/mainpage">
        <html>
            <head>
                <xsl:copy-of select="head/node()" />
            </head>
            <body>
                <div id="container">
                    <xsl:copy-of select="header/node()" />
                    <div id="content">
                         <table width="0" cellpadding="0" cellspacing="4">
                            <tr> 
                                <td>
                                    <div id="left">
                                        <xsl:copy-of select="login/node()" />
                                        <xsl:copy-of select="logos/node()" />
                                        <xsl:copy-of select="mainmenu/node()" />
                                    </div>
                                </td>

                                <td valign="top">
                                    <div id="right">
                                        <div class="gcse-searchresults-only"></div>
                                        <div class="box_padding">
                                            
                                            <div id="maincontent_box">

                                                <!-- about pl -->

                                                <p> Physics Library is a virtual community which aims to help make physics knowledge more accessible.  Physics Library's content is created collaboratively: the main feature is the <a href="/encyclopedia">physics encyclopedia</a> with entries written and reviewed by members.   The entries are contributed under the terms of the <a href="https://creativecommons.org/licenses/by-sa/4.0/"> Creative Commons Attribution-ShareAlike CC BY-SA 4.0 License </a>.</p>  
                                
                                                <p> Physics Library entries are written in <a href="https://www.latex-project.org/">LaTeX</a>, the <i>lingua franca</i> of the worldwide mathematics community.  All of the entries are automatically cross-referenced with each other, and the entire corpus is kept updated in real-time. </p>

                                                
                                            </div>
                                        </div>
                                        <div id="go_to_padding">
                                            <div id="go_to">
                                                Browse Encyclopedia By: <a href="/encyclopedia/">Encyclopedia</a>
                                            </div>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                            <tr> 
                                <td>
                                    <div id="latest_padding">
                                        <div id="latest">
                                            <xsl:copy-of select="latestadditions/node()" />
                                        </div>
                                    </div>
                                </td>
                            </tr>
                            <tr> 
                                <div id="author_padding">
                                    <div id="authors">
                                        <xsl:copy-of select="topusers/node()" />
                                    </div>
                                </div>
                            </tr>
                        </table>
                    </div>
                </div>
                <!-- end container -->
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
