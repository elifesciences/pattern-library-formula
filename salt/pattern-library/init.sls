pattern-library-repository:
    builder.git_latest:
        - name: git@github.com:elifesciences/pattern-library.git
        - identity: {{ pillar.elife.projects_builder.key or '' }}
        - rev: {{ salt['elife.rev']() }}
        - branch: {{ salt['elife.branch']() }}
        - target: /srv/pattern-library/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True
        - fetch_pull_requests: True

    file.directory:
        - name: /srv/pattern-library
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - recurse:
            - user
            - group
        - require:
            - builder: pattern-library-repository

pattern-library-public-directory:
    file.directory:
        - name: /srv/pattern-library
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require:
            - pattern-library-repository

npm-install:
    cmd.run:
        - name: npm install
        - cwd: /srv/pattern-library/
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - pattern-library-repository

composer-install:
    cmd.run:
        # to avoid surprise in production, we install the same dependencies
        # everywhere; don't use --no-dev
        - name: composer --no-interaction install
        - cwd: /srv/pattern-library/
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - install-composer
            - pattern-library-repository

make:
    pkg.installed

ruby-dev:
    pkg.installed
        
pattern-library-compass:
    gem.installed:
        - name: compass
        - require:
            - pkg: ruby-dev
            - pkg: make

install-gulp:
    npm.installed:
        - name: gulp-cli
        - require:
            - pkg: nodejs
            - pattern-library-compass

run-gulp:
    cmd.run:
        {% if pillar.elife.env in ['prod', 'ci'] %}
        - name: gulp --environment production
        {% else %}
        - name: gulp
        {% endif %}
        - cwd: /srv/pattern-library/
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - install-gulp
            - npm-install

pattern-library-dependencies:
    cmd.run:
        - name: cp -r ./core/styleguide ./public/
        - cwd: /srv/pattern-library
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - run-gulp

pattern-library-generic-static-website:
    cmd.run:
        - name: php ./core/builder.php -g
        - cwd: /srv/pattern-library
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - pattern-library-dependencies

pattern-library-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/pattern-library.conf
        - source: salt://pattern-library/config/etc-nginx-sites-enabled-pattern-library.conf
        - template: jinja
        - require:
            - nginx-config
            - pattern-library-generic-static-website
        - listen_in:
            - service: nginx-server-service
