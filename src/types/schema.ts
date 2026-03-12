// PratibimbAI Core Data Schema - The Contract
// This schema defines the entire system's data structure

export interface SceneMeta {
  name: string;
  description: string;
  gpu_status: 'active' | 'inactive' | 'fallback';
  version?: string;
  author?: string;
}

export interface SceneEnvironment {
  skyColor: string;
  fogDensity: number;
  bloomIntensity: number;
  ground: boolean;
  groundColor?: string;
  ambientIntensity?: number;
  shadowsEnabled?: boolean;
}

export interface AssetTransform {
  pos: [number, number, number];
  rot?: [number, number, number];
  scale: [number, number, number];
}

export interface Asset {
  id: string;
  url: string;
  pos: [number, number, number];
  scale: [number, number, number];
  rot?: [number, number, number];
  name?: string;
}

export type PrimitiveType = 'box' | 'sphere' | 'cylinder' | 'torus' | 'cone' | 'capsule' | 'plane' | 'ring' | 'dodecahedron' | 'octahedron' | 'tetrahedron' | 'icosahedron';

export interface PrimitiveMaterial {
  color: string;
  metalness: number;
  roughness: number;
  emissive?: string;
  emissiveIntensity?: number;
  opacity?: number;
  transparent?: boolean;
  wireframe?: boolean;
  flatShading?: boolean;
}

export interface PrimitiveTransform {
  pos: [number, number, number];
  rot: [number, number, number];
  scale: [number, number, number];
}

export interface Primitive {
  id?: string;
  name?: string;
  type: PrimitiveType;
  args: number[];
  transform: PrimitiveTransform;
  material: PrimitiveMaterial;
  castShadow?: boolean;
  receiveShadow?: boolean;
  animate?: {
    rotation?: [number, number, number];
    float?: boolean;
    floatIntensity?: number;
    floatSpeed?: number;
  };
}

export interface Light {
  type: 'directional' | 'point' | 'spot' | 'ambient';
  color: string;
  intensity: number;
  position?: [number, number, number];
  castShadow?: boolean;
  target?: [number, number, number];
  angle?: number;
  penumbra?: number;
  decay?: number;
  distance?: number;
}

export interface Camera {
  position: [number, number, number];
  target: [number, number, number];
  fov?: number;
  near?: number;
  far?: number;
}

export interface SceneBlueprint {
  meta: SceneMeta;
  environment: SceneEnvironment;
  camera?: Camera;
  lights?: Light[];
  assets: Asset[];
  primitives: Primitive[];
}

// Flutter Bridge Message Types
export interface BridgeMessage {
  type: 'LOAD_SCENE' | 'LOAD_GLB' | 'UPDATE_SETTINGS' | 'CAPTURE_SCREENSHOT' | 'RESET_SCENE';
  payload: SceneBlueprint | string | Record<string, unknown>;
  timestamp: number;
}

export interface BridgeResponse {
  type: 'SCENE_LOADED' | 'ASSET_LOADED' | 'ERROR' | 'SCREENSHOT_READY' | 'GPU_INFO' | 'BRIDGE_READY';
  payload: Record<string, unknown>;
  timestamp: number;
}

// API Request/Response Types
export interface VisualizeRequest {
  query: string;
  style?: 'realistic' | 'stylized' | 'minimalist' | 'abstract';
  complexity?: 'low' | 'medium' | 'high';
  preferGLB?: boolean;
}

export interface VisualizeResponse {
  success: boolean;
  type: 'glb' | 'procedural';
  data: SceneBlueprint | { url: string };
  processingTime: number;
  source: 'cache' | 'search' | 'synthesis';
}

// GPU Information
export interface GPUInfo {
  renderer: string;
  vendor: string;
  maxTextureSize: number;
  maxViewportDims: [number, number];
  webglVersion: string;
  extensions: string[];
  memoryInfo?: {
    totalMemory: number;
    usedMemory: number;
  };
}

