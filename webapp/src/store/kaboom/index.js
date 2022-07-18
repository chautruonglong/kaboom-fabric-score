export default {
  namespaced: true,
  state: {
    emails: [],
    rooms: [],
    account: {},
    profile: {},
  },
  mutations: {
    SET_EMAILS(state, val) {
      state.emails = val
    },
    SET_ROOMS(state, val) {
      state.rooms = val
    },
    SET_ACCOUNT(state, val) {
      state.account = val
    },
    SET_PROFILE(state, val) {
      state.profile = val
    }
  }
}
