import { environment } from "~/lib/env"

interface ClientEnvScriptProps {
  env: Record<string, unknown>
  nonce?: string
}

const ClientEnvScript = ({ env, nonce }: ClientEnvScriptProps) => {
  return (
    <script
      nonce={nonce}
      // The `nonce` causes a hydration warning in development, but it's safe to suppress it
      suppressHydrationWarning={env.APP_ENV === environment.development}
      dangerouslySetInnerHTML={{
        __html: `window.ENV = ${JSON.stringify(env)}`
      }}
    />
  )
}

export { ClientEnvScript }

export type { ClientEnvScriptProps }
