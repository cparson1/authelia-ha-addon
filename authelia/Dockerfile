FROM authelia/authelia:4.39.27

COPY defaults/configuration.yml /defaults/configuration.yml
COPY defaults/users_database.yml /defaults/users_database.yml
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
