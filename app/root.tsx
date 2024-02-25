import {
  useLoaderData,
  Links,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
  useRouteError,
  isRouteErrorResponse
} from "@remix-run/react"
import type { LinksFunction } from "@remix-run/node"
import { json } from "@remix-run/node"
import { getCdnUrl } from "~/lib/url"
import { getClientEnv } from "~/lib/env.server"
import { useNonce } from "~/components/NonceContext"
import { AppInsightsClient } from "~/components/AppInsights/Client"
import { ClientEnvScript } from "~/components/ClientEnvScript"

export const links: LinksFunction = () => {
  const links: ReturnType<LinksFunction> = []

  const cdnUrl = getCdnUrl("", false)

  if (cdnUrl.length > 0) {
    links.push({
      rel: "preconnect",
      href: cdnUrl
    })
  }

  return links
}

export async function loader() {
  return json({
    env: getClientEnv()
  })
}

export default function App() {
  const nonce = useNonce()

  const data = useLoaderData<typeof loader>()

  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <Meta />
        <Links />
      </head>
      <body>
        <AppInsightsClient>
          <Outlet />
        </AppInsightsClient>
        <ClientEnvScript nonce={nonce} env={data.env} />
        <ScrollRestoration nonce={nonce} />
        <Scripts nonce={nonce} />
      </body>
    </html>
  )
}

export function ErrorBoundary() {
  const nonce = useNonce()
  const error = useRouteError()

  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Oops!</title>
        <Meta />
        <Links />
      </head>
      <body>
        <AppInsightsClient>
          <h1>
            Error boundary says:{" "}
            {isRouteErrorResponse(error)
              ? `${error.status} ${error.statusText}`
              : error instanceof Error
                ? error.message
                : "Unknown Error"}
          </h1>
        </AppInsightsClient>
        <Scripts nonce={nonce} />
      </body>
    </html>
  )
}