// Default Scene Blueprint
export const DEFAULT_SCENE: SceneBlueprint = {
  meta: {
    name: 'PratibimbAI Welcome Scene',
    description: 'Interactive 3D Educational Environment',
    gpu_status: 'active'
  },
  environment: {
    skyColor: '#0a0a1a',
    fogDensity: 0.015,
    bloomIntensity: 1.2,
    ground: true,
    groundColor: '#1a1a2e',
    ambientIntensity: 0.4,
    shadowsEnabled: true
  },
  camera: {
    position: [8, 6, 12],
    target: [0, 0, 0],
    fov: 45
  },
  lights: [
    {
      type: 'directional',
      color: '#ffffff',
      intensity: 1.5,
      position: [10, 15, 10],
      castShadow: true
    },
    {
      type: 'point',
      color: '#6366f1',
      intensity: 2,
      position: [-5, 3, -5]
    },
    {
      type: 'point',
      color: '#f59e0b',
      intensity: 1.5,
      position: [5, 2, 5]
    }
  ],
  assets: [],
  primitives: [
    {
      id: 'platform',
      name: 'Main Platform',
      type: 'cylinder',
      args: [4, 4, 0.3, 64],
      transform: { pos: [0, -0.15, 0], rot: [0, 0, 0], scale: [1, 1, 1] },
      material: { color: '#1e1e3f', metalness: 0.9, roughness: 0.1 },
      receiveShadow: true
    },
    {
      id: 'core-sphere',
      name: 'Energy Core',
      type: 'sphere',
      args: [1, 64, 64],
      transform: { pos: [0, 1.5, 0], rot: [0, 0, 0], scale: [1, 1, 1] },
      material: { color: '#6366f1', metalness: 0.3, roughness: 0.2, emissive: '#4f46e5', emissiveIntensity: 0.5 },
      castShadow: true,
      animate: { float: true, floatIntensity: 0.3, floatSpeed: 2 }
    },
    {
      id: 'ring-1',
      name: 'Orbital Ring 1',
      type: 'torus',
      args: [2, 0.05, 16, 100],
      transform: { pos: [0, 1.5, 0], rot: [1.57, 0, 0], scale: [1, 1, 1] },
      material: { color: '#f59e0b', metalness: 0.8, roughness: 0.2, emissive: '#d97706', emissiveIntensity: 0.3 },
      animate: { rotation: [0, 0.5, 0] }
    },
    {
      id: 'ring-2',
      name: 'Orbital Ring 2',
      type: 'torus',
      args: [2.5, 0.03, 16, 100],
      transform: { pos: [0, 1.5, 0], rot: [0.8, 0.5, 0], scale: [1, 1, 1] },
      material: { color: '#10b981', metalness: 0.8, roughness: 0.2, emissive: '#059669', emissiveIntensity: 0.3 },
      animate: { rotation: [0, -0.3, 0.2] }
    },
    {
      id: 'pillar-1',
      name: 'Crystal Pillar 1',
      type: 'box',
      args: [0.3, 2, 0.3],
      transform: { pos: [3, 1, 0], rot: [0, 0, 0.1], scale: [1, 1, 1] },
      material: { color: '#ec4899', metalness: 0.7, roughness: 0.3, emissive: '#db2777', emissiveIntensity: 0.2 },
      castShadow: true
    },
    {
      id: 'pillar-2',
      name: 'Crystal Pillar 2',
      type: 'box',
      args: [0.3, 1.5, 0.3],
      transform: { pos: [-2.5, 0.75, 1.5], rot: [0, 0.5, -0.1], scale: [1, 1, 1] },
      material: { color: '#8b5cf6', metalness: 0.7, roughness: 0.3, emissive: '#7c3aed', emissiveIntensity: 0.2 },
      castShadow: true
    },
    {
      id: 'pillar-3',
      name: 'Crystal Pillar 3',
      type: 'box',
      args: [0.25, 1.8, 0.25],
      transform: { pos: [-1, 0.9, -2.8], rot: [0, -0.3, 0.05], scale: [1, 1, 1] },
      material: { color: '#06b6d4', metalness: 0.7, roughness: 0.3, emissive: '#0891b2', emissiveIntensity: 0.2 },
      castShadow: true
    }
  ]
};

