FROM node:16-alpine

# Instalar dependências do sistema
RUN apk add --no-cache curl

# Criar diretório da aplicação
WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./
COPY tsconfig.json ./
COPY tslint.json ./

# Instalar dependências
RUN npm install

# Copiar código fonte
COPY src/ ./src/

# Compilar TypeScript
RUN npm run compile

# Expor portas (HTTP e P2P)
EXPOSE 3001 6001

# Comando padrão
CMD ["npm", "start"]
