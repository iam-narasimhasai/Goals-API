FROM node:14

WORKDIR /app

COPY package*.json .

RUN npm install

COPY . .

ENV MONGO_URL mongodb://localhost:27017/course-goals

ENV PORT 321

EXPOSE ${PORT}

CMD ["node","app.js"]