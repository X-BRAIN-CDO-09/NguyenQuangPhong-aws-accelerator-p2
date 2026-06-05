# Base layer: official Node image, alpine variant for lightness
FROM node:20-alpine

# Working directory inside the image
WORKDIR /app

# Copy depedency manifest file FIRST, on its own
COPY package.json ./

# Install dependencies
RUN npm install --omit=dev

# Copy the rest of the code after
COPY . .

# Port the app listens on (documentation only)
EXPOSE 3000

# CMD to run when container starts
CMD [ "npm", "start" ]

# The core Dockerfile instructions
# FROM — the base image to build on. Every Dockerfile starts with FROM.
# WORKDIR — set the working directory; later commands run in this directory.
# COPY — copy files from the build machine into the image. (There's a more powerful ADD, but it's surprise-prone; prefer COPY.)
# RUN — run a command at build time (install packages, compile...). Each RUN creates a layer.
# ENV — set an environment variable.
# EXPOSE — declare the port the app uses. It's documentation only and doesn't open the port (you still need -p at run).
# CMD — the default command to run when the container starts (runs at run time, not at build time).

# Afterwards, build the app using `docker build -t demo:week8dayB .`
# Then run it using `docker run --rm -p 3000:3000 demo:week8dayB`
