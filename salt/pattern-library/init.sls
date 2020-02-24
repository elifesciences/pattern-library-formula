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
        - runas: {{ pillar.elife.deploy_user.username }}
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
