# MRTG Docker Container

Source: <https://github.com/LearningToPi/mrtg>

Docker Hub: <https://hub.docker.com/r/learningtopi/mrtg>

## Overview

This is a simple MRTG container running lighttpd.

## Container Environment Variables

| Variable | Options | Default | Description |
| :------- | :------ | :------ | :---------- |
| TZ | Timezone string | /UTC | Fill in the appropriate timezone, i.e. 'America/New_York' |

## Running the container

The following examples can be used to start the container:

    docker run --name mrtg -d -v .../mrtg.cfg:/etc/mrtg/mrtg.cfg:Z -v .../mrtg/data:/var/www/html/mrtg:Z -e TZ=America/New_York -p 0.0.0.0:8000:80/tcp learningtopi/mrtg:latest

The preceding is an example that mounts the `mrtg.cfg` file as well as the data directory from the local file system.

## User Namespaces

If running docker or podman with user namespaces, the uid/gid of the users in the container will map to different uid/gid numbers in the base system.  If you are using docker volumes, this can be safely ignored, however if you are binding to a path outside of the container, care must be taken to apply proper folder ownership / permissions.

Depending on your containerization platform, the namespace use will be different.  Docker and podman are outlined below.

### Docker User Namespaces

> For more information on docker container isolation with a user namespace, please review dockers documentation: <https://docs.docker.com/engine/security/userns-remap/>.  The info here is not intended to be a holistic review of namespaces.

if user namespaces are enabled for docker (generally done by adding `"userns-remap": "default"` to the `/etc/docker/daemon.json` config file), then all container will run under the default `dockremap` account.  The user accounts in the container will be dynamically generated based on the information in the `/etc/subuid` and `/etc/subbgid` files.  The files have the following format:

    [username]:[starting-id]:[number-of-ids]

Both the `/etc/subuid` and `/etc/subgid` files will require an entry for the `dockremap` account (generally they should have the same values).  The starting ID + the number of ID's should not overlap with any other uid / gid range (other entries in `subuid` or `subgid`, or uid ranges for LDAP / Active Directory etc.)  The following example will be used (for both `/etc/subuid` and `/etc/subgid`):

    dockremap:90000:65536

This will start dynamic container ID's at 90000 and allows for up to 65536 (or a max id of 155536).  For each container that is run with userns enabed, the `root` uid in the container will map to uid 90000 in the host operating system.  The uid (or gid) for any user in a container will be the uid in the container added to 90000.

In this container the `mrtg` user is `994`.  In order to ensure proper permissions on the mounted volume, `994` must be added to the 'dockremap' id of `90000`

Example:

    # set the permissions on the mrtg.cfg file (ensure read/write access to the 90994 mrtg account)
    chown 90994: /srv/mrtg/mrtg.cfg
    chmod 0640 mrtg.cfg

    # set the ownership and permissions of the data dir, and make sure files are world readable (required for lighttpd)
    chown 90994: /srv/mrtg/data/ -R
    chmod 0755 /srv/mrtg/data/
    chmod 0644 /srv/mrtg/data/*

    > WARNING!  Docker uses the same remapping for all containers.  This means if you have a uid of 1001 in the vsftpd container, and a uid of 1001 in another container, on the base system these will both map to 91001!  This may be a security concern.  If this is an issue and you cannot use different uid values inside the containers, then you may want to consider podman instead.

### Podman Namespaces

Podman namespaces work similar to docker with one major exception.  Rather than using the `dockremap` user for all remapping, the remapping is based on the user that started the container.  In this case, the `/etc/subuid` and `/etc/subgid` files will need to container an entry for each user that needs to start containers:

    [user1]:100000:65536
    [user2]:165537:65536

User remapping is done different based on the user namespace mode selected (see here for details: <https://www.redhat.com/en/blog/rootless-podman-user-namespace-modes>).

In the default mode (`--userns=""`), the root user in the container will be mapped to the uid of the user that started the container.  

