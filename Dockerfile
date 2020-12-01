FROM node:10
WORKDIR /usr/src
RUN git clone https://github.com/JackySo-MYOB/code-challenge-3.git app

WORKDIR /usr/src/app
COPY package*.json ./

RUN npm install
COPY . .

EXPOSE 8080
CMD [ "node", "server.js" ]
