# Embedded YouTube Videos

To embed a YouTube video in an article, place this command in the article body:

```tex
\PMyoutube{VIDEO_URL_OR_ID}{Short descriptive caption}
```

For example:

```tex
\PMyoutube{https://youtu.be/dQw4w9WgXcQ}{A short demonstration of the experiment.}
```

Supported video sources are a bare eleven-character YouTube ID, a `youtu.be`
short URL, or a `youtube.com` watch, embed, or shorts URL. The HTML renderer
uses YouTube's privacy-enhanced player with lazy loading. PDF, PNG, legacy
HTML, and source views use the caption as a normal YouTube link instead.

Do not paste an iframe or other HTML into article source. Sources from other
hosts are intentionally rejected by the renderer.
