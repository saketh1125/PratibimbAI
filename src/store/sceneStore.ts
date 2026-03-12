import { create } from 'zustand';
import { SceneBlueprint, GPUInfo, DEFAULT_SCENE } from '../types/schema';

interface SceneState {
  // Scene Data
  currentScene: SceneBlueprint;
  isLoading: boolean;
  error: string | null;
  
  // GPU Info
  gpuInfo: GPUInfo | null;
  
  // UI State
  showJsonEditor: boolean;
  showSidebar: boolean;
  selectedPrimitiveId: string | null;
  
  // Search
  searchQuery: string;
  searchResults: string[];
  
  // Actions
  setScene: (scene: SceneBlueprint) => void;
  updateScene: (partial: Partial<SceneBlueprint>) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setGpuInfo: (info: GPUInfo) => void;
  toggleJsonEditor: () => void;
  toggleSidebar: () => void;
  setSelectedPrimitive: (id: string | null) => void;
  setSearchQuery: (query: string) => void;
  setSearchResults: (results: string[]) => void;
  resetScene: () => void;
}

export const useSceneStore = create<SceneState>((set) => ({
  // Initial State
  currentScene: DEFAULT_SCENE,
  isLoading: false,
  error: null,
  gpuInfo: null,
  showJsonEditor: false,
  showSidebar: false,
  selectedPrimitiveId: null,
  searchQuery: '',
  searchResults: [],
  
  // Actions
  setScene: (scene) => set({ currentScene: scene, error: null }),
  
  updateScene: (partial) => set((state) => ({
    currentScene: { ...state.currentScene, ...partial }
  })),
  
  setLoading: (loading) => set({ isLoading: loading }),
  
  setError: (error) => set({ error }),
  
  setGpuInfo: (info) => set({ gpuInfo: info }),
  
  toggleJsonEditor: () => set((state) => ({ showJsonEditor: !state.showJsonEditor })),
  
  toggleSidebar: () => set((state) => ({ showSidebar: !state.showSidebar })),
  
  setSelectedPrimitive: (id) => set({ selectedPrimitiveId: id }),
  
  setSearchQuery: (query) => set({ searchQuery: query }),
  
  setSearchResults: (results) => set({ searchResults: results }),
  
  resetScene: () => set({ currentScene: DEFAULT_SCENE, error: null, isLoading: false })
}));
