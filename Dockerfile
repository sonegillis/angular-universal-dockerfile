FROM ubuntu:20.04

# set arguments
ARG DOMAIN_NAME
ARG GIT_BRANCH=main
ARG GIT_REPO
ARG PROJECT_DIR
ARG SSH_PRIVATE_KEY
# install dependencies
RUN apt-get update
RUN apt-get -y install nginx && apt-get -y install git
RUN apt-get -y install curl
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get -y install nodejs
RUN node  -v
RUN npm -v
RUN npm install -g @angular/cli
RUN npm install pm2 -g

WORKDIR /

RUN echo ${SSH_PRIVATE_KEY}


RUN mkdir root/.ssh
RUN pwd
RUN touch root/.ssh/id_rsa

RUN ls -la root/.ssh/
RUN touch root/.ssh/known_hosts
COPY id_rsa root/.ssh/id_rsa
RUN chmod 700 root/.ssh/id_rsa

RUN  echo "    IdentityFile /root/.ssh/id_rsa" >> /etc/ssh/ssh_config
RUN ssh-keyscan github.com >> root/.ssh/known_hosts

COPY nginx.conf /etc/nginx/sites-available/${DOMAIN_NAME}/
RUN sed -i "s/DOMAIN_NAME/${DOMAIN_NAME}/g" /etc/nginx/sites-available/${DOMAIN_NAME}/nginx.conf
RUN cat /etc/nginx/sites-available/${DOMAIN_NAME}/nginx.conf
RUN ln -s /etc/nginx/sites-available/${DOMAIN_NAME} /etc/nginx/sites-enabled
RUN rm /etc/nginx/sites-enabled/default


# create a new user and add to www-data group
RUN useradd -g www-data sonegillis
# clone django project
RUN mkdir /home/apps
WORKDIR /home/apps
RUN git clone -b $GIT_BRANCH $GIT_REPO
WORKDIR /home/apps/$PROJECT_DIR
RUN node --max_old_space_size=102400 node_modules/@angular/cli/bin/ng build --prod
RUN npm i
RUN npm i -g pm2
RUN npm run build:ssr
RUN cp -r dist/weedstore-desktop/ /var/www/${DOMAIN_NAME}/

WORKDIR /var/www/${DOMAIN_NAME}/server/
EXPOSE 80
EXPOSE 443
ENTRYPOINT ["pm2-runtime", "start", "main.js", "/dev/null"]