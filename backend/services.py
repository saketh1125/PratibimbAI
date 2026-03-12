"""
PratibimbAI Backend - Services
SearchService (Mock Sketchfab) and SynthesisService (Gemini Integration)
"""

import os
import json
import hashlib
import time
from typing import Optional, List, Dict, Any
from datetime import datetime
import math

from models import (
    SceneBlueprint, SceneMeta, Environment, Primitive, 
    Light, Asset, Transform, MaterialProps, VisualizeRequest,
    SearchResult
)

# Try to import Google Generative AI
try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    print("Warning: google-generativeai not installed. Using fallback synthesis.")


# System prompt for Gemini - Compositional Geometry approach
GEMINI_SYSTEM_PROMPT = """You are PratibimbAI, an expert 3D scene compositor for educational visualization.

Your task is to generate JSON blueprints for 3D scenes using COMPOSITIONAL GEOMETRY - building complex objects from simple primitives.

IMPORTANT RULES:
1. Use ONLY these primitive types: box, sphere, cylinder, torus, cone, capsule, dodecahedron, octahedron, tetrahedron
2. Build complex shapes by combining multiple primitives (e.g., a Heart = 2 spheres + 1 inverted cone)
3. All positions (pos) are [x, y, z] arrays where y is UP
4. Use realistic proportions and proper positioning
5. Include appropriate lighting for the scene
6. Add emissive materials for glowing effects
7. Use animations sparingly for key elements

COORDINATE SYSTEM:
- Origin (0, 0, 0) is at ground level center
- Y-axis points UP
- Objects should be placed above y=0 to rest on ground

COLOR PALETTE (use hex):
- Educational: #6366f1 (indigo), #8b5cf6 (purple), #06b6d4 (cyan), #22c55e (green)
- Organic: #ef4444 (red), #f97316 (orange), #eab308 (yellow), #84cc16 (lime)
- Neutral: #94a3b8 (slate), #64748b (gray), #faf8f5 (white), #1e293b (dark)

COMPOSITIONAL EXAMPLES:
- Heart: 2 overlapping spheres at top + inverted cone pointing down
- Tree: Cylinder trunk + 3 stacked cones (foliage) or sphere
- House: Box base + tetrahedron/cone roof
- Snowman: 3 stacked spheres (decreasing size)
- Table: Box top + 4 cylinder legs
- Atom: Central sphere + torus orbits + small spheres (electrons)

OUTPUT FORMAT:
Return ONLY valid JSON matching this schema (no markdown, no explanation):
{
  "meta": { "name": "string", "description": "string", "gpu_status": "active" },
  "environment": { "skyColor": "#hex", "bloomIntensity": 1.5, "ground": true, "groundColor": "#hex", "contactShadows": true },
  "lights": [{ "type": "directional|point|ambient", "color": "#hex", "intensity": 1.5, "position": [x,y,z], "castShadow": true }],
  "assets": [],
  "primitives": [
    {
      "id": "unique-id",
      "type": "primitive-type",
      "args": [geometry-args],
      "transform": { "pos": [x,y,z], "rot": [rx,ry,rz], "scale": [sx,sy,sz] },
      "material": { "color": "#hex", "metalness": 0.5, "roughness": 0.5, "emissive": "#hex", "emissiveIntensity": 0.5 }
    }
  ]
}

GEOMETRY ARGS:
- box: [width, height, depth]
- sphere: [radius, widthSegments, heightSegments]
- cylinder: [radiusTop, radiusBottom, height, radialSegments]
- cone: [radius, height, radialSegments]
- torus: [radius, tubeRadius, radialSegments, tubularSegments]
- capsule: [radius, length, capSegments, radialSegments]"""