// Taj Mahal Scene Blueprint
export const TAJ_MAHAL_SCENE: SceneBlueprint = {
  meta: {
    name: 'Taj Mahal',
    description: 'The Crown of Palaces - A UNESCO World Heritage Site',
    gpu_status: 'active'
  },
  environment: {
    skyColor: '#1a0a2e',
    fogDensity: 0.008,
    bloomIntensity: 1.5,
    ground: true,
    groundColor: '#0d4a0d',
    ambientIntensity: 0.5,
    shadowsEnabled: true
  },
  camera: {
    position: [0, 8, 25],
    target: [0, 4, 0],
    fov: 50
  },
  lights: [
    {
      type: 'directional',
      color: '#ffeedd',
      intensity: 2,
      position: [15, 20, 10],
      castShadow: true
    },
    {
      type: 'point',
      color: '#ffcc88',
      intensity: 1.5,
      position: [0, 10, 0]
    },
    {
      type: 'ambient',
      color: '#334466',
      intensity: 0.4
    }
  ],
  assets: [],
  primitives: [
    // Main Platform
    { type: 'box', args: [20, 1, 20], transform: { pos: [0, 0.5, 0], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#8b0000', metalness: 0.3, roughness: 0.8 }, receiveShadow: true },
    { type: 'box', args: [14, 0.8, 14], transform: { pos: [0, 1.4, 0], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.1, roughness: 0.3 }, receiveShadow: true },
    
    // Main Building
    { type: 'box', args: [8, 6, 8], transform: { pos: [0, 4.8, 0], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    
    // Chamfered Corners
    { type: 'box', args: [1.5, 6, 1.5], transform: { pos: [3.5, 4.8, 3.5], rot: [0, 0.785, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    { type: 'box', args: [1.5, 6, 1.5], transform: { pos: [-3.5, 4.8, 3.5], rot: [0, 0.785, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    { type: 'box', args: [1.5, 6, 1.5], transform: { pos: [3.5, 4.8, -3.5], rot: [0, 0.785, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    { type: 'box', args: [1.5, 6, 1.5], transform: { pos: [-3.5, 4.8, -3.5], rot: [0, 0.785, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    
    // Main Dome
    { type: 'cylinder', args: [3.5, 3.5, 1.5, 64], transform: { pos: [0, 8.5, 0], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    { type: 'sphere', args: [3.2, 64, 32, 0, 6.28, 0, 1.57], transform: { pos: [0, 9.5, 0], rot: [0, 0, 0], scale: [1, 1.3, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 }, castShadow: true },
    { type: 'cylinder', args: [0.15, 0.1, 2, 16], transform: { pos: [0, 14, 0], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 }, castShadow: true },
    { type: 'sphere', args: [0.25, 16, 16], transform: { pos: [0, 15.2, 0], rot: [0, 0, 0], scale: [1, 0.6, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 } },
    
    // Corner Chhatris
    { type: 'cylinder', args: [0.8, 0.8, 0.4, 32], transform: { pos: [3.2, 8.2, 3.2], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 } },
    { type: 'sphere', args: [0.7, 32, 16, 0, 6.28, 0, 1.57], transform: { pos: [3.2, 8.6, 3.2], rot: [0, 0, 0], scale: [1, 1.2, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'cylinder', args: [0.05, 0.04, 0.8, 8], transform: { pos: [3.2, 9.8, 3.2], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 } },
    
    { type: 'cylinder', args: [0.8, 0.8, 0.4, 32], transform: { pos: [-3.2, 8.2, 3.2], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 } },
    { type: 'sphere', args: [0.7, 32, 16, 0, 6.28, 0, 1.57], transform: { pos: [-3.2, 8.6, 3.2], rot: [0, 0, 0], scale: [1, 1.2, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'cylinder', args: [0.05, 0.04, 0.8, 8], transform: { pos: [-3.2, 9.8, 3.2], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 } },
    
    { type: 'cylinder', args: [0.8, 0.8, 0.4, 32], transform: { pos: [3.2, 8.2, -3.2], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 } },
    { type: 'sphere', args: [0.7, 32, 16, 0, 6.28, 0, 1.57], transform: { pos: [3.2, 8.6, -3.2], rot: [0, 0, 0], scale: [1, 1.2, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'cylinder', args: [0.05, 0.04, 0.8, 8], transform: { pos: [3.2, 9.8, -3.2], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 } },
    
    { type: 'cylinder', args: [0.8, 0.8, 0.4, 32], transform: { pos: [-3.2, 8.2, -3.2], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 } },
    { type: 'sphere', args: [0.7, 32, 16, 0, 6.28, 0, 1.57], transform: { pos: [-3.2, 8.6, -3.2], rot: [0, 0, 0], scale: [1, 1.2, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'cylinder', args: [0.05, 0.04, 0.8, 8], transform: { pos: [-3.2, 9.8, -3.2], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 } },
    
    // Minarets
    { type: 'cylinder', args: [0.6, 0.7, 10, 32], transform: { pos: [7, 6, 7], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    { type: 'torus', args: [0.7, 0.1, 8, 32], transform: { pos: [7, 8, 7], rot: [1.57, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'torus', args: [0.65, 0.08, 8, 32], transform: { pos: [7, 10, 7], rot: [1.57, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'sphere', args: [0.5, 32, 16, 0, 6.28, 0, 1.57], transform: { pos: [7, 11.5, 7], rot: [0, 0, 0], scale: [1, 1.2, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'cylinder', args: [0.04, 0.03, 0.6, 8], transform: { pos: [7, 12.5, 7], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 } },
    
    { type: 'cylinder', args: [0.6, 0.7, 10, 32], transform: { pos: [-7, 6, 7], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    { type: 'torus', args: [0.7, 0.1, 8, 32], transform: { pos: [-7, 8, 7], rot: [1.57, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'torus', args: [0.65, 0.08, 8, 32], transform: { pos: [-7, 10, 7], rot: [1.57, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'sphere', args: [0.5, 32, 16, 0, 6.28, 0, 1.57], transform: { pos: [-7, 11.5, 7], rot: [0, 0, 0], scale: [1, 1.2, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'cylinder', args: [0.04, 0.03, 0.6, 8], transform: { pos: [-7, 12.5, 7], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 } },
    
    { type: 'cylinder', args: [0.6, 0.7, 10, 32], transform: { pos: [7, 6, -7], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    { type: 'torus', args: [0.7, 0.1, 8, 32], transform: { pos: [7, 8, -7], rot: [1.57, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'torus', args: [0.65, 0.08, 8, 32], transform: { pos: [7, 10, -7], rot: [1.57, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'sphere', args: [0.5, 32, 16, 0, 6.28, 0, 1.57], transform: { pos: [7, 11.5, -7], rot: [0, 0, 0], scale: [1, 1.2, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'cylinder', args: [0.04, 0.03, 0.6, 8], transform: { pos: [7, 12.5, -7], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 } },
    
    { type: 'cylinder', args: [0.6, 0.7, 10, 32], transform: { pos: [-7, 6, -7], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.2, roughness: 0.3 }, castShadow: true },
    { type: 'torus', args: [0.7, 0.1, 8, 32], transform: { pos: [-7, 8, -7], rot: [1.57, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'torus', args: [0.65, 0.08, 8, 32], transform: { pos: [-7, 10, -7], rot: [1.57, 0, 0], scale: [1, 1, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'sphere', args: [0.5, 32, 16, 0, 6.28, 0, 1.57], transform: { pos: [-7, 11.5, -7], rot: [0, 0, 0], scale: [1, 1.2, 1] }, material: { color: '#faf8f5', metalness: 0.3, roughness: 0.2 } },
    { type: 'cylinder', args: [0.04, 0.03, 0.6, 8], transform: { pos: [-7, 12.5, -7], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.9, roughness: 0.1 } },
    
    // Front Iwan (Arch)
    { type: 'box', args: [3, 5, 0.5], transform: { pos: [0, 4.5, 4.25], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#1a1a2e', metalness: 0.1, roughness: 0.9 } },
    { type: 'box', args: [3.5, 0.5, 0.6], transform: { pos: [0, 7.25, 4.3], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#ffd700', metalness: 0.8, roughness: 0.2 } },
    
    // Reflecting Pool
    { type: 'box', args: [3, 0.1, 15], transform: { pos: [0, 1.05, 12], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#1e3a5f', metalness: 0.95, roughness: 0.05 } },
    
    // Pathway
    { type: 'box', args: [4, 0.05, 15], transform: { pos: [0, 1.03, 12], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#8b4513', metalness: 0.2, roughness: 0.8 } },
    
    // Garden Trees (simplified as cones)
    { type: 'cone', args: [0.8, 2, 8], transform: { pos: [5, 2.5, 10], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#228b22', metalness: 0.1, roughness: 0.8 } },
    { type: 'cylinder', args: [0.15, 0.15, 1, 8], transform: { pos: [5, 1.5, 10], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#4a3728', metalness: 0.1, roughness: 0.9 } },
    
    { type: 'cone', args: [0.8, 2, 8], transform: { pos: [-5, 2.5, 10], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#228b22', metalness: 0.1, roughness: 0.8 } },
    { type: 'cylinder', args: [0.15, 0.15, 1, 8], transform: { pos: [-5, 1.5, 10], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#4a3728', metalness: 0.1, roughness: 0.9 } },
    
    { type: 'cone', args: [0.8, 2, 8], transform: { pos: [5, 2.5, 15], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#228b22', metalness: 0.1, roughness: 0.8 } },
    { type: 'cylinder', args: [0.15, 0.15, 1, 8], transform: { pos: [5, 1.5, 15], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#4a3728', metalness: 0.1, roughness: 0.9 } },
    
    { type: 'cone', args: [0.8, 2, 8], transform: { pos: [-5, 2.5, 15], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#228b22', metalness: 0.1, roughness: 0.8 } },
    { type: 'cylinder', args: [0.15, 0.15, 1, 8], transform: { pos: [-5, 1.5, 15], rot: [0, 0, 0], scale: [1, 1, 1] }, material: { color: '#4a3728', metalness: 0.1, roughness: 0.9 } }
  ]
};
