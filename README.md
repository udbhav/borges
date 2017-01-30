# Borges

A machine for development.

## Local port forwarding

You've got borges running on a remote machine, but would like to
communicate with a development server on port 8080. Run this from your
machine:

    ssh -L 8080:localhost:8080 user@yourserver.com

Now, for the duration of your ssh session, `localhost:8080` in your
browser will be `localhost:8080` on borges.

## Creating a production machine

You'll need to create `data_bags/admins/username.json` using a format
like:

```json
{
  "name": "Your Name",
  "email": "you@example.com",
  "password": "your_password_shadow_hash",
  "id_rsa": "id_rsa_with_line_returns_escaped",
  "id_rsa.pub": "id_rsa.pub_with_line_returns_escaped"
}
```

Generate your password shadow hash using openssl:

    openssl passwd -1 "theplaintextpassword"

Fire up a remote server using your host of choice and then:

```
scp -r ~/Sites/borges root@yourserver.com:/root/borges-bootstrap
ssh root@yourserver.com
/root/borges-bootstrap/provision.sh
```

The above will set up `/root/local_mode_repo` for future chef-client
runs. Do those by running `chef-client -z -o borges` from that
directory.

If you need to update the cookbook run:

    cd /root/borges && berks vendor /root/local_mode_repo/cookbooks && cd /root/local_mode_repo && chef-client -z -o borges

## Running locally

    docker run -it borges /bin/zsh

## TODOS

- tmux confs for each project

