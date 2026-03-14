import { useEffect, useCallback, useRef } from 'react';
import { useSceneStore } from '../store/sceneStore';
import { SceneBlueprint, BridgeMessage, BridgeResponse, GPUInfo } from '../types/schema';

// Declare Flutter interface for TypeScript
declare global {
  interface Window {
    flutter_inappwebview?: {
      callHandler: (name: string, ...args: unknown[]) => Promise<unknown>;
    };
    FlutterChannel?: {
      postMessage: (message: string) => void;
    };
    receiveFromFlutter?: (data: string) => void;
    loadScene?: (json: string) => void;
    loadGLB?: (url: string) => void;
    loadSceneBase64?: (b64: string) => void;
    loadGLBBase64?: (b64: string) => void;
  }
}

export function useBridge() {
  const { setScene, setLoading, setError, setGpuInfo } = useSceneStore();
  const isInitialized = useRef(false);

  // Send message to Flutter
  const sendToFlutter = useCallback((response: BridgeResponse) => {
    const message = JSON.stringify(response);
    
    // Method 1: InAppWebView handler
    if (window.flutter_inappwebview?.callHandler) {
      window.flutter_inappwebview.callHandler('onBridgeMessage', message);
    }
    
    // Method 2: JavaScript channel
    if (window.FlutterChannel?.postMessage) {
      window.FlutterChannel.postMessage(message);
    }
    
    // Method 3: postMessage (for iframe embedding)
    window.parent.postMessage(response, '*');
    
    console.log('[Bridge] Sent to Flutter:', response.type);
  }, []);

  // Handle incoming messages from Flutter
  const handleFlutterMessage = useCallback((data: string | BridgeMessage) => {
    try {
      const message: BridgeMessage = typeof data === 'string' ? JSON.parse(data) : data;
      console.log('[Bridge] Received from Flutter:', message.type);

      switch (message.type) {
        case 'LOAD_SCENE':
          setLoading(true);
          const scene = message.payload as SceneBlueprint;
          setScene(scene);
          setLoading(false);
          sendToFlutter({
            type: 'SCENE_LOADED',
            payload: { 
              name: scene.meta.name,
              primitiveCount: scene.primitives.length,
              assetCount: scene.assets.length
            },
            timestamp: Date.now()
          });
          break;

        case 'LOAD_GLB':
          setLoading(true);
          const glbUrl = message.payload as string;
          // Create a scene with just the GLB asset
          setScene({
            meta: { name: 'GLB Model', description: 'Loaded from URL', gpu_status: 'active' },
            environment: { skyColor: '#1a1a2e', fogDensity: 0.02, bloomIntensity: 1.5, ground: true },
            assets: [{ id: 'main-model', url: glbUrl, pos: [0, 0, 0], scale: [1, 1, 1] }],
            primitives: []
          });
          setLoading(false);
          sendToFlutter({
            type: 'ASSET_LOADED',
            payload: { url: glbUrl },
            timestamp: Date.now()
          });
          break;

        case 'UPDATE_SETTINGS':
          const settings = message.payload as Partial<SceneBlueprint>;
          const currentScene = useSceneStore.getState().currentScene;
          setScene({ ...currentScene, ...settings });
          break;

        case 'RESET_SCENE':
          useSceneStore.getState().resetScene();
          sendToFlutter({
            type: 'SCENE_LOADED',
            payload: { reset: true },
            timestamp: Date.now()
          });
          break;

        default:
          console.warn('[Bridge] Unknown message type:', message.type);
      }
    } catch (error) {
      console.error('[Bridge] Error handling message:', error);
      setError(error instanceof Error ? error.message : 'Unknown error');
      sendToFlutter({
        type: 'ERROR',
        payload: { error: String(error) },
        timestamp: Date.now()
      });
    }
  }, [setScene, setLoading, setError, sendToFlutter]);

  // Initialize GPU info
  const initGpuInfo = useCallback(() => {
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
    
    if (gl) {
      const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
      const gpuInfo: GPUInfo = {
        renderer: debugInfo ? gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) : 'Unknown',
        vendor: debugInfo ? gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL) : 'Unknown',
        maxTextureSize: gl.getParameter(gl.MAX_TEXTURE_SIZE),
        maxViewportDims: gl.getParameter(gl.MAX_VIEWPORT_DIMS) as [number, number],
        webglVersion: gl instanceof WebGL2RenderingContext ? 'WebGL 2.0' : 'WebGL 1.0',
        extensions: gl.getSupportedExtensions() || []
      };
      
      setGpuInfo(gpuInfo);
      sendToFlutter({
        type: 'GPU_INFO',
        payload: gpuInfo as unknown as Record<string, unknown>,
        timestamp: Date.now()
      });
    }
  }, [setGpuInfo, sendToFlutter]);

  // Setup event listeners
  useEffect(() => {
    if (isInitialized.current) return;
    isInitialized.current = true;

    // Initialize GPU info
    initGpuInfo();

    // Method 1: Global function for Flutter to call
    window.receiveFromFlutter = handleFlutterMessage;

    // Method 2: Expose global scene loading functions for evaluateJavascript
    window.loadScene = (jsonString: string) => {
      console.log('[Bridge] loadScene called with:', jsonString.substring(0, 100) + '...');
      try {
        const blueprint = JSON.parse(jsonString);
        console.log('[Bridge] Parsed scene:', blueprint.meta?.name, 'with', blueprint.primitives?.length, 'primitives');
        handleFlutterMessage({
          type: 'LOAD_SCENE',
          payload: blueprint,
          timestamp: Date.now()
        });
      } catch (error) {
        console.error('[Bridge] loadScene error:', error);
      }
    };

    window.loadGLB = (url: string) => {
      handleFlutterMessage({
        type: 'LOAD_GLB',
        payload: url,
        timestamp: Date.now()
      });
    };

    // Base64-encoded variants — Flutter sends base64(utf8(json)) to avoid
    // quote-escaping issues with AI-generated text.
    window.loadSceneBase64 = (b64: string) => {
      try {
        const jsonString = atob(b64);
        const blueprint = JSON.parse(jsonString);
        console.log('[Bridge] loadSceneBase64 decoded:', blueprint.meta?.name);
        handleFlutterMessage({
          type: 'LOAD_SCENE',
          payload: blueprint,
          timestamp: Date.now()
        });
      } catch (error) {
        console.error('[Bridge] loadSceneBase64 error:', error);
      }
    };

    window.loadGLBBase64 = (b64: string) => {
      try {
        const url = atob(b64);
        handleFlutterMessage({
          type: 'LOAD_GLB',
          payload: url,
          timestamp: Date.now()
        });
      } catch (error) {
        console.error('[Bridge] loadGLBBase64 error:', error);
      }
    };

    // Method 2: postMessage listener (for iframe embedding)
    const handlePostMessage = (event: MessageEvent) => {
      if (event.data && typeof event.data === 'object' && 'type' in event.data) {
        handleFlutterMessage(event.data);
      }
    };
    window.addEventListener('message', handlePostMessage);

    // Notify Flutter that engine is ready
    sendToFlutter({
      type: 'BRIDGE_READY',
      payload: { ready: true, version: '1.0.0' },
      timestamp: Date.now()
    });

    console.log('[Bridge] Initialized and ready');

    return () => {
      window.removeEventListener('message', handlePostMessage);
      delete window.receiveFromFlutter;
      delete window.loadScene;
      delete window.loadGLB;
      delete window.loadSceneBase64;
      delete window.loadGLBBase64;
    };
  }, [handleFlutterMessage, initGpuInfo, sendToFlutter]);

  return {
    sendToFlutter,
    handleFlutterMessage
  };
}

// Utility hook for loading scenes from API
export function useApiLoader() {
  const { setScene, setLoading, setError } = useSceneStore();

  const loadFromApi = useCallback(async (query: string, apiUrl: string = '/v1/visualize') => {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query, style: 'realistic', complexity: 'high' })
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }

      const data = await response.json();
      
      if (data.success && data.type === 'procedural') {
        setScene(data.data as SceneBlueprint);
      } else if (data.success && data.type === 'glb') {
        // Handle GLB URL
        setScene({
          meta: { name: query, description: 'Loaded from search', gpu_status: 'active' },
          environment: { skyColor: '#1a1a2e', fogDensity: 0.02, bloomIntensity: 1.5, ground: true },
          assets: [{ id: 'search-result', url: data.data.url, pos: [0, 0, 0], scale: [1, 1, 1] }],
          primitives: []
        });
      }
    } catch (error) {
      console.error('[API] Error loading:', error);
      setError(error instanceof Error ? error.message : 'Failed to load from API');
    } finally {
      setLoading(false);
    }
  }, [setScene, setLoading, setError]);

  return { loadFromApi };
}
