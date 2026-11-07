import { Link, Route, Routes } from 'react-router'
import { MarketplacePage } from './marketplace/MarketplacePage'

export default function App() {
  return <Routes>
    <Route path="/" element={<MarketplacePage />} />
    <Route path="*" element={<main><h1>Page not found</h1><Link to="/">Back to marketplace</Link></main>} />
  </Routes>
}
