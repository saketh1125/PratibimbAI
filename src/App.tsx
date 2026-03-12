import React from 'react';
import { UniversalScene } from './components/UniversalScene';
import { useBridge } from './hooks/useBridge';

// Main App Component
const App: React.FC = () => {
  // Initialize bridge
  useBridge();

  return (
    <div className="w-screen h-screen bg-slate-950 overflow-hidden">
      {/* 3D Scene */}
      <div className="absolute inset-0">
        <UniversalScene />
      </div>
    </div>
  );
};

export default App;
