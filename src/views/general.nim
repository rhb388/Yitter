import uri, strutils, strformat
import karax/[karaxdsl, vdom]

import renderutils
import ../utils, ../types, ../prefs, ../formatters

import jester

const
  doctype = "<!DOCTYPE html>\n"
  lp = readFile("public/lp.svg")

proc renderNavbar*(title, rss: string; req: Request): VNode =
  let twitterPath = getTwitterLink(req.path, req.params)
  var path = $(parseUri(req.path) ? filterParams(req.params))
  if "/status" in path: path.add "#m"

  buildHtml(nav):
    tdiv(class="inner-nav"):
      tdiv(class="nav-item"):
        a(class="site-name", href="/"): text title

      a(href="/"): img(class="site-logo", src="/logo.png")

      tdiv(class="nav-item right"):
        icon "search", title="Search", href="/search"
        if rss.len > 0:
          icon "rss-feed", title="RSS Feed", href=rss
        icon "bird", title="Open in Twitter", href=twitterPath
        icon "info", title="About", href="/about"
        iconReferer "cog", "/settings", path, title="Preferences"

proc renderHead*(prefs: Prefs; cfg: Config; titleText=""; desc=""; video="";
                 images: seq[string] = @[]; ogTitle=""; theme=""; rss=""): VNode =
  let ogType =
    if video.len > 0: "video"
    elif images.len > 0: "photo"
    else: "article"

  var opensearchUrl = ""
  if cfg.useHttps:
    opensearchUrl = "https://" & cfg.hostname & "/opensearch"
  else:
    opensearchUrl = "http://" & cfg.hostname & "/opensearch"

  buildHtml(head):
    link(rel="stylesheet", `type`="text/css", href="/css/style.css?v=3")
    link(rel="stylesheet", `type`="text/css", href="/css/fontello.css?v=2")
    link(rel="preload", type="text/css", href="/css/style.css?v=3", `as`="style")
    link(rel="preload", type="text/css", href="/css/fontello.css?v=2", `as`="style")
    link(rel="preload", href="/fonts/fontello.woff2?21002321", `as`="font")

    link(rel="stylesheet", type="text/css", href="/css/style.css?v=3")
    link(rel="stylesheet", type="text/css", href="/css/fontello.css?v=2")

    if theme.len > 0:
      link(rel="preload", type="text/css", href=(&"/css/themes/{theme}.css"), `as`="style")
      link(rel="stylesheet", type="text/css", href=(&"/css/themes/{theme}.css"))

    link(rel="apple-touch-icon", sizes="180x180", href="/apple-touch-icon.png")
    link(rel="icon", type="image/png", sizes="32x32", href="/favicon-32x32.png")
    link(rel="icon", type="image/png", sizes="16x16", href="/favicon-16x16.png")
    link(rel="manifest", href="/site.webmanifest")
    link(rel="mask-icon", href="/safari-pinned-tab.svg", color="#ff6c60")
@@ -55,12 +64,15 @@ proc renderHead*(prefs: Prefs; cfg: Config; titleText=""; desc=""; video="";   
    link(rel="search", type="application/opensearchdescription+xml", title=cfg.title,
                            href=opensearchUrl)

    if prefs.hlsPlayback:
      script(src="/js/hls.light.min.js", `defer`="")
      script(src="/js/hlsPlayback.js", `defer`="")

    if prefs.infiniteScroll:
      script(src="/js/infiniteScroll.js", `defer`="")

    title:
      if titleText.len > 0:
@@ -92,12 +104,7 @@ proc renderMain*(body: VNode; req: Request; cfg: Config; prefs=defaultPrefs;      
        text titleText & " | " & cfg.title
      else:
        text cfg.title

    meta(name="viewport", content="width=device-width, initial-scale=1.0")
    meta(property="og:type", content=ogType)
    meta(property="og:title", content=(if ogTitle.len > 0: ogTitle else: titleText))
    meta(property="og:description", content=stripHtml(desc))
    meta(property="og:site_name", content="Nitter")
    meta(property="og:locale", content="en_US")

    for url in images:
      meta(property="og:image", content=getPicUrl(url))
      meta(property="twitter:card", content="summary_large_image")

    if video.len > 0:
      meta(property="og:video:url", content=video)
      meta(property="og:video:secure_url", content=video)
      meta(property="og:video:type", content="text/html")

proc renderMain*(body: VNode; req: Request; cfg: Config; prefs=defaultPrefs;
                 titleText=""; desc=""; ogTitle=""; rss=""; video="";
                 images: seq[string] = @[]): string =
  var theme = toLowerAscii(prefs.theme).replace(" ", "_")
  if "theme" in req.params:
    theme = toLowerAscii(req.params["theme"]).replace(" ", "_")

  let node = buildHtml(html(lang="en")):
    renderHead(prefs, cfg, titleText, desc, video, images, ogTitle, theme, rss)

    body:
      renderNavbar(cfg.title, rss, req)

      tdiv(class="container"):
        body

  result = doctype & $node

proc renderError*(error: string): VNode =
  buildHtml(tdiv(class="panel-container")):
    tdiv(class="error-panel"):
      span: text error
