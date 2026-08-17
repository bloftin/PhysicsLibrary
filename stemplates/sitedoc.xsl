<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" />

    <xsl:template match="/sitedoc">
        <html>
            <body>
                <table width="100%" cellpadding="0" cellspacing="4">
                    <tr>
                        <td valign="top">
                            <div class="box_padding">
                                <div id="maincontent_box">
                                    <h1>PhysicsLibrary Documentation</h1>

                                    <p>
                                        Welcome to the PhysicsLibrary documentation center. These guides collect
                                        practical notes for writing, editing, formatting, classifying, and maintaining
                                        PhysicsLibrary content.
                                    </p>

                                    <p>
                                        Most documentation pages are collaborative objects. They can be improved by
                                        PhysicsLibrary users and then published here as site documentation.
                                    </p>
                                </div>
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td valign="top">
                            <xsl:call-template name="doc-section">
                                <xsl:with-param name="title">Key Documents</xsl:with-param>
                                <xsl:with-param name="content">
                                    <dl>
                                        <dt>
                                            <a href="/?op=getobj&amp;from=papers&amp;id=142">
                                                Aaron Krowne's PlanetMath / Noosphere thesis
                                            </a>
                                        </dt>
                                        <dd>
                                            Historical background on the original collaborative system that
                                            PhysicsLibrary descends from. The current site has changed substantially,
                                            but the thesis is still useful context for the design philosophy.
                                        </dd>
                                    </dl>
                                </xsl:with-param>
                            </xsl:call-template>
                        </td>
                    </tr>

                    <tr>
                        <td valign="top">
                            <xsl:call-template name="doc-section">
                                <xsl:with-param name="title">Recommended Guide Topics</xsl:with-param>
                                <xsl:with-param name="content">
                                    <p>
                                        These are good candidates for collaborative site documentation entries:
                                    </p>

                                    <ul>
                                        <li>
                                            <b>PhysicsLibrary Style Guide</b> - voice, article structure,
                                            definitions, examples, references, and common editing conventions.
                                        </li>
                                        <li>
                                            <b>Adding Images and Figures</b> - recommended LaTeX image patterns,
                                            captions, file uploads, and renderer-friendly sizing.
                                        </li>
                                        <li>
                                            <b>Tables and Formatting</b> - examples for bordered tables, aligned
                                            equations, lists, theorem text, and references.
                                        </li>
                                        <li>
                                            <b>PACS Classification Guide</b> - how to choose PACS categories and
                                            when broad classifications are appropriate.
                                        </li>
                                        <li>
                                            <b>Renderer Compatibility Notes</b> - what works best across HTML with
                                            images, page images, PDF, TeX source, and make4ht.
                                        </li>
                                    </ul>
                                </xsl:with-param>
                            </xsl:call-template>
                        </td>
                    </tr>

                    <tr>
                        <td valign="top">
                            <xsl:call-template name="doc-section">
                                <xsl:with-param name="title">Image Template</xsl:with-param>
                                <xsl:with-param name="content">
                                    <p>
                                        For PNG and JPG figures, prefer explicit width instead of bare image includes:
                                    </p>

                                    <pre>\begin{center}
\includegraphics[width=0.85\textwidth,keepaspectratio]{your-image.png}

{\small Figure 1. Short plain-text caption.}
\end{center}</pre>

                                    <p>
                                        Avoid TeX math in captions when possible. Plain-text captions behave better
                                        in older renderers.
                                    </p>
                                </xsl:with-param>
                            </xsl:call-template>
                        </td>
                    </tr>

                    <tr>
                        <td valign="top">
                            <xsl:call-template name="doc-section">
                                <xsl:with-param name="title">Site Documentation Entries</xsl:with-param>
                                <xsl:with-param name="content">
                                    <xsl:choose>
                                        <xsl:when test="items/docitem">
                                            <dl>
                                                <xsl:for-each select="items/docitem">
                                                    <dt>
                                                        <font size="+1">
                                                            <a href="/?op=getobj&amp;from=collab&amp;id={uid}">
                                                                <xsl:value-of select="title"/>
                                                            </a>
                                                        </font>
                                                    </dt>
                                                    <dd>
                                                        <xsl:choose>
                                                            <xsl:when test="abstract">
                                                                <xsl:value-of select="abstract"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <i>No description given.</i>
                                                            </xsl:otherwise>
                                                        </xsl:choose>

                                                        <xsl:if test="lastedit">
                                                            <br />
                                                            <i>
                                                                Last edit: <xsl:value-of select="lastedit/when"/>
                                                                by <xsl:value-of select="lastedit/who"/>
                                                            </i>
                                                        </xsl:if>
                                                    </dd>
                                                </xsl:for-each>
                                            </dl>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <p>
                                                No collaborative documentation entries have been published yet.
                                            </p>
                                        </xsl:otherwise>
                                    </xsl:choose>

                                    <p>
                                        To propose a new documentation page, create a
                                        <a href="/?op=edit&amp;from=collab&amp;new=1">
                                            new collaboration
                                        </a>,
                                        publish it, and ask an administrator to mark it as site documentation.
                                    </p>
                                </xsl:with-param>
                            </xsl:call-template>
                        </td>
                    </tr>
                </table>
            </body>
        </html>
    </xsl:template>

    <xsl:template name="doc-section">
        <xsl:param name="title" />
        <xsl:param name="content" />

        <table width="100%" cellpadding="0" cellspacing="0">
            <tr>
                <td bgcolor="#003399">
                    <font color="#ffffff">
                        <b><xsl:value-of select="$title"/></b>
                    </font>
                </td>
            </tr>
            <tr>
                <td>
                    <xsl:copy-of select="$content" />
                </td>
            </tr>
        </table>
        <br />
    </xsl:template>
</xsl:stylesheet>
