# PratibimbAI - Educational 3D Engine

<p align="center">
  <img src="https://img.shields.io/badge/React%20Three%20Fiber-3D%20Engine-blue" />
  <img src="https://img.shields.io/badge/Flutter-Mobile%20Shell-02569B" />
  <img src="https://img.shields.io/badge/FastAPI-Backend-009688" />
  <img src="https://img.shields.io/badge/Gemini%201.5%20Pro-AI%20Synthesis-4285F4" />
</p>

> **International Tech Competition Grade** - A seamless pipeline where a Flutter app hosts a local React Three Fiber (R3F) engine, pulling data from a FastAPI server that either finds a GLB or synthesizes a scene via Gemini 1.5 Pro using Compositional Geometry.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Mobile App                        │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              Glassmorphic UI Layer (Rich Dark Theme)        │ │
│  │  ┌─────────────┐  ┌──────────────────┐  ┌──────────────┐   │ │
│  │  │ Search Bar  │  │ Scene Info Panel │  │   Sidebar    │   │ │
│  │  └─────────────┘  └──────────────────┘  └──────────────┘   │ │
│  └─────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 InAppWebView (WebGL Canvas)                  │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │            React Three Fiber Engine                      │ │ │
│  │  │  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐ │ │ │
│  │  │  │ SceneBuilder  │  │ PrimitiveFactory│  │ ModelLoader │ │ │ │
│  │  │  └───────────────┘  └───────────────┘  └──────────────┘ │ │ │
│  │  │  ┌───────────────────────────────────────────────────┐  │ │ │
│  │  │  │            PostProcessing (Bloom, Vignette)        │  │ │ │
│  │  │  └───────────────────────────────────────────────────┘  │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────│──────────────────────────────┘
                                   │ Bridge (postMessage)
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FastAPI Backend                             │
│  ┌─────────────────────┐    ┌─────────────────────────────────┐ │
│  │   SearchService     │    │       SynthesisService          │ │
│  │   (Sketchfab Mock)  │    │   (Gemini 1.5 Pro Integration)  │ │
│  └─────────────────────┘    └─────────────────────────────────┘ │
│                                         │                        │
│                     Compositional Geometry Prompting             │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
pratibimb-ai/
├── src/                          # React Three Fiber Engine
│   ├── App.tsx                   # Main React entry point
│   ├── components/
│   │   ├── UniversalScene.tsx    # Canvas wrapper with post-processing
│   │   ├── SceneBuilder.tsx      # Parses JSON → 3D components
│   │   ├── PrimitiveFactory.tsx  # Maps primitives to R3F meshes
│   │   └── ModelLoader.tsx       # GLTF/GLB loader with useGLTF
│   ├── hooks/
│   │   └── useBridge.ts          # Flutter ↔ React communication
│   ├── store/
│   │   └── sceneStore.ts         # Zustand state management
│   └── types/
│       └── schema.ts             # TypeScript interfaces
│
├── backend/                      # FastAPI Backend
│   ├── main.py                   # API endpoints
│   ├── models.py                 # Pydantic v2 models
│   ├── services.py               # Search & Synthesis services
│   └── requirements.txt          # Python dependencies
│
├── mobile/                       # Flutter Mobile App
│   ├── lib/
│   │   └── main.dart             # Complete Flutter UI
│   └── pubspec.yaml              # Flutter dependencies
│
├── index.html                    # HTML entry with premium CSS
├── package.json                  # React dependencies
└── README.md                     # This file
```

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ and npm
- Python 3.9+
- Flutter 3.0+
- Google API Key (for Gemini 1.5 Pro)

### 1. Build the React Engine

```bash
# Install dependencies
npm install

# Build for production
npm run build

# Output: dist/ folder
```

### 2. Run the FastAPI Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set Gemini API key (optional - uses fallback if not set)
export GOOGLE_API_KEY="your-api-key-here"

# Run server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 3. Build Flutter APK

```bash
cd mobile

