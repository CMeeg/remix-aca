/* eslint-disable import/no-unresolved */
import { generateSitemap } from "@nasa-gcn/remix-seo"
import type { LoaderFunctionArgs, ServerBuild } from "@remix-run/node"
import { getAbsoluteUrl } from "~/lib/url"

// TODO: Hopefully this implementation can be simplified a little once some issues with Remix+Vite are resolved
// https://github.com/nasa-gcn/remix-seo/issues/7

type Routes = ServerBuild["routes"]
type Route = Routes[keyof Routes]

function findRealParentId(route: Route, routes: Routes) {
  if (route.parentId) {
    const parentRoute = routes[route.parentId]!

    if (typeof parentRoute.path !== "undefined") {
      return parentRoute.id
    }

    return findRealParentId(parentRoute, routes)
  }

  return route.id === "root" ? undefined : "root"
}

export async function loader({ request }: LoaderFunctionArgs) {
  const build = (await (import.meta.env.DEV
    ? //@ts-ignore: If you haven't performed a build yet, this file will not exist
      import("../../build/server/index.js")
    : import(
        /* @vite-ignore */ import.meta.resolve("../../build/server/index.js")
      ))) as ServerBuild

  for (const key in build.routes) {
    const route = build.routes[key]!
    route.parentId = findRealParentId(route, build.routes)
  }

  return generateSitemap(request, build.routes, {
    siteUrl: getAbsoluteUrl(),
    headers: {
      "Cache-Control": `public, max-age=${60 * 60}`
    }
  })
}
