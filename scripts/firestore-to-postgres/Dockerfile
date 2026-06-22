FROM node:20-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY migrate.mjs verify.mjs normalize.mjs schema.sql relational_schema.sql views.sql ./

CMD ["npm", "run", "migrate"]
