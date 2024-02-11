import helmet from "helmet"
import crypto from "node:crypto"

export function useSecurity(app) {
  const isProductionMode = process.env.NODE_ENV === "production"

  const localhost = "localhost"
  const baseUrl = process.env.BASE_URL ?? ""
  const baseHostname = baseUrl ? new URL(baseUrl).hostname : localhost
  const isLocalhost = baseHostname === localhost

  const cdnUrl = process.env.CDN_URL ?? ""
  const cdnHostname = cdnUrl ? new URL(cdnUrl).hostname : ""

  const reportOnly = false

  const strictTransportSecurity = isProductionMode && !isLocalhost

  app.use((_, res, next) => {
    res.locals.cspNonce = crypto.randomBytes(16).toString("hex")
    next()
  })

  app.use(
    helmet({
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          "default-src": ["'self'", cdnHostname],
          "connect-src": ["'self'", isProductionMode ? "" : "ws:"],
          "img-src": ["'self'", "data:", cdnHostname],
          "script-src": [
            "'self'",
            "'strict-dynamic'",
            (_, res) => `'nonce-${res.locals.cspNonce}'`
          ],
          "script-src-attr": [(_, res) => `'nonce-${res.locals.cspNonce}'`],
          "upgrade-insecure-requests":
            !reportOnly && strictTransportSecurity ? [] : null
        },
        reportOnly
      },
      strictTransportSecurity,
      crossOriginResourcePolicy: false
    })
  )

  app.use((req, res, next) => {
    const policy = req.headers["x-azure-ref"] ? "cross-origin" : "same-origin"

    res.set("Cross-Origin-Resource-Policy", policy)

    next()
  })
}
