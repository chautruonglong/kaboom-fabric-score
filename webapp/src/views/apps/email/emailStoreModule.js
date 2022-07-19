import axios from '@axios'
import { getUserData } from '@/auth/utils'

const baseUrl = process.env.VUE_APP_API_URL

export default {
  namespaced: true,
  state: {},
  getters: {},
  mutations: {},
  actions: {
    fetchEmails(ctx, payload) {
      const userData = getUserData()
      payload = {
        ...payload,
        accountId: userData.id
      }

      return new Promise((resolve, reject) => {
        axios
          .get(`${baseUrl}/mails`, { params: payload })
          .then(response => resolve(response))
          .catch(error => reject(error))
      })
    },
    updateEmail(ctx, payload) {
      return new Promise((resolve, reject) => {
        axios
          .patch(`${baseUrl}/mails/change-status/${payload.mailId}`, {
            status: payload.status
          })
          .then(response => resolve(response))
          .catch(error => reject(error))
      })
    },
    updateEmailLabels(ctx, payload) {
      return new Promise((resolve, reject) => {
        axios
          .post('/apps/email/update-emails-label', payload)
          .then(response => resolve(response))
          .catch(error => reject(error))
      })
    },
    paginateEmail(ctx, payload) {
      return new Promise((resolve, reject) => {
        axios
          .get('/apps/email/paginate-email', { params: payload })
          .then(response => resolve(response))
          .catch(error => reject(error))
      })
    },
  },
}
