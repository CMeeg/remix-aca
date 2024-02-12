import { createContext, useContext } from "react"

const NonceContext = createContext<string | undefined>(undefined)

const useNonce = () => useContext(NonceContext)

export { NonceContext, useNonce }
