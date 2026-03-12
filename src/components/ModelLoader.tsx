import React, { Suspense, useEffect, useRef } from 'react';
import { useGLTF, useAnimations } from '@react-three/drei';
import * as THREE from 'three';
import { Asset } from '../types/schema';

interface ModelLoaderProps {
  asset: Asset;
  onLoad?: () => void;
  onError?: (error: Error) => void;
}

// Individual GLB/GLTF Model Component
const GLBModel: React.FC<ModelLoaderProps> = ({ asset, onLoad }) => {
  const groupRef = useRef<THREE.Group>(null);
  
  // Load the GLTF/GLB model
  const { scene, animations } = useGLTF(asset.url, true);
  
  // Setup animations if available
  const { actions, mixer } = useAnimations(animations, groupRef);

  useEffect(() => {
    // Clone the scene to allow multiple instances
    if (scene) {
      // Enable shadows for all meshes
      scene.traverse((child) => {
        if (child instanceof THREE.Mesh) {
          child.castShadow = true;
          child.receiveShadow = true;
          
          // Ensure materials are properly configured
          if (child.material) {
            if (Array.isArray(child.material)) {
              child.material.forEach(mat => {
                mat.needsUpdate = true;
              });
            } else {
              child.material.needsUpdate = true;
            }
          }
        }
      });
      
      onLoad?.();
    }
  }, [scene, onLoad]);

  // Play all animations by default
  useEffect(() => {
    if (actions && Object.keys(actions).length > 0) {
      Object.values(actions).forEach(action => {
        action?.play();
      });
    }
    
    return () => {
      mixer?.stopAllAction();
    };
  }, [actions, mixer]);

  return (
    <group
      ref={groupRef}
      position={asset.pos}
      scale={asset.scale}
      rotation={asset.rot || [0, 0, 0]}
    >
      <primitive object={scene.clone()} />
    </group>
  );
};

// Error Boundary for model loading
class ModelErrorBoundary extends React.Component<
  { children: React.ReactNode; fallback: React.ReactNode; onError?: (error: Error) => void },
  { hasError: boolean }
> {
  constructor(props: { children: React.ReactNode; fallback: React.ReactNode; onError?: (error: Error) => void }) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error) {
    console.error('[ModelLoader] Error loading model:', error);
    this.props.onError?.(error);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}

// Loading placeholder
const LoadingPlaceholder: React.FC<{ position: [number, number, number] }> = ({ position }) => (
  <mesh position={position}>
    <boxGeometry args={[1, 1, 1]} />
    <meshStandardMaterial color="#6366f1" wireframe />
  </mesh>
);

// Error placeholder
const ErrorPlaceholder: React.FC<{ position: [number, number, number] }> = ({ position }) => (
  <mesh position={position}>
    <octahedronGeometry args={[0.5]} />
    <meshStandardMaterial color="#ef4444" />
  </mesh>
);

// Main Model Loader with Suspense and Error Boundary
export const ModelLoader: React.FC<ModelLoaderProps> = ({ asset, onLoad, onError }) => {
  return (
    <ModelErrorBoundary
      fallback={<ErrorPlaceholder position={asset.pos} />}
      onError={onError}
    >
      <Suspense fallback={<LoadingPlaceholder position={asset.pos} />}>
        <GLBModel asset={asset} onLoad={onLoad} onError={onError} />
      </Suspense>
    </ModelErrorBoundary>
  );
};

// Asset Factory - renders all assets
interface AssetFactoryProps {
  assets: Asset[];
  onAssetLoad?: (assetId: string) => void;
  onAssetError?: (assetId: string, error: Error) => void;
}

export const AssetFactory: React.FC<AssetFactoryProps> = ({
  assets,
  onAssetLoad,
  onAssetError
}) => {
  return (
    <group name="assets-group">
      {assets.map((asset) => (
        <ModelLoader
          key={asset.id}
          asset={asset}
          onLoad={() => onAssetLoad?.(asset.id)}
          onError={(error) => onAssetError?.(asset.id, error)}
        />
      ))}
    </group>
  );
};

// Preload utility for GLB models
export const preloadModel = (url: string) => {
  useGLTF.preload(url);
};

export default ModelLoader;
