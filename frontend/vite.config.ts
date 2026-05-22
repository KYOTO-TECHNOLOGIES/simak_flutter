import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import tailwindcss from '@tailwindcss/vite'


// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    proxy: {
      '/api': {
        target: 'http://72.61.243.154:8000',
        changeOrigin: true,
        secure: false,
        configure: (proxy) => {
          // Prevent the proxy from buffering request bodies (fixes multipart/form-data corruption)
          proxy.on('proxyReq', (proxyReq, req) => {
            // If the request has a content-length, trust it and don't re-process
            if (req.headers['content-length']) {
              proxyReq.setHeader('content-length', req.headers['content-length']);
            }
          });
        },
      }
    }
  }
})
