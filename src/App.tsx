import React, { useState, useEffect, useCallback } from 'react';
import { UniversalScene } from './components/UniversalScene';
import { useSceneStore } from './store/sceneStore';
import { useBridge } from './hooks/useBridge';
import { DEFAULT_SCENE, TAJ_MAHAL_SCENE, SceneBlueprint } from './types/schema';

// Template scenes
const SCENE_TEMPLATES: Record<string, SceneBlueprint> = {
  default: DEFAULT_SCENE,
  tajMahal: TAJ_MAHAL_SCENE
};

// Glassmorphic Card Component
const GlassCard: React.FC<{ 
  children: React.ReactNode; 
  className?: string;
  onClick?: () => void;
}> = ({ children, className = '', onClick }) => (
  <div 
    className={`
      backdrop-blur-xl bg-white/5 border border-white/10 
      rounded-2xl shadow-2xl shadow-black/20
      ${className}
    `}
    onClick={onClick}
  >
    {children}
  </div>
);

// Search Bar Component
const SearchBar: React.FC<{
  value: string;
  onChange: (value: string) => void;
  onSearch: () => void;
  isLoading: boolean;
}> = ({ value, onChange, onSearch, isLoading }) => (
  <GlassCard className="flex items-center gap-3 px-4 py-3">
    <svg className="w-5 h-5 text-purple-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
    </svg>
    <input
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onKeyDown={(e) => e.key === 'Enter' && onSearch()}
      placeholder="Describe what you want to visualize..."
      className="flex-1 bg-transparent text-white placeholder-white/40 outline-none text-sm"
    />
    <button
      onClick={onSearch}
      disabled={isLoading || !value.trim()}
      className="px-4 py-1.5 bg-gradient-to-r from-purple-600 to-indigo-600 rounded-lg text-white text-sm font-medium
                 hover:from-purple-500 hover:to-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed
                 transition-all duration-300"
    >
      {isLoading ? (
        <span className="flex items-center gap-2">
          <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          Generating...
        </span>
      ) : 'Generate'}
    </button>
  </GlassCard>
);

