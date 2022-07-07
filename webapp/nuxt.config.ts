import { defineNuxtConfig } from 'nuxt'
import { resolve } from 'path'

export default defineNuxtConfig({
  ssr: false,
  alias: {
    '@': resolve(__dirname, './'),
    '@utils': resolve(__dirname, './utils'),
    '@store': resolve(__dirname, './store'),
    '@pages': resolve(__dirname, './pages'),
    '@assets': resolve(__dirname, './assets'),
    '@models': resolve(__dirname, './models'),
    '@layouts': resolve(__dirname, './layouts'),
    '@plugins': resolve(__dirname, './plugins'),
    '@services': resolve(__dirname, './services'),
    '@middleware': resolve(__dirname, './middleware'),
    '@components': resolve(__dirname, './components'),
  },
})
