import { createApp } from 'vue'
import router from '@/frontend/lib/Router'
import pinia from '@/frontend/lib/Pinia'
import App from '@/frontend/App.vue'

declare global {
  interface Window {
    API_ENDPOINT: string
  }
}

const app = createApp(App)

app.use(router)
app.use(pinia)

app.mount('#app')
