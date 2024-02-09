import { createRequestHandler } from "@remix-run/express"
import { installGlobals } from "@remix-run/node"
import compression from "compression"
import express from "express"
import morgan from "morgan"

if (process.env.NODE_ENV !== "production") {
  await import("dotenv").then((dotenv) => dotenv.config())
}

installGlobals()

const viteDevServer =
  process.env.NODE_ENV === "production"
    ? undefined
    : await import("vite").then((vite) =>
        vite.createServer({
          server: { middlewareMode: true }
        })
      )

const remixHandler = createRequestHandler({
  build: viteDevServer
    ? () => viteDevServer.ssrLoadModule("virtual:remix/server-build")
    : await import("./build/server/index.js")
})

const app = express()

// Rewrite paths that start with the build ID to remove the build ID (used for cache busting)
const buildId = process.env.BUILD_ID
if (buildId) {
  app.get(`/${buildId}/*`, (req, res, next) => {
    req.url = `/${req.params["0"]}`
    next()
  })
}

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

// http://expressjs.com/en/advanced/best-practice-security.html#at-a-minimum-disable-x-powered-by-header
app.disable("x-powered-by")

// Handle asset requests
if (viteDevServer) {
  app.use(viteDevServer.middlewares)
} else {
  // Vite fingerprints its assets so we can cache forever
  app.use(
    "/assets",
    express.static("build/client/assets", { immutable: true, maxAge: "1y" })
  )
}

// Everything else (like favicon.ico) is cached for an hour. You may want to be more aggressive with this caching
app.use(express.static("build/client", { maxAge: "1h" }))

app.use(morgan("tiny"))

// Handle SSR requests
app.all("*", remixHandler)

const port = process.env.PORT || 3000
app.listen(port, () =>
  console.log(`Express server listening at http://localhost:${port}`)
)
