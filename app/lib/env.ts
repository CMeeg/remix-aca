import { useRouteLoaderData } from "@remix-run/react"
import type { loader } from "~/root"

const environment = {
  development: "development",
  production: "production"
} as const

type Environment = keyof typeof environment

const useEnv = () => {
  const data = useRouteLoaderData<typeof loader>("root")!

  return data.env
}

const getEnv = () => (typeof document === "undefined" ? ENV : window.ENV)

export { environment, useEnv, getEnv }

export type { Environment }
