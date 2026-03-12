import React, { useRef, useMemo } from 'react';
import { useFrame } from '@react-three/fiber';
import { Float } from '@react-three/drei';
import * as THREE from 'three';
import { Primitive, PrimitiveType } from '../types/schema';

interface PrimitiveProps {
  primitive: Primitive;
  isSelected?: boolean;
  onClick?: () => void;
}

// Geometry factory function
function createGeometry(type: PrimitiveType, args: number[]): THREE.BufferGeometry {
  switch (type) {
    case 'box':
      return new THREE.BoxGeometry(...(args.slice(0, 3) as [number, number, number]));
    case 'sphere':
      return new THREE.SphereGeometry(...(args as [number, number?, number?, number?, number?, number?, number?]));
    case 'cylinder':
      return new THREE.CylinderGeometry(...(args as [number?, number?, number?, number?, number?, boolean?, number?, number?]));
    case 'cone':
      return new THREE.ConeGeometry(...(args as [number?, number?, number?, number?, boolean?, number?, number?]));
    case 'torus':
      return new THREE.TorusGeometry(...(args as [number?, number?, number?, number?, number?]));
    case 'capsule':
      return new THREE.CapsuleGeometry(...(args as [number?, number?, number?, number?]));
    case 'plane':
      return new THREE.PlaneGeometry(...(args as [number?, number?, number?, number?]));
    case 'ring':
      return new THREE.RingGeometry(...(args as [number?, number?, number?, number?, number?, number?]));
    case 'dodecahedron':
      return new THREE.DodecahedronGeometry(...(args as [number?, number?]));
    case 'octahedron':
      return new THREE.OctahedronGeometry(...(args as [number?, number?]));
    case 'tetrahedron':
      return new THREE.TetrahedronGeometry(...(args as [number?, number?]));
    case 'icosahedron':
      return new THREE.IcosahedronGeometry(...(args as [number?, number?]));
    default:
      return new THREE.BoxGeometry(1, 1, 1);
  }
}

// Single Primitive Mesh Component
const PrimitiveMesh: React.FC<PrimitiveProps> = ({ primitive, isSelected, onClick }) => {
  const meshRef = useRef<THREE.Mesh>(null);
  const { type, args, transform, material, animate, castShadow = true, receiveShadow = true } = primitive;

  // Create geometry
  const geometry = useMemo(() => createGeometry(type, args), [type, args]);

  // Create material
  const meshMaterial = useMemo(() => {
    return new THREE.MeshStandardMaterial({
      color: new THREE.Color(material.color),
      metalness: material.metalness,
      roughness: material.roughness,
      emissive: material.emissive ? new THREE.Color(material.emissive) : undefined,
      emissiveIntensity: material.emissiveIntensity || 0,
      opacity: material.opacity ?? 1,
      transparent: material.transparent || (material.opacity !== undefined && material.opacity < 1),
      wireframe: material.wireframe || false,
      flatShading: material.flatShading || false,
      side: THREE.DoubleSide
    });
  }, [material]);

  // Animation frame
  useFrame((_, delta) => {
    if (meshRef.current && animate?.rotation) {
      meshRef.current.rotation.x += animate.rotation[0] * delta;
      meshRef.current.rotation.y += animate.rotation[1] * delta;
      meshRef.current.rotation.z += animate.rotation[2] * delta;
    }
  });

  const mesh = (
    <mesh
      ref={meshRef}
      geometry={geometry}
      material={meshMaterial}
      position={transform.pos}
      rotation={transform.rot}
      scale={transform.scale}
      castShadow={castShadow}
      receiveShadow={receiveShadow}
      onClick={onClick}
    >
      {isSelected && (
        <meshBasicMaterial
          color="#00ffff"
          wireframe
          transparent
          opacity={0.5}
        />
      )}
    </mesh>
  );

  // Wrap in Float component if floating animation is enabled
  if (animate?.float) {
    return (
      <Float
        speed={animate.floatSpeed || 2}
        rotationIntensity={0}
        floatIntensity={animate.floatIntensity || 0.5}
        floatingRange={[-0.1, 0.1]}
      >
        {mesh}
      </Float>
    );
  }

  return mesh;
};

// Primitive Factory Component - renders all primitives
interface PrimitiveFactoryProps {
  primitives: Primitive[];
  selectedId?: string | null;
  onSelect?: (id: string | null) => void;
}

export const PrimitiveFactory: React.FC<PrimitiveFactoryProps> = ({
  primitives,
  selectedId,
  onSelect
}) => {
  return (
    <group name="primitives-group">
      {primitives.map((primitive, index) => {
        const id = primitive.id || `primitive-${index}`;
        return (
          <PrimitiveMesh
            key={id}
            primitive={primitive}
            isSelected={selectedId === id}
            onClick={() => onSelect?.(id)}
          />
        );
      })}
    </group>
  );
};

export default PrimitiveFactory;