class SearchService:
    """Mock service for searching 3D models (Sketchfab-like)"""
    
    # Mock database of available GLB models
    MOCK_MODELS: Dict[str, SearchResult] = {
        "lowpoly_tree": SearchResult(
            id="tree-001",
            name="Low Poly Tree",
            url="https://models.example.com/tree.glb",
            thumbnail="https://images.example.com/tree.jpg",
            author="PratibimbAI",
            license="CC-BY"
        ),
        "robot_character": SearchResult(
            id="robot-001", 
            name="Cute Robot Character",
            url="https://models.example.com/robot.glb",
            thumbnail="https://images.example.com/robot.jpg",
            author="PratibimbAI",
            license="CC-BY"
        ),
    }
    
    def __init__(self):
        self.cache: Dict[str, List[SearchResult]] = {}
    
    def search(self, query: str, limit: int = 5) -> List[SearchResult]:
        """Search for 3D models matching the query"""
        query_lower = query.lower()
        cache_key = f"{query_lower}:{limit}"
        
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        results = []
        for key, model in self.MOCK_MODELS.items():
            if any(term in key.lower() or term in model.name.lower() 
                   for term in query_lower.split()):
                results.append(model)
                if len(results) >= limit:
                    break
        
        self.cache[cache_key] = results
        return results
    
    def get_model_url(self, model_id: str) -> Optional[str]:
        """Get URL for a specific model"""
        for model in self.MOCK_MODELS.values():
            if model.id == model_id:
                return model.url
        return None


