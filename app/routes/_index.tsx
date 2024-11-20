import type { MetaFunction } from "@remix-run/node"
import { json } from "@remix-run/node"
import { Link } from "@remix-run/react"
import { getCdnUrl } from "~/lib/url.server"
import { logger } from "~/lib/logger.server"

export async function loader() {
  logger().info({ route: "index" }, "Hello from the index route!")

  return json({
    meta: [
      { title: "New Remix App" },
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
      <h1>Welcome to Remix</h1>
      <Link to="/error">Error page</Link>
      <ul>
        <li>
          <a
            target="_blank"
            href="https://remix.run/tutorials/blog"
            rel="noreferrer"
          >
            15m Quickstart Blog Tutorial
          </a>
        </li>
        <li>
          <a
            target="_blank"
            href="https://remix.run/tutorials/jokes"
            rel="noreferrer"
          >
            Deep Dive Jokes App Tutorial
          </a>
        </li>
        <li>
          <a target="_blank" href="https://remix.run/docs" rel="noreferrer">
            Remix Docs
          </a>
        </li>
      </ul>
    </div>
  )
}