# Copy built engine to assets
mkdir -p assets/www
cp -r ../dist/* assets/www/

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

## 📐 Core Data Schema (The Contract)

All components adhere to this JSON schema:

```json
{
  "meta": {
    "name": "Scene Name",
    "description": "Description",
    "gpu_status": "active"
  },
  "environment": {
    "skyColor": "#0f0a1a",
    "fogDensity": 0.02,
    "bloomIntensity": 1.5,
    "ground": true,
    "groundColor": "#1a1a2e"
  },
  "lights": [
    {
      "type": "directional|point|ambient|spot",
      "color": "#ffffff",
      "intensity": 1.5,
      "position": [10, 15, 10],
      "castShadow": true
    }
  ],
  "assets": [
    {
      "id": "model-1",
      "url": "https://example.com/model.glb",
      "pos": [0, 0, 0],
      "scale": [1, 1, 1]
    }
  ],
  "primitives": [
    {
      "id": "sphere-1",
      "type": "sphere",
      "args": [1, 32, 32],
      "transform": {
        "pos": [0, 2, 0],
        "rot": [0, 0, 0],
        "scale": [1, 1, 1]
      },
      "material": {
        "color": "#6366f1",
        "metalness": 0.8,
        "roughness": 0.2,
        "emissive": "#4f46e5",
        "emissiveIntensity": 0.5
      },
      "animate": {
        "rotation": [0, 0.5, 0],
        "float": true,
        "floatIntensity": 0.3
      }
    }
  ]
}
```

### Supported Primitives

| Type | Args |
|------|------|
| `box` | `[width, height, depth]` |
| `sphere` | `[radius, widthSegments, heightSegments]` |
| `cylinder` | `[radiusTop, radiusBottom, height, radialSegments]` |
| `cone` | `[radius, height, radialSegments]` |
| `torus` | `[radius, tubeRadius, radialSegments, tubularSegments]` |
| `capsule` | `[radius, length, capSegments, radialSegments]` |
| `dodecahedron` | `[radius, detail]` |
| `octahedron` | `[radius, detail]` |
| `tetrahedron` | `[radius, detail]` |

## 🎨 Compositional Geometry Examples

Build complex objects from simple primitives:

| Object | Composition |
|--------|-------------|
| **Heart** | 2 spheres (top lobes) + 1 inverted cone (bottom point) |
| **Tree** | 1 cylinder (trunk) + 3 stacked cones (foliage) |
| **Snowman** | 3 stacked spheres (decreasing size) |
| **House** | 1 box (base) + 1 pyramid cone (roof) |
| **Atom** | 1 sphere (nucleus) + 3 torus rings (orbits) + spheres (electrons) |
| **Robot** | Boxes (body, head) + spheres (eyes, joints) + cylinders (limbs) |

## 🌐 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/v1/visualize` | POST | Main synthesis endpoint |
| `/v1/search?query=tree` | GET | Search for GLB models |
| `/v1/demo/{name}` | GET | Get pre-built demo scenes |
| `/v1/validate` | POST | Validate a blueprint |

### Example: Generate a Scene

```bash
curl -X POST http://localhost:8000/v1/visualize \
  -H "Content-Type: application/json" \
  -d '{"query": "a glowing crystal heart", "style": "stylized", "complexity": "medium"}'
```

## 🎯 Competition-Level Features

1. **AI-Powered Synthesis** - Gemini 1.5 Pro with compositional geometry prompting
2. **Premium Visual Effects** - Bloom, Vignette, Contact Shadows
3. **Glassmorphic UI** - Apple-style backdrop blur aesthetic
4. **Rich Dark Theme** - Deep Coffee, Gold, Neon Indigo palette
5. **60fps Mobile Performance** - Optimized WebGL rendering
6. **Bidirectional Bridge** - Seamless Flutter ↔ React communication
7. **Offline Fallback** - Rule-based synthesis when API unavailable
8. **Modular Architecture** - Ready for local LLM integration (Gemma/Qwen)

## 🔧 Configuration

### Environment Variables

```bash
# Backend
GOOGLE_API_KEY=your-gemini-api-key
PORT=8000

# Flutter (in main.dart)
apiBaseUrl=http://your-server:8000
```

### Adding Local LLM Support

The architecture is designed for easy LLM swapping:

```python
# backend/services.py

class LocalLLMService:
    def __init__(self, model_path: str):
        # Load Gemma, Qwen, or other local model
        self.model = load_model(model_path)
    
    async def synthesize(self, prompt: str) -> SceneBlueprint:
        # Same interface as Gemini
        response = self.model.generate(SYSTEM_PROMPT + prompt)
        return parse_blueprint(response)
```

## 📱 Mobile Controls

- **Single finger drag** → Rotate camera
- **Pinch** → Zoom in/out  
- **Two finger drag** → Pan camera
- **Tap sidebar** → Load demo scenes
- **Search bar** → Generate AI scenes

## 📄 License

MIT License - Built for educational purposes.

---

<p align="center">
  <strong>PratibimbAI</strong> - Where Education Meets Immersive 3D
</p>
