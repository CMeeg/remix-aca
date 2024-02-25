import { generateRobotsTxt } from "@nasa-gcn/remix-seo"
import type { RobotsConfig } from "@nasa-gcn/remix-seo/build/types"
import { environment, currentEnvironment } from "~/lib/env.server"
import { getAbsoluteUrl } from "~/lib/url.server"

export function loader() {
  const config: RobotsConfig = {
    appendOnDefaultPolicies: false,
    headers: {
      "Cache-Control": `public, max-age=${60 * 60}`
    }
  }

  if (currentEnvironment !== environment.production) {
    return generateRobotsTxt(
      [
        { type: "userAgent", value: "*" },
        { type: "disallow", value: "/" }
      ],
      config
    )
  }

  return generateRobotsTxt(
    [
      { type: "userAgent", value: "*" },
      { type: "allow", value: "/" },
      { type: "sitemap", value: getAbsoluteUrl("sitemap.xml") }
    ],
    config
  )
}
