import compression from "compression"

export function useCompression(app) {
  app.use(
    compression({
      filter: (req, res) => {
        if (req.headers["x-azure-ref"]) {
          // Don't compress responses to requests from the CDN because it compresses them for us
          return false
        }

        // Otherwsie use the default filter function
        return compression.filter(req, res)
      }
    })
  )
}
