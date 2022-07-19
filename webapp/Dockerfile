FROM node:16.15.0-alpine3.15 AS build
WORKDIR /app
COPY . .
RUN yarn install
RUN yarn build
RUN rm -rf node_modules && \
  NODE_ENV=production yarn install --production=true

FROM node:16.15.0-alpine3.15 AS run
WORKDIR /app
RUN npm i -g serve
COPY --from=build /app/dist ./dist

CMD [ "serve", "-s", "dist" ]
