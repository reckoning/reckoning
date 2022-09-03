import { ref } from 'vue'
import { defineStore } from 'pinia'
import { sessions } from '@/frontend/api'

export default defineStore(
  'auth',
  () => {
    const authenticated = ref(false)

    function login() {
      authenticated.value = true
    }

    async function logout() {
      authenticated.value = false

      try {
        await sessions.deleteSession()
      } catch (_error) {
        // console.error(error)
      }
    }

    return { authenticated, login, logout }
  },
  {
    persist: true,
  }
)
