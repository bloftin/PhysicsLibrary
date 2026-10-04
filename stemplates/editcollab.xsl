<xsl:template match="editcollab">
  <style type="text/css">
.pl-collab-editor { color: #1d2935; contain: inline-size; font-family: Arial, Helvetica, sans-serif; min-width: 0; }
.pl-collab-editor a { color: #064d93; }
.pl-collab-editor .pl-modern-box-header { background: #003399; border-bottom: 1px solid #002266; box-sizing: border-box; color: #fff; margin: 0 0 .65rem; padding: .15rem .5rem; }
.pl-collab-editor h1 { color: #fff; font-size: 1rem; letter-spacing: 0; line-height: 1.2; margin: 0; overflow-wrap: anywhere; }
.pl-collab-editor-body { line-height: 1.5; min-width: 0; overflow-wrap: anywhere; padding: .25rem .5rem .75rem; }
.pl-collab-editor-body > p:first-child { margin-top: 0; }
.pl-collab-field { margin-bottom: 1rem; }
.pl-collab-field label { display: block; font-size: .9rem; font-weight: bold; margin-bottom: .35rem; }
.pl-collab-editor input[type="text"], .pl-collab-editor textarea { background: #fff; border: 1px solid #8093a5; border-radius: 2px; box-sizing: border-box; color: #17212b; font: .95rem Arial, Helvetica, sans-serif; max-width: 100%; padding: .45rem .5rem; width: 100%; }
.pl-collab-editor textarea { display: block; resize: vertical; }
.pl-collab-editor textarea[name="data"] { font-family: Consolas, "Courier New", monospace; line-height: 1.45; }
.pl-collab-actions { display: flex; flex-wrap: wrap; gap: .5rem; margin: .75rem 0; }
.pl-collab-editor input[type="submit"] { background: #1b507d; border: 1px solid #153f65; border-radius: 2px; color: #fff; cursor: pointer; font: .9rem Arial, Helvetica, sans-serif; max-width: 100%; padding: .4rem .75rem; white-space: normal; }
.pl-collab-editor input:focus-visible, .pl-collab-editor textarea:focus-visible, .pl-collab-editor a:focus-visible { outline: 2px solid #064d93; outline-offset: 2px; }
.pl-collab-feedback { background: #fff3f1; border-left: 3px solid #a00000; color: #a00000; margin: 0 0 1rem; padding: .6rem .75rem; }
.pl-collab-feedback p { margin: .25rem 0; }
.pl-collab-preview { contain: inline-size; max-width: 100%; overflow-x: auto; }
.pl-collab-editor h2 { border-bottom: 1px solid #cbd6de; font-size: 1rem; margin: 1rem 0 .5rem; padding-bottom: .35rem; }
.pl-collab-filebox { background: #f1f4f7; border: 1px solid #cbd6de; box-sizing: border-box; padding: .75rem; }
.pl-collab-filebox table { border-collapse: collapse; max-width: 100%; width: 100%; }
.pl-collab-filebox td { background: transparent; padding: 0; text-align: left; }
.pl-collab-filebox center { font-weight: bold; text-align: left; }
.pl-collab-filebox font { font-size: inherit; }
.pl-collab-filebox input[type="file"] { box-sizing: border-box; max-width: 100%; width: 100%; }
.pl-collab-filebox input[type="submit"] { white-space: nowrap; }
.pl-collab-filebox table table table td { padding-right: .65rem; vertical-align: top; }
@media (max-width: 650px) {
  .pl-collab-editor-body { padding-left: .25rem; padding-right: .25rem; }
  .pl-collab-filebox table table table tr, .pl-collab-filebox table table table td { display: block; padding-right: 0; }
  .pl-collab-filebox table table table td:first-child { margin-bottom: .5rem; }
}
  </style>
  <div class="pl-collab-editor">
    <header class="pl-modern-box-header"><h1>Editing Collaboration</h1></header>
    <div class="pl-collab-editor-body">
      <p><a href="{//globals/main_url}/?op=collab">Collaborations</a></p>
      <form method="post" action="{//globals/main_url}/" enctype="multipart/form-data" accept-charset="UTF-8">
        <xsl:choose>
          <xsl:when test="mode='update'">
            <p>Here you can enter a revision comment for your changes. We <strong>strongly recommend</strong> you do this, for the convenience of everyone involved.</p>
            <div class="pl-collab-field">
              <label for="pl-collab-revision">Revision comment</label>
              <textarea id="pl-collab-revision" name="revcomment" cols="80" rows="5"></textarea>
            </div>
            <input type="hidden" name="title" value="{title}"/>
            <input type="hidden" name="data" value="{data}"/>
            <input type="hidden" name="tempdir" value="{tempdir}"/>
            <div class="pl-collab-actions"><input type="submit" name="save" value="commit"/></div>
          </xsl:when>
          <xsl:when test="mode='preview'">
            <div class="pl-collab-actions">
              <input type="submit" name="edit" value="back to editing"/>
              <input type="submit" name="filebox" value="manage file box"/>
            </div>
            <xsl:choose>
              <xsl:when test="preview/content/node()">
                <h2>Preview of '<xsl:value-of select="title"/>'</h2>
                <div class="pl-collab-preview"><xsl:copy-of select="preview/content/node()"/></div>
              </xsl:when>
              <xsl:otherwise>
                <p class="pl-collab-feedback" role="alert">Error rendering your LaTeX! Please return to editing and check your source.</p>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="new=1"><input type="hidden" name="abstract" value="{abstract}"/></xsl:if>
            <input type="hidden" name="title" value="{title}"/>
            <input type="hidden" name="data" value="{data}"/>
            <input type="hidden" name="tempdir" value="{tempdir}"/>
            <div class="pl-collab-actions">
              <input type="submit" name="edit" value="back to editing"/>
              <input type="submit" name="filebox" value="manage file box"/>
            </div>
          </xsl:when>
          <xsl:when test="mode='filebox'">
            <div class="pl-collab-filebox"><xsl:copy-of select="fmanager"/></div>
            <xsl:if test="new=1"><input type="hidden" name="abstract" value="{abstract}"/></xsl:if>
            <input type="hidden" name="title" value="{title}"/>
            <input type="hidden" name="data" value="{data}"/>
            <div class="pl-collab-actions">
              <input type="submit" name="edit" value="back to editing"/>
              <input type="submit" name="preview" value="preview"/>
            </div>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="feedback/item">
              <div class="pl-collab-feedback" role="alert">
                <xsl:for-each select="feedback/item"><p><xsl:value-of select="."/></p></xsl:for-each>
              </div>
            </xsl:if>
            <div class="pl-collab-field">
              <label for="pl-collab-title">Title:</label>
              <input id="pl-collab-title" type="text" name="title" value="{title}" size="60"/>
            </div>
            <xsl:if test="new=1">
              <div class="pl-collab-field">
                <label for="pl-collab-abstract">Comment (abstract, etc):</label>
                <textarea id="pl-collab-abstract" name="abstract" rows="5" cols="80"><xsl:value-of select="abstract"/></textarea>
              </div>
            </xsl:if>
            <div class="pl-collab-field">
              <label for="pl-collab-data">Document (compilable LaTeX, entire file):</label>
              <textarea id="pl-collab-data" name="data" rows="25" cols="80"><xsl:value-of select="data"/></textarea>
            </div>
            <input type="hidden" name="tempdir" value="{tempdir}"/>
            <div class="pl-collab-actions">
              <input type="submit" name="preview" value="preview"/>
              <input type="submit" name="filebox" value="manage file box"/>
              <input type="submit" name="save" value="finish and save"/>
              <input type="submit" name="abort" value="abort"/>
            </div>
          </xsl:otherwise>
        </xsl:choose>
        <input type="hidden" name="op" value="edit"/>
        <input type="hidden" name="from" value="collab"/>
        <input type="hidden" name="version" value="{version}"/>
        <input type="hidden" name="id" value="{id}"/>
        <input type="hidden" name="new" value="{new}"/>
      </form>
    </div>
  </div>
</xsl:template>
