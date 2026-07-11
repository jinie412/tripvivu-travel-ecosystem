import React from 'react'
import AppRoutes from './routes'
import DynamicTitle from './components/DynamicTitle'

const App: React.FC = () => {
  return (
    <div className="app-container">
      <DynamicTitle />
      <AppRoutes />
    </div>
  )
}

export default App;
