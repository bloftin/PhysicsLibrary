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
                        <div id="left">
                            <xsl:copy-of select="login/node()" />
                            <xsl:copy-of select="logos/node()" />
                        </div>
                        <div id="right">
                            <div class="box_padding">
                                <div class="gcse-searchresults-only"></div>
                                <div id="maincontent_box">

                                <!-- about pl -->

                                <p> Physics Library is a virtual community which aims to help make physics knowledge more accessible.  Physics Library's content is created collaboratively: the main feature is the <a href="/encyclopedia">physics encyclopedia</a> with entries written and reviewed by members.   The entries are contributed under the terms of the <a href="https://creativecommons.org/licenses/by-sa/4.0/"> Creative Commons Attribution-ShareAlike CC BY-SA 4.0 License </a>.</p>  
                
                                <p> Physics Library entries are written in <a href="https://www.latex-project.org/">LaTeX</a>, the <i>lingua franca</i> of the worldwide mathematics community.  All of the entries are automatically cross-referenced with each other, and the entire corpus is kept updated in real-time. </p>

                                    
                            </div>
                        </div>
                        <div id="go_to_padding">
                            <div id="go_to">
                                Browse Encyclopedia By: <a href="/browse/objects/">Subject</a> | <a href="/?op=enlist;mode=hits">Popularity</a> | <a href="/encyclopedia/">More</a>
                            </div>
                        </div>
                        <div id="latest_padding">
                            <div id="latest">
                                <xsl:copy-of select="latestadditions/node()" />
                            </div>
                        </div>
                        <div id="author_padding">
                            <div id="authors">
                                <xsl:copy-of select="topusers/node()" />
                            </div>
                        </div>
                        </div>
                    </div>
                </div>
                <!-- end container -->
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
