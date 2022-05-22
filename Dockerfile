FROM ubuntu:20.04

# set arguments
ARG GIT_BRANCH=main
ARG GIT_REPO
ARG PROJECT_NAME
ARG SSH_PRIVATE_KEY
# install dependencies
RUN apt-get update
RUN apt-get -y install git
RUN apt-get -y install curl
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get -y install nodejs
RUN node  -v
RUN npm -v
RUN npm install -g @angular/cli@9.0.7
RUN npm install pm2 -g

WORKDIR /

RUN echo ${SSH_PRIVATE_KEY}

RUN mkdir /root/.ssh
RUN pwd
RUN touch /root/.ssh/id_rsa
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN chmod 700 /root/.ssh/id_rsa

RUN ssh-keyscan github.com >> /root/.ssh/known_hosts


# create a new user and add to www-data group
RUN useradd -g www-data angular
# clone django project
RUN mkdir /home/apps && mkdir /home/apps/${PROJECT_NAME}
WORKDIR /home/apps/$PROJECT_NAME
RUN git clone $GIT_REPO . -b $GIT_BRANCH
RUN ls
RUN npm i
RUN ng build --prod
RUN npm i -g pm2
RUN npm run build:ssr

EXPOSE 4000
