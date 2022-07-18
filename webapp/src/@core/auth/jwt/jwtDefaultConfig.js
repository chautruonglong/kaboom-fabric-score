const baseUrl = process.env.VUE_APP_API_URL

export default {
  // Endpoints
  loginEndpoint: `${baseUrl}/accounts/login`,
  registerEndpoint: `${baseUrl}/accounts`,
  refreshEndpoint: `${baseUrl}/sessions/refresh`,
  logoutEndpoint: `${baseUrl}/accounts/{0}/logout`,

  // This will be prefixed in authorization header with token
  // e.g. Authorization: Bearer <token>
  tokenType: 'Bearer',

  // Value of this property will be used as key to store JWT token in storage
  storageTokenKeyName: 'accessToken',
  storageRefreshTokenKeyName: 'refreshToken',
}
