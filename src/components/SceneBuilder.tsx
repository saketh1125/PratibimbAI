import React, { useMemo } from 'react';
import { useThree } from '@react-three/fiber';
import { 
  Environment, 
  ContactShadows, 
  Stars,
  Cloud
} from '@react-three/drei';
import * as THREE from 'three';
import { SceneBlueprint, Light } from '../types/schema';
import { PrimitiveFactory } from './PrimitiveFactory';
import { AssetFactory } from './ModelLoader';

interface SceneBuilderProps {
  blueprint: SceneBlueprint;
  selectedPrimitiveId?: string | null;
  onSelectPrimitive?: (id: string | null) => void;
}

// Light Factory Component
const LightFactory: React.FC<{ lights: Light[] }> = ({ lights }) => {
  return (
    <group name="lights-group">
      {lights.map((light, index) => {
        const key = `light-${index}`;
        
        switch (light.type) {
          case 'directional':
            return (
              <directionalLight
                key={key}
                color={light.color}
                intensity={light.intensity}
                position={light.position || [10, 10, 10]}
                castShadow={light.castShadow}
                shadow-mapSize={[2048, 2048]}
                shadow-camera-far={50}
                shadow-camera-left={-20}
                shadow-camera-right={20}
                shadow-camera-top={20}
                shadow-camera-bottom={-20}
                shadow-bias={-0.0001}
              />
            );
          
          case 'point':
            return (
              <pointLight
                key={key}
                color={light.color}
                intensity={light.intensity}
                position={light.position || [0, 5, 0]}
                castShadow={light.castShadow}
                decay={light.decay || 2}
                distance={light.distance || 0}
              />
            );
          
          case 'spot':
            return (
              <spotLight
                key={key}
                color={light.color}
                intensity={light.intensity}
                position={light.position || [0, 10, 0]}
                castShadow={light.castShadow}
                angle={light.angle || Math.PI / 6}
                penumbra={light.penumbra || 0.5}
                decay={light.decay || 2}
                distance={light.distance || 0}
              />
            );
          
          case 'ambient':
            return (
              <ambientLight
                key={key}
                color={light.color}
                intensity={light.intensity}
              />
            );
          
          default:
            return null;
        }
      })}
    </group>
  );
};

// Ground Component
const Ground: React.FC<{ color: string; visible: boolean }> = ({ color, visible }) => {
  if (!visible) return null;
  
  return (
    <group name="ground-group">
      {/* Main ground plane */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.01, 0]} receiveShadow>
        <planeGeometry args={[100, 100]} />
        <meshStandardMaterial 
          color={color} 
          metalness={0.1} 
          roughness={0.9}
        />
      </mesh>
      
      {/* Grid helper for visual reference */}
      <gridHelper 
        args={[50, 50, '#333333', '#222222']} 
        position={[0, 0.01, 0]}
      />
    </group>
  );
};

// Atmosphere Component
const Atmosphere: React.FC<{ 
  skyColor: string; 
  fogDensity: number;
  showStars?: boolean;
  showClouds?: boolean;
}> = ({ skyColor, fogDensity, showStars = true, showClouds = false }) => {
  const { scene } = useThree();
  
  // Set fog
  useMemo(() => {
    scene.fog = new THREE.FogExp2(skyColor, fogDensity);
    scene.background = new THREE.Color(skyColor);
  }, [scene, skyColor, fogDensity]);
  
  return (
    <group name="atmosphere-group">
      {showStars && (
        <Stars
          radius={100}
          depth={50}
          count={5000}
          factor={4}
          saturation={0}
          fade
          speed={1}
        />
      )}
      
      {showClouds && (
        <>
          <Cloud position={[-10, 15, -15]} speed={0.2} opacity={0.3} />
          <Cloud position={[10, 12, -10]} speed={0.3} opacity={0.25} />
          <Cloud position={[0, 18, -20]} speed={0.15} opacity={0.2} />
        </>
      )}
    </group>
  );
};

// Main Scene Builder Component
export const SceneBuilder: React.FC<SceneBuilderProps> = ({
  blueprint,
  selectedPrimitiveId,
  onSelectPrimitive
}) => {
  const { environment, primitives, assets, lights } = blueprint;
  
  // Determine if we should show special atmosphere effects
  const isDarkScene = useMemo(() => {
    const color = new THREE.Color(environment.skyColor);
    return color.getHSL({ h: 0, s: 0, l: 0 }).l < 0.3;
  }, [environment.skyColor]);

  return (
    <group name="scene-builder">
      {/* Atmosphere & Background */}
      <Atmosphere
        skyColor={environment.skyColor}
        fogDensity={environment.fogDensity}
        showStars={isDarkScene}
        showClouds={!isDarkScene}
      />
      
      {/* Environment Map for reflections */}
      <Environment preset="city" background={false} />
      
      {/* Lights */}
      {lights && lights.length > 0 ? (
        <LightFactory lights={lights} />
      ) : (
        // Default lighting if none specified
        <>
          <ambientLight intensity={environment.ambientIntensity || 0.4} />
          <directionalLight
            position={[10, 15, 10]}
            intensity={1.5}
            castShadow
            shadow-mapSize={[2048, 2048]}
            shadow-camera-far={50}
            shadow-camera-left={-20}
            shadow-camera-right={20}
            shadow-camera-top={20}
            shadow-camera-bottom={-20}
          />
          <pointLight position={[-10, 5, -10]} intensity={0.5} color="#6366f1" />
          <pointLight position={[10, 5, 10]} intensity={0.5} color="#f59e0b" />
        </>
      )}
      
      {/* Ground */}
      <Ground 
        color={environment.groundColor || '#1a1a2e'} 
        visible={environment.ground} 
      />
      
      {/* Contact Shadows for premium look */}
      {environment.shadowsEnabled !== false && (
        <ContactShadows
          position={[0, 0, 0]}
          opacity={0.5}
          scale={40}
          blur={2}
          far={10}
          resolution={256}
          color="#000000"
        />
      )}
      
      {/* Render all primitives */}
      <PrimitiveFactory
        primitives={primitives}
        selectedId={selectedPrimitiveId}
        onSelect={onSelectPrimitive}
      />
      
      {/* Render all GLB/GLTF assets */}
      <AssetFactory
        assets={assets}
        onAssetLoad={(id) => console.log(`[SceneBuilder] Asset loaded: ${id}`)}
        onAssetError={(id, error) => console.error(`[SceneBuilder] Asset error: ${id}`, error)}
      />
    </group>
  );
};

export default SceneBuilder;
