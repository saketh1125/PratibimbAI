import React, { Suspense, useEffect, useRef } from 'react';
import { Canvas } from '@react-three/fiber';
import { OrbitControls, Preload, PerformanceMonitor, AdaptiveDpr, Environment, ContactShadows } from '@react-three/drei';
import { EffectComposer, Bloom, Vignette } from '@react-three/postprocessing';
import * as THREE from 'three';
import { useSceneStore } from '../store/sceneStore';
import { SceneBuilder } from './SceneBuilder';

// Loading Screen Component
const LoadingScreen: React.FC = () => (
  <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
    <div className="text-center">
      <div className="relative w-24 h-24 mx-auto mb-6">
        <div className="absolute inset-0 border-4 border-purple-500/30 rounded-full" />
        <div className="absolute inset-0 border-4 border-transparent border-t-purple-500 rounded-full animate-spin" />
        <div className="absolute inset-2 border-4 border-transparent border-t-indigo-400 rounded-full animate-spin" style={{ animationDirection: 'reverse', animationDuration: '1.5s' }} />
        <div className="absolute inset-4 border-4 border-transparent border-t-cyan-400 rounded-full animate-spin" style={{ animationDuration: '2s' }} />
      </div>
      <h2 className="text-xl font-bold text-white mb-2">PratibimbAI</h2>
      <p className="text-purple-300 text-sm">Initializing 3D Engine...</p>
    </div>
  </div>
);

// Post Processing Effects
const PostProcessingEffects: React.FC<{ bloomIntensity: number }> = ({ bloomIntensity }) => {
  return (
    <EffectComposer>
      <Bloom
        luminanceThreshold={0.6}
        luminanceSmoothing={0.4}
        intensity={bloomIntensity || 0.4}
      />
      <Vignette eskil={false} offset={0.1} darkness={0.3} />
    </EffectComposer>
  );
};

// Scene Content (inside Canvas)
const SceneContent: React.FC = () => {
  const { currentScene, selectedPrimitiveId, setSelectedPrimitive } = useSceneStore();
  const controlsRef = useRef<any>(null);

  // Reset camera when scene changes
  useEffect(() => {
    if (controlsRef.current && currentScene.camera) {
      controlsRef.current.target.set(...currentScene.camera.target);
      controlsRef.current.update();
    }
  }, [currentScene]);

  return (
    <>
      {/* Performance optimization */}
      <PerformanceMonitor>
        <AdaptiveDpr pixelated />
      </PerformanceMonitor>
      
      {/* Camera Controls */}
      <OrbitControls
        ref={controlsRef}
        makeDefault
        enablePan
        enableZoom
        enableRotate
        enableDamping
        dampingFactor={0.05}
        minDistance={2}
        maxDistance={100}
        minPolarAngle={0.1}
        maxPolarAngle={Math.PI / 2 + 0.3}
        target={currentScene.camera?.target || [0, 0, 0]}
        // Touch optimizations for mobile
        touches={{
          ONE: THREE.TOUCH.ROTATE,
          TWO: THREE.TOUCH.DOLLY_PAN
        }}
      />
      
      {/* Lighting Setup */}
      <directionalLight
        position={[5, 10, 5]}
        intensity={1.2}
        castShadow
        shadow-mapSize={[2048, 2048]}
        shadow-camera-far={50}
        shadow-camera-left={-20}
        shadow-camera-right={20}
        shadow-camera-top={20}
        shadow-camera-bottom={-20}
      />
      <hemisphereLight
        intensity={0.35}
        color={'#ffffff'}
        groundColor={'#222233'}
      />
      
      {/* HDR Environment */}
      <Environment preset="city" background={false} />
      
      {/* Contact Shadows */}
      <ContactShadows
        position={[0, 0, 0]}
        opacity={0.5}
        scale={20}
        blur={2.5}
        far={10}
      />
      
      {/* Ground Plane for Shadows */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} receiveShadow position={[0, -0.01, 0]}>
        <planeGeometry args={[200, 200]} />
        <shadowMaterial opacity={0.2} />
      </mesh>
      
      {/* Main Scene */}
      <Suspense fallback={null}>
        <SceneBuilder
          blueprint={currentScene}
          selectedPrimitiveId={selectedPrimitiveId}
          onSelectPrimitive={setSelectedPrimitive}
        />
      </Suspense>
      
      {/* Post Processing */}
      <PostProcessingEffects bloomIntensity={currentScene.environment.bloomIntensity} />
      
      {/* Preload assets */}
      <Preload all />
    </>
  );
};

// Main Universal Scene Component
export const UniversalScene: React.FC = () => {
  const { currentScene, isLoading } = useSceneStore();
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const fixViewport = () => {
      const height = window.visualViewport ? window.visualViewport.height : window.innerHeight;
      document.documentElement.style.setProperty('--vh', `${height}px`);
    };
    fixViewport();
    window.addEventListener('resize', fixViewport);
    window.addEventListener('orientationchange', fixViewport);
    return () => {
      window.removeEventListener('resize', fixViewport);
      window.removeEventListener('orientationchange', fixViewport);
    };
  }, []);

  return (
    <div ref={containerRef} className="w-full h-full relative">
      {/* Loading overlay */}
      {isLoading && <LoadingScreen />}
      
      {/* Three.js Canvas */}
      <Canvas
        style={{ position: 'absolute', width: '100vw', height: '100vh', top: 0, left: 0, touchAction: 'auto' }}
        resize={{scroll:false,debounce:0}}
        shadows
        dpr={[1, 2]}
        gl={{
          antialias: true,
          alpha: false,
          powerPreference: 'high-performance',
          stencil: false,
          depth: true,
          logarithmicDepthBuffer: true
        }}
        camera={{
          position: currentScene.camera?.position || [6, 5, 8],
          fov: currentScene.camera?.fov || 50,
          near: currentScene.camera?.near || 0.1,
          far: currentScene.camera?.far || 1000
        }}

        onCreated={({ gl }) => {
          gl.toneMapping = THREE.ACESFilmicToneMapping;
          gl.toneMappingExposure = 1.2;
          gl.shadowMap.enabled = true;
          gl.shadowMap.type = THREE.PCFSoftShadowMap;
          gl.outputColorSpace = THREE.SRGBColorSpace;
        }}
      >
        <SceneContent />
      </Canvas>
    </div>
  );
};

export default UniversalScene;
