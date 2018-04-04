pattern-library-docker-compose-folder:
    file.directory:
        - name: /home/{{ pillar.elife.deploy_user.username }}/pattern-library/
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require:
            - deploy-user

pattern-library-docker-compose-.env:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/pattern-library/.env
        - source: salt://pattern-library/config/home-deployuser-pattern-library-.env
        - makedirs: True
        - template: jinja
        - require:
            - pattern-library-docker-compose-folder

pattern-library-docker-compose-yml:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/pattern-library/docker-compose.yml
        - source: salt://pattern-library/config/home-deployuser-pattern-library-docker-compose.yml
        - template: jinja
        - require:
            - pattern-library-docker-compose-folder

pattern-library-docker-containers:
    cmd.run:
        - name: |
            /usr/local/bin/docker-compose up --force-recreate -d
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: /home/{{ pillar.elife.deploy_user.username }}/pattern-library
        - require:
            - pattern-library-docker-compose-.env
            - pattern-library-docker-compose-yml

pattern-library-smoke-tests:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/pattern-library/smoke_tests.sh
        - source: salt://pattern-library/config/home-deployuser-pattern-library-smoke_tests.sh
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - mode: 755
        - require:
            - pattern-library-docker-compose-folder

#pattern-library-public-directory:
#    file.directory:
#        - name: /srv/pattern-library
#        - user: {{ pillar.elife.deploy_user.username }}
#        - group: {{ pillar.elife.deploy_user.username }}
#        - require:
#            - pattern-library-repository
#
#pattern-library-deb-dependencies:
#    pkg.installed:
#        - pkgs:
#            - make
#            - ruby-dev
#            - g++
#
#npm-install:
#    cmd.run:
#        - name: npm install
#        - cwd: /srv/pattern-library/
#        - user: {{ pillar.elife.deploy_user.username }}
#        - require:
#            - pattern-library-deb-dependencies
#            - pattern-library-repository
#
#composer-install:
#    cmd.run:
#        # to avoid surprise in production, we install the same dependencies
#        # everywhere; don't use --no-dev
#        - name: composer --no-interaction install
#        - cwd: /srv/pattern-library/
#        - user: {{ pillar.elife.deploy_user.username }}
#        - require:
#            - install-composer
#            - pattern-library-repository
#
#        
#pattern-library-compass:
#    gem.installed:
#        - name: compass
#        - require:
#            - pattern-library-deb-dependencies
#
#install-gulp:
#    npm.installed:
#        - name: gulp-cli
#        - require:
#            - pkg: nodejs
#            - pattern-library-compass
#
#run-gulp:
#    cmd.run:
#        {% if pillar.elife.env in ['prod', 'ci'] %}
#        - name: gulp --environment production
#        {% else %}
#        - name: gulp
#        {% endif %}
#        - cwd: /srv/pattern-library/
#        - user: {{ pillar.elife.deploy_user.username }}
#        - require:
#            - install-gulp
#            - npm-install
#
#pattern-library-public-folder-contents-dependencies:
#    cmd.run:
#        - name: cp -r ./core/styleguide ./public/
#        - cwd: /srv/pattern-library
#        - user: {{ pillar.elife.deploy_user.username }}
#        - require:
#            - run-gulp
#
#pattern-library-generic-static-website:
#    cmd.run:
#        - name: php ./core/builder.php -g
#        - cwd: /srv/pattern-library
#        - user: {{ pillar.elife.deploy_user.username }}
#        - require:
#            - pattern-library-public-folder-contents-dependencies
#            - composer-install

pattern-library-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/pattern-library.conf
        - source: salt://pattern-library/config/etc-nginx-sites-enabled-pattern-library.conf
        - template: jinja
        - require:
            - nginx-config
            - pattern-library-docker-containers
        - listen_in:
            - service: nginx-server-service
