# Borges

A machine for development.

## Creating a remote machine

You'll need to create `data_bags/admins/username.json` using a format
like:

```json
{
  "name": "Your Name",
  "email": "you@example.com",
  "password": "your_password_shadow_hash",
  "htpasswd": "your_password",
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

    cd /root/borges && berks vendor /root/local_mode_repo/cookbooks \
    && cd /root/local_mode_repo && chef-client -z -o borges

Save custom attributes in a json file and pass them in to chef-client
if you need:

    chef-client -z -o borges -j node.json

## Copy and Paste on Mac

Instructions are taken from https://gist.github.com/burke/5960455.

### Local (OS X) Side

#### `~/Library/LaunchAgents/pbcopy.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>localhost.pbcopy</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/bin/pbcopy</string>
    </array>
    <key>inetdCompatibility</key>
    <dict>
      <key>Wait</key>
      <false/>
    </dict>
    <key>Sockets</key>
    <dict>
      <key>Listeners</key>
      <dict>
        <key>SockServiceName</key>
        <string>2224</string>
        <key>SockNodeName</key>
        <string>127.0.0.1</string>
      </dict>
    </dict>
  </dict>
</plist>
```

#### `~/Library/LaunchAgents/pbpaste.plist`

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>localhost.pbpaste</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/bin/pbpaste</string>
    </array>
    <key>inetdCompatibility</key>
    <dict>
      <key>Wait</key>
      <false/>
    </dict>
    <key>Sockets</key>
    <dict>
      <key>Listeners</key>
      <dict>
        <key>SockServiceName</key>
        <string>2225</string>
        <key>SockNodeName</key>
        <string>127.0.0.1</string>
      </dict>
    </dict>
  </dict>
</plist>
```

#### `~/.ssh/config`

```
Host myhost
    HostName 192.168.1.123
    User myname
    RemoteForward 2224 127.0.0.1:2224
    RemoteForward 2225 127.0.0.1:2225
```

After adding the PLists above, you'll have to run:

```
launchctl load ~/Library/LaunchAgents/pbcopy.plist
launchctl load ~/Library/LaunchAgents/pbpaste.plist
```

### Remote (Linux) Side

#### `~/.tmux.conf

```
bind C-c run "tmux save-buffer - | pbcopy-remote"
bind C-v run "tmux set-buffer $(pbpaste-remote); tmux paste-buffer"
```

#### `~/bin/pbpaste-remote`

```
#!/bin/sh
nc localhost 2225
```

#### `~/bin/pbcopy-remote`

```
#!/bin/sh
cat | nc -q1 localhost 2224
```

## Local port forwarding

You've got borges running on a remote machine, but would like to
communicate with a development server on port 8080. Run this from your
machine:

    ssh -L 8080:localhost:8080 user@yourserver.com

Now, for the duration of your ssh session, `localhost:8080` in your
browser will be `localhost:8080` on borges.

## Running locally

    docker run -it borges /bin/zsh

## TODOS

- tmux confs for each project
- Add docs about editing a node etc.
- Automate config.rb in provision.sh
