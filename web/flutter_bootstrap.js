{{flutter_js}}
{{flutter_build_config}}

// Elección del motor de dibujo:
// - WebAssembly ("skwasm") sólo si la página está "aislada" (servida por
//   HTTPS con los encabezados COOP/COEP) y NO es Safari. Es lo más rápido.
// - En cualquier otro caso (HTTP en la red local, Safari/iPhone)
//   JavaScript + CanvasKit, que es lo más compatible. Safari se quedaba en
//   la pantalla de carga con WebAssembly servido por HTTP.
const isSafari = /^((?!chrome|android|crios|fxios).)*safari/i.test(navigator.userAgent);
const useWasm = self.crossOriginIsolated === true && !isSafari;

_flutter.loader.load({
  config: {
    renderer: useWasm ? 'skwasm' : 'canvaskit',
  },
});
