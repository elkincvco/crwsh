import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { useAuth } from './hooks/useAuth';
import { LoginForm } from './components/LoginForm';
import { WorkspaceView } from './components/WorkspaceView';
import { BookingFlow } from './components/booking/BookingFlow';
import { PublicTrackingView } from './components/tracking/PublicTrackingView';
import { PWAInstallPrompt } from './components/pwa/PWAInstallPrompt';
import { PWAUpdatePrompt } from './components/pwa/PWAUpdatePrompt';
import { OfflineIndicator } from './components/pwa/OfflineIndicator';

function App() {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen bg-blue-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-blue-600">Cargando...</p>
        </div>
      </div>
    );
  }

  return (
    <Router>
      {/* PWA Components */}
      <OfflineIndicator />
      <PWAInstallPrompt />
      <PWAUpdatePrompt />
      
      <Routes>
        {/* Public booking route */}
        <Route path="/book/:workspaceId" element={<BookingFlow />} />
        
        {/* Public tracking route */}
        <Route path="/track/:appointmentId" element={<PublicTrackingView />} />
        
        {/* Protected admin routes */}
        <Route path="/*" element={
          !user ? <LoginForm /> : <WorkspaceView />
        } />
      </Routes>
    </Router>
  );
}

export default App;
