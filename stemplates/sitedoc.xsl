<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" omit-xml-declaration="yes" />
    <xsl:template match="/sitedoc">
        <div class="pl-site-doc-body">
            <p>Welcome to the PhysicsLibrary documentation center. These guides collect practical notes for writing, editing, formatting, classifying, and maintaining PhysicsLibrary content.</p>
            <p>Most documentation pages are collaborative objects. They can be improved by PhysicsLibrary users and then published here as site documentation.</p>

            <section>
                <h2>Key Documents</h2>
                <dl>
                    <dt><a href="/?op=sitedoc;guide=newuser">PhysicsLibrary New User Guide</a></dt>
                    <dd>Getting started with encyclopedia contributions, alternate entries, metadata, LaTeX previews, file uploads, and references.</dd>
                    <dt><a href="/?op=getobj&amp;from=papers&amp;id=142">Aaron Krowne's PlanetMath / Noosphere thesis</a></dt>
                    <dd>Historical background on the original collaborative system that PhysicsLibrary descends from. The current site has changed substantially, but the thesis is still useful context for the design philosophy.</dd>
                </dl>
            </section>

            <section>
                <h2>Recommended Guide Topics</h2>
                <p>These are good candidates for collaborative site documentation entries:</p>
                <ul>
                    <li><b>PhysicsLibrary Style Guide</b> - voice, article structure, definitions, examples, references, and common editing conventions.</li>
                    <li><b>Adding Images and Figures</b> - recommended LaTeX image patterns, captions, file uploads, and renderer-friendly sizing.</li>
                    <li><b>Tables and Formatting</b> - examples for bordered tables, aligned equations, lists, theorem text, and references.</li>
                    <li><b>PACS Classification Guide</b> - how to choose PACS categories and when broad classifications are appropriate.</li>
                    <li><b>Renderer Compatibility Notes</b> - what works best across HTML with images, page images, PDF, TeX source, and make4ht.</li>
                </ul>
            </section>

            <section>
                <h2>Image Template</h2>
                <p>For PNG and JPG figures, prefer explicit width instead of bare image includes:</p>
                <pre>\begin{center}
\includegraphics[width=0.85\textwidth,keepaspectratio]{your-image.png}

{\small Figure 1. Short plain-text caption.}
\end{center}</pre>
                <p>Avoid TeX math in captions when possible. Plain-text captions behave better in older renderers.</p>
            </section>

            <section>
                <h2>Video Template</h2>
                <p>Currently only youtube embedded video links are allowed on PhysicsLibrary. You use the manual link contol sequence of \PMyoutube{https://youtu.be/VIDEO_ID}{A short description of the video.} A typical example:</p>
                <pre>\PMyoutube{https://youtu.be/6oGjAlrHjtE}{Companion video for the inertia-tensor similarity-transformation derivation.}</pre>
            </section>

            <section>
                <h2>Site Documentation Entries</h2>
                <xsl:choose>
                    <xsl:when test="items/docitem">
                        <dl class="pl-site-doc-entries">
                            <xsl:for-each select="items/docitem">
                                <dt><a href="/?op=getobj&amp;from=collab&amp;id={uid}"><xsl:value-of select="title"/></a></dt>
                                <dd>
                                    <xsl:choose>
                                        <xsl:when test="abstract"><xsl:value-of select="abstract"/></xsl:when>
                                        <xsl:otherwise><i>No description given.</i></xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:if test="lastedit">
                                        <div class="pl-site-doc-edit">Last edit: <xsl:value-of select="lastedit/when"/> by <xsl:value-of select="lastedit/who"/></div>
                                    </xsl:if>
                                </dd>
                            </xsl:for-each>
                        </dl>
                    </xsl:when>
                    <xsl:otherwise><p>No collaborative documentation entries have been published yet.</p></xsl:otherwise>
                </xsl:choose>
                <p>To propose a new documentation page, create a <a href="/?op=edit&amp;from=collab&amp;new=1">new collaboration</a>, publish it, and ask an administrator to mark it as site documentation.</p>
            </section>
        </div>
    </xsl:template>
</xsl:stylesheet>
