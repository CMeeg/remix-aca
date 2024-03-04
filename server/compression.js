import compression from "compression"

export function useCompression(app) {
  app.use(
    compression({
      filter: (req, res) => {
        // https://learn.microsoft.com/en-us/azure/frontdoor/front-door-http-headers-protocol#from-the-front-door-to-the-backend
        if (req.headers["x-azure-ref"]) {
          // Don't compress responses to requests from the CDN because it compresses them for us
          return false
        }

        // Otherwise use the default filter function
        return compression.filter(req, res)
      }
    })
  )
}