class SynthesisService:
    """Service for generating 3D scene blueprints using Gemini or fallback"""
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.environ.get("GOOGLE_API_KEY")
        self.model = None
        self.cache: Dict[str, SceneBlueprint] = {}
        
        if GEMINI_AVAILABLE and self.api_key:
            try:
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel(
                    model_name="gemini-1.5-pro",
                    system_instruction=GEMINI_SYSTEM_PROMPT
                )
                print("Gemini 1.5 Pro initialized successfully")
            except Exception as e:
                print(f"Failed to initialize Gemini: {e}")
                self.model = None
    
    def _generate_cache_key(self, request: VisualizeRequest) -> str:
        """Generate cache key for request"""
        data = f"{request.query}:{request.style}:{request.complexity}"
        return hashlib.md5(data.encode()).hexdigest()
    
    async def synthesize(self, request: VisualizeRequest) -> SceneBlueprint:
        """Generate a 3D scene blueprint from a text description"""
        cache_key = self._generate_cache_key(request)
        
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        # Try Gemini first
        if self.model:
            try:
                blueprint = await self._synthesize_with_gemini(request)
                self.cache[cache_key] = blueprint
                return blueprint
            except Exception as e:
                print(f"Gemini synthesis failed: {e}")
        
        # Fallback to rule-based synthesis
        blueprint = self._synthesize_fallback(request)
        self.cache[cache_key] = blueprint
        return blueprint
    
    async def _synthesize_with_gemini(self, request: VisualizeRequest) -> SceneBlueprint:
        """Generate scene using Gemini API"""
        prompt = f"""Create a 3D scene for: "{request.query}"
Style: {request.style}
Complexity: {request.complexity}

Remember to use compositional geometry - combine simple primitives to create the object.
Return ONLY the JSON blueprint, no other text."""

        response = await self.model.generate_content_async(prompt)
        
        # Parse the response
        json_str = response.text.strip()
        
        # Clean up markdown if present
        if json_str.startswith("```json"):
            json_str = json_str[7:]
        if json_str.startswith("```"):
            json_str = json_str[3:]
        if json_str.endswith("```"):
            json_str = json_str[:-3]
        
        data = json.loads(json_str.strip())
        return SceneBlueprint(**data)
    
    def _synthesize_fallback(self, request: VisualizeRequest) -> SceneBlueprint:
        """Rule-based fallback synthesis"""
        query = request.query.lower()
        
        # Check for known patterns
        if "heart" in query:
            return self._create_heart_scene()
        elif "atom" in query:
            return self._create_atom_scene()
        elif "tree" in query:
            return self._create_tree_scene()
        elif "robot" in query:
            return self._create_robot_scene()
        elif "house" in query or "home" in query:
            return self._create_house_scene()
        elif "snowman" in query:
            return self._create_snowman_scene()
        elif "planet" in query or "solar" in query:
            return self._create_planet_scene()
        elif "dna" in query or "helix" in query:
            return self._create_dna_scene()
        elif "pyramid" in query:
            return self._create_pyramid_scene()
        else:
            return self._create_abstract_scene(request.query)
    
    def _create_heart_scene(self) -> SceneBlueprint:
        """Create a compositional heart (2 spheres + cone)"""
        return SceneBlueprint(
            meta=SceneMeta(name="Heart", description="Compositional geometry: 2 spheres + 1 cone", gpu_status="active"),
            environment=Environment(skyColor="#1a0a1a", bloomIntensity=2.0, ground=True, groundColor="#1a1a2e"),
            lights=[
                Light(type="ambient", color="#ff6b9d", intensity=0.5),
                Light(type="directional", position=(5, 10, 5), intensity=1.5, castShadow=True),
                Light(type="point", position=(0, 3, 3), color="#ff1493", intensity=2)
            ],
            primitives=[
                Primitive(id="heart-left", type="sphere", args=[1, 32, 32], 
                         transform=Transform(pos=(-0.7, 2.5, 0)),
                         material=MaterialProps(color="#ff1493", emissive="#ff1493", emissiveIntensity=0.3, metalness=0.3, roughness=0.4)),
                Primitive(id="heart-right", type="sphere", args=[1, 32, 32],
                         transform=Transform(pos=(0.7, 2.5, 0)),
                         material=MaterialProps(color="#ff1493", emissive="#ff1493", emissiveIntensity=0.3, metalness=0.3, roughness=0.4)),
                Primitive(id="heart-bottom", type="cone", args=[1.5, 2.2, 32],
                         transform=Transform(pos=(0, 0.7, 0), rot=(math.pi, 0, 0)),
                         material=MaterialProps(color="#ff1493", emissive="#ff1493", emissiveIntensity=0.3, metalness=0.3, roughness=0.4)),
            ]
        )
    
    def _create_atom_scene(self) -> SceneBlueprint:
        """Create an atom model with nucleus and orbits"""
        primitives = [
            Primitive(id="nucleus", type="sphere", args=[0.8, 32, 32],
                     transform=Transform(pos=(0, 2, 0)),
                     material=MaterialProps(color="#ef4444", emissive="#ef4444", emissiveIntensity=1, metalness=0.9, roughness=0.1)),
        ]
        
        # Add orbits
        for i, (color, angle) in enumerate([("#3b82f6", 0), ("#22c55e", math.pi/3), ("#eab308", -math.pi/3)]):
            primitives.append(Primitive(
                id=f"orbit-{i}", type="torus", args=[2.5, 0.03, 16, 100],
                transform=Transform(pos=(0, 2, 0), rot=(math.pi/2 + angle, angle, 0)),
                material=MaterialProps(color=color, emissive=color, emissiveIntensity=0.5, opacity=0.6, transparent=True)
            ))
        
        return SceneBlueprint(
            meta=SceneMeta(name="Atom Model", description="Educational atom with orbiting electrons", gpu_status="active"),
            environment=Environment(skyColor="#050510", bloomIntensity=2.5, ground=False),
            lights=[
                Light(type="ambient", color="#4f46e5", intensity=0.5),
                Light(type="point", position=(0, 2, 0), color="#ffffff", intensity=3)
            ],
            primitives=primitives
        )
    
    def _create_tree_scene(self) -> SceneBlueprint:
        """Create a simple tree (cylinder trunk + cone foliage)"""
        return SceneBlueprint(
            meta=SceneMeta(name="Tree", description="Simple tree: cylinder trunk + cone foliage", gpu_status="active"),
            environment=Environment(skyColor="#87ceeb", bloomIntensity=0.8, ground=True, groundColor="#228b22"),
            lights=[
                Light(type="ambient", color="#ffffff", intensity=0.6),
                Light(type="directional", position=(5, 10, 5), intensity=1.2, castShadow=True)
            ],
            primitives=[
                Primitive(id="trunk", type="cylinder", args=[0.3, 0.4, 2, 8],
                         transform=Transform(pos=(0, 1, 0)),
                         material=MaterialProps(color="#8b4513", metalness=0.1, roughness=0.9)),
                Primitive(id="foliage-1", type="cone", args=[1.5, 2, 8],
                         transform=Transform(pos=(0, 3, 0)),
                         material=MaterialProps(color="#228b22", metalness=0.1, roughness=0.8)),
                Primitive(id="foliage-2", type="cone", args=[1.2, 1.8, 8],
                         transform=Transform(pos=(0, 4.2, 0)),
                         material=MaterialProps(color="#2e8b2e", metalness=0.1, roughness=0.8)),
                Primitive(id="foliage-3", type="cone", args=[0.9, 1.5, 8],
                         transform=Transform(pos=(0, 5.2, 0)),
                         material=MaterialProps(color="#32cd32", metalness=0.1, roughness=0.8)),
            ]
        )
    
    def _create_robot_scene(self) -> SceneBlueprint:
        """Create a cute robot character"""
        return SceneBlueprint(
            meta=SceneMeta(name="Cute Robot", description="Friendly robot character", gpu_status="active"),
            environment=Environment(skyColor="#0f172a", bloomIntensity=1.8, ground=True, groundColor="#1e293b"),
            lights=[
                Light(type="ambient", color="#64748b", intensity=0.5),
                Light(type="directional", position=(5, 10, 5), intensity=1.5, castShadow=True),
                Light(type="point", position=(0, 4, 3), color="#06b6d4", intensity=2)
            ],
            primitives=[
                # Body
                Primitive(id="body", type="box", args=[2, 2.5, 1.5], transform=Transform(pos=(0, 2.25, 0)),
                         material=MaterialProps(color="#475569", metalness=0.8, roughness=0.3)),
                # Head
                Primitive(id="head", type="box", args=[1.8, 1.5, 1.5], transform=Transform(pos=(0, 4.5, 0)),
                         material=MaterialProps(color="#64748b", metalness=0.8, roughness=0.3)),
                # Eyes
                Primitive(id="eye-left", type="sphere", args=[0.25, 16, 16], transform=Transform(pos=(-0.4, 4.6, 0.8)),
                         material=MaterialProps(color="#22d3ee", emissive="#22d3ee", emissiveIntensity=2)),
                Primitive(id="eye-right", type="sphere", args=[0.25, 16, 16], transform=Transform(pos=(0.4, 4.6, 0.8)),
                         material=MaterialProps(color="#22d3ee", emissive="#22d3ee", emissiveIntensity=2)),
                # Antenna
                Primitive(id="antenna", type="cylinder", args=[0.05, 0.05, 0.6, 8], transform=Transform(pos=(0, 5.5, 0)),
                         material=MaterialProps(color="#94a3b8")),
                Primitive(id="antenna-ball", type="sphere", args=[0.12, 8, 8], transform=Transform(pos=(0, 5.85, 0)),
                         material=MaterialProps(color="#ef4444", emissive="#ef4444", emissiveIntensity=1)),
            ]
        )
    
    def _create_house_scene(self) -> SceneBlueprint:
        """Create a simple house"""
        return SceneBlueprint(
            meta=SceneMeta(name="House", description="Simple house: box base + pyramid roof", gpu_status="active"),
            environment=Environment(skyColor="#87ceeb", bloomIntensity=0.5, ground=True, groundColor="#90ee90"),
            lights=[
                Light(type="ambient", color="#ffffff", intensity=0.6),
                Light(type="directional", position=(10, 15, 5), intensity=1.5, castShadow=True)
            ],
            primitives=[
                # Base
                Primitive(id="house-base", type="box", args=[4, 3, 4], transform=Transform(pos=(0, 1.5, 0)),
                         material=MaterialProps(color="#f5f5dc", metalness=0.1, roughness=0.8)),
                # Roof
                Primitive(id="roof", type="cone", args=[3.5, 2.5, 4], transform=Transform(pos=(0, 4.25, 0), rot=(0, math.pi/4, 0)),
                         material=MaterialProps(color="#8b4513", metalness=0.2, roughness=0.7)),
                # Door
                Primitive(id="door", type="box", args=[1, 2, 0.1], transform=Transform(pos=(0, 1, 2.05)),
                         material=MaterialProps(color="#8b4513", metalness=0.3, roughness=0.6)),
                # Windows
                Primitive(id="window-1", type="box", args=[0.8, 0.8, 0.1], transform=Transform(pos=(-1.2, 2, 2.05)),
                         material=MaterialProps(color="#87ceeb", emissive="#87ceeb", emissiveIntensity=0.2, metalness=0.9, roughness=0.1)),
                Primitive(id="window-2", type="box", args=[0.8, 0.8, 0.1], transform=Transform(pos=(1.2, 2, 2.05)),
                         material=MaterialProps(color="#87ceeb", emissive="#87ceeb", emissiveIntensity=0.2, metalness=0.9, roughness=0.1)),
            ]
        )
    
    def _create_snowman_scene(self) -> SceneBlueprint:
        """Create a snowman (3 stacked spheres)"""
        return SceneBlueprint(
            meta=SceneMeta(name="Snowman", description="Classic snowman: 3 stacked spheres", gpu_status="active"),
            environment=Environment(skyColor="#1a1a2e", bloomIntensity=1.0, ground=True, groundColor="#e8e8e8"),
            lights=[
                Light(type="ambient", color="#cce5ff", intensity=0.5),
                Light(type="directional", position=(5, 10, 5), color="#ffffff", intensity=1.5, castShadow=True)
            ],
            primitives=[
                # Body spheres
                Primitive(id="body-bottom", type="sphere", args=[1.5, 32, 32], transform=Transform(pos=(0, 1.5, 0)),
                         material=MaterialProps(color="#ffffff", metalness=0.1, roughness=0.8)),
                Primitive(id="body-middle", type="sphere", args=[1.1, 32, 32], transform=Transform(pos=(0, 3.5, 0)),
                         material=MaterialProps(color="#ffffff", metalness=0.1, roughness=0.8)),
                Primitive(id="body-head", type="sphere", args=[0.8, 32, 32], transform=Transform(pos=(0, 5, 0)),
                         material=MaterialProps(color="#ffffff", metalness=0.1, roughness=0.8)),
                # Eyes
                Primitive(id="eye-left", type="sphere", args=[0.1, 16, 16], transform=Transform(pos=(-0.25, 5.2, 0.7)),
                         material=MaterialProps(color="#000000")),
                Primitive(id="eye-right", type="sphere", args=[0.1, 16, 16], transform=Transform(pos=(0.25, 5.2, 0.7)),
                         material=MaterialProps(color="#000000")),
                # Nose (carrot)
                Primitive(id="nose", type="cone", args=[0.1, 0.5, 8], transform=Transform(pos=(0, 5, 0.8), rot=(math.pi/2, 0, 0)),
                         material=MaterialProps(color="#ff6600")),
                # Hat
                Primitive(id="hat-brim", type="cylinder", args=[0.9, 0.9, 0.1, 16], transform=Transform(pos=(0, 5.75, 0)),
                         material=MaterialProps(color="#1a1a1a")),
                Primitive(id="hat-top", type="cylinder", args=[0.6, 0.6, 0.8, 16], transform=Transform(pos=(0, 6.2, 0)),
                         material=MaterialProps(color="#1a1a1a")),
            ]
        )
    
    def _create_planet_scene(self) -> SceneBlueprint:
        """Create a planet with rings"""
        return SceneBlueprint(
            meta=SceneMeta(name="Planet", description="Ringed planet like Saturn", gpu_status="active"),
            environment=Environment(skyColor="#000011", bloomIntensity=2.0, ground=False),
            lights=[
                Light(type="ambient", color="#1a1a3e", intensity=0.3),
                Light(type="point", position=(10, 5, 10), color="#ffffff", intensity=3)
            ],
            primitives=[
                Primitive(id="planet", type="sphere", args=[3, 64, 64], transform=Transform(pos=(0, 3, 0)),
                         material=MaterialProps(color="#d4a574", metalness=0.2, roughness=0.8)),
                Primitive(id="ring-1", type="torus", args=[5, 0.8, 2, 100], transform=Transform(pos=(0, 3, 0), rot=(math.pi/3, 0, 0)),
                         material=MaterialProps(color="#c4a060", metalness=0.4, roughness=0.5, opacity=0.8, transparent=True)),
                Primitive(id="ring-2", type="torus", args=[6, 0.5, 2, 100], transform=Transform(pos=(0, 3, 0), rot=(math.pi/3, 0, 0)),
                         material=MaterialProps(color="#a08050", metalness=0.4, roughness=0.5, opacity=0.6, transparent=True)),
            ]
        )
    
    def _create_dna_scene(self) -> SceneBlueprint:
        """Create a DNA double helix"""
        primitives = []
        
        for i in range(20):
            angle = (i / 20) * math.pi * 4
            y = i * 0.5 - 5
            
            # Helix 1
            primitives.append(Primitive(
                id=f"helix-1-{i}", type="sphere", args=[0.2, 16, 16],
                transform=Transform(pos=(math.cos(angle) * 1.5, y + 5, math.sin(angle) * 1.5)),
                material=MaterialProps(color="#06b6d4", emissive="#06b6d4", emissiveIntensity=1)
            ))
            
            # Helix 2
            primitives.append(Primitive(
                id=f"helix-2-{i}", type="sphere", args=[0.2, 16, 16],
                transform=Transform(pos=(math.cos(angle + math.pi) * 1.5, y + 5, math.sin(angle + math.pi) * 1.5)),
                material=MaterialProps(color="#8b5cf6", emissive="#8b5cf6", emissiveIntensity=1)
            ))
            
            # Bridges (every other)
            if i % 2 == 0:
                primitives.append(Primitive(
                    id=f"bridge-{i}", type="cylinder", args=[0.05, 0.05, 3, 8],
                    transform=Transform(pos=(0, y + 5, 0), rot=(0, 0, math.pi/2 + angle)),
                    material=MaterialProps(color="#22d3ee", emissive="#22d3ee", emissiveIntensity=0.5, opacity=0.7, transparent=True)
                ))
        
        return SceneBlueprint(
            meta=SceneMeta(name="DNA Helix", description="Double helix DNA structure", gpu_status="active"),
            environment=Environment(skyColor="#050510", bloomIntensity=2.0, ground=False),
            lights=[
                Light(type="ambient", color="#4f46e5", intensity=0.4),
                Light(type="point", position=(0, 5, 5), color="#06b6d4", intensity=3),
                Light(type="point", position=(0, 5, -5), color="#8b5cf6", intensity=3)
            ],
            primitives=primitives
        )
    
    def _create_pyramid_scene(self) -> SceneBlueprint:
        """Create an Egyptian pyramid"""
        return SceneBlueprint(
            meta=SceneMeta(name="Egyptian Pyramid", description="Great Pyramid with golden cap", gpu_status="active"),
            environment=Environment(skyColor="#1a1520", bloomIntensity=1.5, ground=True, groundColor="#c2956e"),
            lights=[
                Light(type="ambient", color="#ffd700", intensity=0.4),
                Light(type="directional", position=(10, 20, 5), color="#fff5e6", intensity=2, castShadow=True),
                Light(type="point", position=(0, 8, 0), color="#ffd700", intensity=1.5)
            ],
            primitives=[
                Primitive(id="pyramid-main", type="cone", args=[5, 7, 4], 
                         transform=Transform(pos=(0, 3.5, 0), rot=(0, math.pi/4, 0)),
                         material=MaterialProps(color="#d4a84b", metalness=0.4, roughness=0.6)),
                Primitive(id="pyramid-cap", type="cone", args=[0.8, 1.2, 4],
                         transform=Transform(pos=(0, 7.6, 0), rot=(0, math.pi/4, 0)),
                         material=MaterialProps(color="#ffd700", emissive="#ffd700", emissiveIntensity=0.5, metalness=0.9, roughness=0.1)),
                Primitive(id="base", type="box", args=[12, 0.3, 12],
                         transform=Transform(pos=(0, 0.15, 0)),
                         material=MaterialProps(color="#8b7355", metalness=0.2, roughness=0.8)),
            ]
        )
    
    def _create_abstract_scene(self, query: str) -> SceneBlueprint:
        """Create an abstract geometric scene for unknown queries"""
        return SceneBlueprint(
            meta=SceneMeta(name=query.title(), description=f"Abstract visualization of: {query}", gpu_status="active"),
            environment=Environment(skyColor="#0f172a", bloomIntensity=1.8, ground=True, groundColor="#1e293b"),
            lights=[
                Light(type="ambient", color="#6366f1", intensity=0.5),
                Light(type="directional", position=(5, 10, 5), intensity=1.5, castShadow=True),
                Light(type="point", position=(0, 5, 0), color="#8b5cf6", intensity=2)
            ],
            primitives=[
                Primitive(id="core", type="dodecahedron", args=[2],
                         transform=Transform(pos=(0, 3, 0)),
                         material=MaterialProps(color="#8b5cf6", emissive="#8b5cf6", emissiveIntensity=0.3, metalness=0.8, roughness=0.2)),
                Primitive(id="ring-1", type="torus", args=[3, 0.15, 16, 100],
                         transform=Transform(pos=(0, 3, 0), rot=(math.pi/2, 0, 0)),
                         material=MaterialProps(color="#06b6d4", emissive="#06b6d4", emissiveIntensity=0.5, opacity=0.7, transparent=True)),
                Primitive(id="ring-2", type="torus", args=[3.5, 0.1, 16, 100],
                         transform=Transform(pos=(0, 3, 0), rot=(math.pi/3, math.pi/4, 0)),
                         material=MaterialProps(color="#22c55e", emissive="#22c55e", emissiveIntensity=0.5, opacity=0.5, transparent=True)),
            ]
        )
