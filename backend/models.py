"""
PratibimbAI Backend - Pydantic v2 Models
Core data schema matching the TypeScript interfaces
"""

from typing import Optional, Literal, List, Tuple
from pydantic import BaseModel, Field
from datetime import datetime

# Type aliases
Vec3 = Tuple[float, float, float]

PrimitiveType = Literal[
    'box', 'sphere', 'cylinder', 'torus', 'cone', 'capsule',
    'plane', 'ring', 'dodecahedron', 'octahedron', 'tetrahedron', 'icosahedron'
]


class MaterialProps(BaseModel):
    """PBR Material properties"""
    color: str = "#8b5cf6"
    metalness: float = Field(default=0.5, ge=0, le=1)
    roughness: float = Field(default=0.5, ge=0, le=1)
    emissive: Optional[str] = None
    emissiveIntensity: float = Field(default=1.0, ge=0)
    opacity: float = Field(default=1.0, ge=0, le=1)
    transparent: bool = False
    wireframe: bool = False


class AnimationProps(BaseModel):
    """Animation properties for primitives"""
    rotateX: Optional[float] = None
    rotateY: Optional[float] = None
    rotateZ: Optional[float] = None
    float_: Optional[bool] = Field(default=None, alias="float")
    floatSpeed: float = 2.0
    floatIntensity: float = 0.5
    
    class Config:
        populate_by_name = True


class Transform(BaseModel):
    """Transform properties"""
    pos: Vec3 = (0, 0, 0)
    rot: Optional[Vec3] = None
    scale: Optional[Vec3] = None


class Primitive(BaseModel):
    """Primitive geometry definition"""
    id: Optional[str] = None
    name: Optional[str] = None
    type: PrimitiveType
    args: List[float]
    transform: Transform
    material: MaterialProps = Field(default_factory=MaterialProps)
    animate: Optional[AnimationProps] = None
    castShadow: bool = True
    receiveShadow: bool = True


class Asset(BaseModel):
    """External GLB/GLTF asset"""
    id: str
    name: Optional[str] = None
    url: str
    pos: Vec3 = (0, 0, 0)
    rot: Optional[Vec3] = None
    scale: Vec3 = (1, 1, 1)
    animate: Optional[AnimationProps] = None


class Light(BaseModel):
    """Light definition"""
    type: Literal['directional', 'point', 'spot', 'ambient']
    color: str = "#ffffff"
    intensity: float = 1.0
    position: Optional[Vec3] = None
    target: Optional[Vec3] = None
    castShadow: bool = False
    angle: Optional[float] = None
    penumbra: Optional[float] = None
    decay: float = 2.0
    distance: float = 0


class Environment(BaseModel):
    """Environment settings"""
    skyColor: str = "#0a0a1a"
    groundColor: str = "#1a1a2e"
    fogColor: Optional[str] = None
    fogDensity: float = 0.02
    fogNear: Optional[float] = None
    fogFar: Optional[float] = None
    bloomIntensity: float = 1.5
    bloomThreshold: float = 0.8
    bloomRadius: float = 0.4
    ambientIntensity: float = 0.4
    ambientColor: str = "#ffffff"
    ground: bool = True
    groundSize: float = 50
    hdri: Optional[str] = None
    contactShadows: bool = True


class SceneMeta(BaseModel):
    """Scene metadata"""
    name: str
    description: Optional[str] = None
    author: Optional[str] = None
    version: str = "1.0.0"
    gpu_status: Literal['active', 'fallback', 'disabled'] = 'active'
    created_at: Optional[datetime] = None
    tags: List[str] = Field(default_factory=list)


class SceneBlueprint(BaseModel):
    """Complete Scene Blueprint - The main contract"""
    meta: SceneMeta
    environment: Environment = Field(default_factory=Environment)
    lights: List[Light] = Field(default_factory=list)
    assets: List[Asset] = Field(default_factory=list)
    primitives: List[Primitive] = Field(default_factory=list)


# Request/Response models
class VisualizeRequest(BaseModel):
    """Request to visualize a concept"""
    query: str = Field(..., min_length=1, max_length=500)
    style: Literal['realistic', 'stylized', 'minimal', 'educational'] = 'educational'
    complexity: Literal['simple', 'medium', 'complex'] = 'medium'


class VisualizeResponse(BaseModel):
    """Response from visualization endpoint"""
    success: bool
    source: Literal['search', 'synthesis', 'cache']
    blueprint: Optional[SceneBlueprint] = None
    glb_url: Optional[str] = None
    error: Optional[str] = None
    processing_time_ms: Optional[float] = None


# Search result model
class SearchResult(BaseModel):
    """Result from model search"""
    id: str
    name: str
    url: str
    thumbnail: Optional[str] = None
    author: Optional[str] = None
    license: Optional[str] = None
