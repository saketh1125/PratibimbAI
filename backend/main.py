"""
PratibimbAI Backend - FastAPI Server
Main API endpoint with Gemini integration for 3D scene synthesis
"""

import os
import time
from typing import Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from models import (
    VisualizeRequest, 
    VisualizeResponse, 
    SceneBlueprint,
    SearchResult
)
from services import SearchService, SynthesisService


# Global services
search_service: Optional[SearchService] = None
synthesis_service: Optional[SynthesisService] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan - initialize and cleanup services"""
    global search_service, synthesis_service
    
    # Initialize services
    print("🚀 Starting PratibimbAI Backend...")
    search_service = SearchService()
    synthesis_service = SynthesisService(
        api_key=os.environ.get("GOOGLE_API_KEY")
    )
    
    if synthesis_service.model:
        print("✅ Gemini 1.5 Pro connected")
    else:
        print("⚠️ Running in fallback mode (no Gemini API key)")
    
    print("✅ PratibimbAI Backend ready!")
    
    yield
    
    # Cleanup
    print("👋 Shutting down PratibimbAI Backend...")


# Create FastAPI app
app = FastAPI(
    title="PratibimbAI API",
    description="Educational 3D Engine Backend - Compositional Geometry Synthesis",
    version="1.0.0",
    lifespan=lifespan
)

# CORS for Flutter WebView and development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to your domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "service": "PratibimbAI",
        "version": "1.0.0",
        "status": "healthy",
        "gemini_connected": synthesis_service.model is not None if synthesis_service else False
    }


@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "services": {
            "search": search_service is not None,
            "synthesis": synthesis_service is not None,
            "gemini": synthesis_service.model is not None if synthesis_service else False
        }
    }


@app.post("/v1/visualize", response_model=VisualizeResponse)
async def visualize(request: VisualizeRequest):
    """
    Main visualization endpoint.
    
    Takes a text query and returns either:
    - A GLB URL if a matching model is found in search
    - A synthesized SceneBlueprint if no model found
    
    The synthesis uses Gemini 1.5 Pro with compositional geometry prompting.
    """
    start_time = time.time()
    
    try:
        # Step 1: Search for existing models
        search_results = search_service.search(request.query)
        
        if search_results:
            # Found a matching GLB model
            result = search_results[0]
            processing_time = (time.time() - start_time) * 1000
            
            return VisualizeResponse(
                success=True,
                source="search",
                glb_url=result.url,
                processing_time_ms=processing_time
            )
        
        # Step 2: No model found, synthesize scene
        blueprint = await synthesis_service.synthesize(request)
        processing_time = (time.time() - start_time) * 1000
        
        return VisualizeResponse(
            success=True,
            source="synthesis",
            blueprint=blueprint,
            processing_time_ms=processing_time
        )
        
    except Exception as e:
        processing_time = (time.time() - start_time) * 1000
        return VisualizeResponse(
            success=False,
            source="synthesis",
            error=str(e),
            processing_time_ms=processing_time
        )


@app.get("/v1/search")
async def search_models(
    query: str = Query(..., min_length=1, max_length=200),
    limit: int = Query(default=10, ge=1, le=50)
):
    """
    Search for 3D models matching the query.
    Returns a list of available GLB models.
    """
    results = search_service.search(query, limit)
    return {
        "query": query,
        "count": len(results),
        "results": [r.model_dump() for r in results]
    }


@app.get("/v1/demo/{scene_name}")
async def get_demo_scene(scene_name: str):
    """
    Get a pre-built demo scene by name.
    Available: heart, atom, tree, robot, house, snowman, planet, dna, pyramid
    """
    # Use the synthesis service's fallback methods directly
    scene_methods = {
        "heart": synthesis_service._create_heart_scene,
        "atom": synthesis_service._create_atom_scene,
        "tree": synthesis_service._create_tree_scene,
        "robot": synthesis_service._create_robot_scene,
        "house": synthesis_service._create_house_scene,
        "snowman": synthesis_service._create_snowman_scene,
        "planet": synthesis_service._create_planet_scene,
        "dna": synthesis_service._create_dna_scene,
        "pyramid": synthesis_service._create_pyramid_scene,
    }
    
    if scene_name.lower() not in scene_methods:
        raise HTTPException(
            status_code=404, 
            detail=f"Demo scene '{scene_name}' not found. Available: {list(scene_methods.keys())}"
        )
    
    blueprint = scene_methods[scene_name.lower()]()
    return blueprint.model_dump()


@app.post("/v1/validate")
async def validate_blueprint(blueprint: SceneBlueprint):
    """
    Validate a SceneBlueprint JSON.
    Returns the validated and normalized blueprint.
    """
    return {
        "valid": True,
        "primitive_count": len(blueprint.primitives),
        "asset_count": len(blueprint.assets),
        "light_count": len(blueprint.lights),
        "blueprint": blueprint.model_dump()
    }


# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail, "status_code": exc.status_code}
    )


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={"error": str(exc), "status_code": 500}
    )


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=True
    )
