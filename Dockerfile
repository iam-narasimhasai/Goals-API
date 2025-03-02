FROM node:23-alpine3.20

WORKDIR /app

COPY package*.json /app

RUN npm ci --only=production

COPY . .

EXPOSE 3000 

ENV MONGO_URL=mongodb+srv://dileep:secret32412@cluster0.61vv0.mongodb.net/course-goals?retryWrites=true&w=majority&appName=Cluster0


ENV PORT=3000

CMD ["node","app.js"]
