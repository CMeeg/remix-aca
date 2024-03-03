export function useRedirect(app) {
  const baseUrl = process.env.BASE_URL
  let baseHostname = ""
  let baseProtocol = ""

  if (baseUrl) {
    const url = new URL(baseUrl)
    baseHostname = url.hostname
    baseProtocol = url.protocol.replace(":", "")
  }

  if (baseHostname) {
    // Redirect to the canonical hostname
    app.use((req, res, next) => {
      // The `x-azure-ref` is set when the requst comes from the CDN
      // https://learn.microsoft.com/en-us/azure/frontdoor/front-door-http-headers-protocol#from-the-front-door-to-the-backend
      if (req.hostname !== baseHostname && !req.headers["x-azure-ref"]) {
        res.redirect(308, `${baseProtocol}://${baseHostname}${req.originalUrl}`)
        return
      }

      next()
    })
  }

  if (baseProtocol === "https") {
    // Ensure HTTPS only
    app.use((req, res, next) => {
      if (req.protocol === "http") {
        res.redirect(`https://${req.hostname}${req.originalUrl}`)
        return
      }

      next()
    })
  }

  // No trailing slashes on GET requests
  app.get("*", (req, res, next) => {
    if (req.path.endsWith("/") && req.path.length > 1) {
      const query = req.url.slice(req.path.length)
      const safepath = req.path.slice(0, -1).replace(/\/+/g, "/")

      res.redirect(301, safepath + query)
      return
    }

    next()
  })
}