// Sidebar Component
const Sidebar: React.FC<{
  isOpen: boolean;
  onClose: () => void;
  currentScene: SceneBlueprint;
  onSelectTemplate: (key: string) => void;
}> = ({ isOpen, onClose, currentScene, onSelectTemplate }) => {
  const [activeTab, setActiveTab] = useState<'scene' | 'json'>('scene');
  const [jsonValue, setJsonValue] = useState('');

  useEffect(() => {
    setJsonValue(JSON.stringify(currentScene, null, 2));
  }, [currentScene]);

  return (
    <div className={`
      fixed left-0 top-0 h-full w-96 z-40 transition-transform duration-500 ease-out
      ${isOpen ? 'translate-x-0' : '-translate-x-full'}
    `}>
      <GlassCard className="h-full flex flex-col m-4 overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-white/10">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-600 to-indigo-600 flex items-center justify-center">
              <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14 10l-2 1m0 0l-2-1m2 1v2.5M20 7l-2 1m2-1l-2-1m2 1v2.5M14 4l-2-1-2 1M4 7l2-1M4 7l2 1M4 7v2.5M12 21l-2-1m2 1l2-1m-2 1v-2.5M6 18l-2-1v-2.5M18 18l2-1v-2.5" />
              </svg>
            </div>
            <div>
              <h2 className="text-white font-bold">PratibimbAI</h2>
              <p className="text-white/50 text-xs">3D Scene Builder</p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <svg className="w-5 h-5 text-white/70" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-white/10">
          {(['scene', 'json'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-3 text-sm font-medium transition-colors ${
                activeTab === tab 
                  ? 'text-purple-400 border-b-2 border-purple-400' 
                  : 'text-white/50 hover:text-white/70'
              }`}
            >
              {tab === 'scene' ? 'Scene Info' : 'JSON Blueprint'}
            </button>
          ))}
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-4">
          {activeTab === 'scene' ? (
            <div className="space-y-4">
              {/* Current Scene Info */}
              <div className="p-4 rounded-xl bg-white/5 border border-white/10">
                <h3 className="text-white font-semibold mb-2">{currentScene.meta.name}</h3>
                <p className="text-white/60 text-sm mb-3">{currentScene.meta.description}</p>
                <div className="flex items-center gap-2">
                  <span className={`w-2 h-2 rounded-full ${currentScene.meta.gpu_status === 'active' ? 'bg-green-500' : 'bg-yellow-500'}`} />
                  <span className="text-white/50 text-xs">GPU {currentScene.meta.gpu_status}</span>
                </div>
              </div>

              {/* Stats */}
              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 rounded-xl bg-gradient-to-br from-purple-600/20 to-indigo-600/20 border border-purple-500/30">
                  <div className="text-2xl font-bold text-white">{currentScene.primitives.length}</div>
                  <div className="text-purple-300 text-xs">Primitives</div>
                </div>
                <div className="p-3 rounded-xl bg-gradient-to-br from-amber-600/20 to-orange-600/20 border border-amber-500/30">
                  <div className="text-2xl font-bold text-white">{currentScene.assets.length}</div>
                  <div className="text-amber-300 text-xs">Assets</div>
                </div>
              </div>

              {/* Templates */}
              <div>
                <h4 className="text-white/70 text-sm font-medium mb-3">Quick Templates</h4>
                <div className="space-y-2">
                  <button
                    onClick={() => onSelectTemplate('default')}
                    className="w-full p-3 rounded-xl bg-white/5 border border-white/10 text-left hover:bg-white/10 transition-colors"
                  >
                    <div className="text-white text-sm font-medium">✨ Welcome Scene</div>
                    <div className="text-white/50 text-xs">Interactive 3D demo</div>
                  </button>
                  <button
                    onClick={() => onSelectTemplate('tajMahal')}
                    className="w-full p-3 rounded-xl bg-white/5 border border-white/10 text-left hover:bg-white/10 transition-colors"
                  >
                    <div className="text-white text-sm font-medium">🕌 Taj Mahal</div>
                    <div className="text-white/50 text-xs">Architectural masterpiece</div>
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <div className="space-y-3">
              <textarea
                value={jsonValue}
                onChange={(e) => setJsonValue(e.target.value)}
                className="w-full h-[400px] bg-black/30 border border-white/10 rounded-xl p-3 text-white/90 text-xs font-mono resize-none outline-none focus:border-purple-500/50"
                spellCheck={false}
              />
              <button
                onClick={() => {
                  try {
                    const scene = JSON.parse(jsonValue);
                    useSceneStore.getState().setScene(scene);
                  } catch (e) {
                    alert('Invalid JSON');
                  }
                }}
                className="w-full py-2 bg-gradient-to-r from-purple-600 to-indigo-600 rounded-xl text-white text-sm font-medium hover:opacity-90 transition-opacity"
              >
                Apply JSON
              </button>
            </div>
          )}
        </div>
      </GlassCard>
    </div>
  );
};

// GPU Info Badge
const GPUInfoBadge: React.FC = () => {
  const { gpuInfo } = useSceneStore();
  const [expanded, setExpanded] = useState(false);

  if (!gpuInfo) return null;

  return (
    <GlassCard 
      className="cursor-pointer transition-all duration-300 overflow-hidden"
      onClick={() => setExpanded(!expanded)}
    >
      <div className="px-3 py-2 flex items-center gap-2">
        <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
        <span className="text-white/70 text-xs font-medium">GPU Active</span>
        <svg className={`w-3 h-3 text-white/50 transition-transform ${expanded ? 'rotate-180' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </div>
      {expanded && (
        <div className="px-3 pb-3 pt-1 border-t border-white/10 space-y-1">
          <div className="text-white/90 text-xs font-medium truncate">{gpuInfo.renderer}</div>
          <div className="text-white/50 text-xs">{gpuInfo.vendor}</div>
          <div className="text-white/50 text-xs">{gpuInfo.webglVersion}</div>
          <div className="text-white/50 text-xs">Max Texture: {gpuInfo.maxTextureSize}px</div>
        </div>
      )}
    </GlassCard>
  );
};

// Main App Component
const App: React.FC = () => {
  const { currentScene, setScene, isLoading, showSidebar, toggleSidebar } = useSceneStore();
  const [searchQuery, setSearchQuery] = useState('');
  
  // Initialize bridge
  useBridge();

  // Handle search
  const handleSearch = useCallback(async () => {
    if (!searchQuery.trim()) return;
    
    // In a real implementation, this would call the FastAPI backend
    console.log('Searching for:', searchQuery);
    
    // Mock: Generate a simple scene based on query
    // In production, this calls POST /v1/visualize
  }, [searchQuery]);

  // Handle template selection
  const handleSelectTemplate = useCallback((key: string) => {
    const template = SCENE_TEMPLATES[key];
    if (template) {
      setScene(template);
    }
  }, [setScene]);

  return (
    <div className="w-screen h-screen bg-slate-950 overflow-hidden">
      {/* 3D Scene */}
      <div className="absolute inset-0">
        <UniversalScene />
      </div>

      {/* UI Overlay */}
      <div className="absolute inset-0 pointer-events-none">
        {/* Top Bar */}
        <div className="absolute top-0 left-0 right-0 p-4 flex items-start justify-between pointer-events-auto">
          {/* Menu Button & GPU Info */}
          <div className="flex flex-col gap-3">
            <GlassCard className="p-2">
              <button
                onClick={toggleSidebar}
                className="p-2 hover:bg-white/10 rounded-lg transition-colors"
              >
                <svg className="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                </svg>
              </button>
            </GlassCard>
            <GPUInfoBadge />
          </div>

          {/* Search Bar */}
          <div className="flex-1 max-w-2xl mx-4">
            <SearchBar
              value={searchQuery}
              onChange={setSearchQuery}
              onSearch={handleSearch}
              isLoading={isLoading}
            />
          </div>

          {/* Logo */}
          <GlassCard className="px-4 py-3 flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-600 to-indigo-600 flex items-center justify-center">
              <span className="text-white font-bold text-sm">P</span>
            </div>
            <div className="hidden sm:block">
              <div className="text-white font-bold text-sm">PratibimbAI</div>
              <div className="text-white/50 text-xs">Educational 3D Engine</div>
            </div>
          </GlassCard>
        </div>

        {/* Bottom Info Bar */}
        <div className="absolute bottom-0 left-0 right-0 p-4 flex justify-center pointer-events-auto">
          <GlassCard className="px-6 py-3 flex items-center gap-6">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-purple-500" />
              <span className="text-white/70 text-sm">{currentScene.meta.name}</span>
            </div>
            <div className="h-4 w-px bg-white/20" />
            <div className="text-white/50 text-sm">
              {currentScene.primitives.length} objects
            </div>
            <div className="h-4 w-px bg-white/20" />
            <div className="text-white/50 text-sm flex items-center gap-2">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.12 2.122" />
              </svg>
              Drag to rotate • Pinch to zoom
            </div>
          </GlassCard>
        </div>

        {/* Sidebar */}
        <div className="pointer-events-auto">
          <Sidebar
            isOpen={showSidebar}
            onClose={toggleSidebar}
            currentScene={currentScene}
            onSelectTemplate={handleSelectTemplate}
          />
        </div>
      </div>

      {/* Backdrop for sidebar */}
      {showSidebar && (
        <div 
          className="absolute inset-0 bg-black/30 z-30"
          onClick={toggleSidebar}
        />
      )}
    </div>
  );
};

export default App;
