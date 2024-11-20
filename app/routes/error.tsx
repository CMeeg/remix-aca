import type { MetaFunction } from "@remix-run/node"
import { json } from "@remix-run/node"
import { Link } from "@remix-run/react"
import { getCdnUrl } from "~/lib/url.server"
import { logger } from "~/lib/logger.server"

export async function loader() {
  logger().info({ route: "error" }, "Hello from the error route!")

  // throw new Error("Test error")

  return json({
    meta: [
      { title: "Error" },
      { name: "description", content: "Welcome to Remix!" },
      {
        tagName: "link",
        rel: "icon",
        href: getCdnUrl("/favicon.ico")
      }
    ]
  })
}

export const meta: MetaFunction<typeof loader> = ({ data }) => {
  if (!data) {
    return []
  }

  return data.meta
}

export default function Index() {
  return (
    <div style={{ fontFamily: "system-ui, sans-serif", lineHeight: "1.8" }}>
      <h1>Error</h1>
      <Link to="/">Home page</Link>
      <button
        onClick={() => {
          throw new Error("Test error")
        }}
      >
        Throw error
      </button>
    </div>
  )
}
