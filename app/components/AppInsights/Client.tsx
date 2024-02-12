import { lazy, Suspense } from "react"
import type { FC, ReactNode } from "react"
import { useEnv } from "~/lib/env"

interface AppInsightsClientProps {
  children: ReactNode
}

const AppInsightsContextProvider = lazy(() => import("./Context"))

const AppInsightsClient: FC<AppInsightsClientProps> = ({ children }) => {
  const env = useEnv()
  const connectionString = env.APPLICATIONINSIGHTS_CONNECTION_STRING

  if (!connectionString) {
    return <>{children}</>
  }

  return (
    <Suspense fallback="">
      <AppInsightsContextProvider connectionString={connectionString}>
        {children}
      </AppInsightsContextProvider>
    </Suspense>
  )
}

export { AppInsightsClient }

export type { AppInsightsClientProps }
