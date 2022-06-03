## Vault 오프라인 설치과정


### 필요파일

1. consul binary
2. vault binary
3. vautl-secret-gen binary
4. Consul Members 
    - "10.13.42.101" (Server1)
    - "10.13.42.102" (Server2)
    - "10.13.42.103" (Server3)
    - "10.13.42.201" (Client1, Vault Server Active)
    - "10.13.42.202" (Client2, Vault Server Standby)


### 포트

|Source|Destination|port|protocol|Direction|Purpose|
|------|---|---|
|Client machines|Load balancer|443|tcp|incoming|Request distribution|
|Load balancer|Vault servers|8200|tcp|incoming|Vault API|
|Vault servers|Vault servers|8200|tcp|bidirectional|Cluster bootstrapping|
|Vault servers|Vault servers|8201|tcp|bidirectional|Raft, replication, request forwarding|
|Consul and Vault servers|Consul servers|8300|tcp|incoming|Consul server RPC|
|Consul and Vault servers|Consul and Vault servers|8301|tcp, udp|bidirectional|Consul LAN gossip|
 

### 참고 사이트

https://docmoa.github.io/04-HashiCorp/04-Consul/02-Configuration/server.html


### Consul Server 1

```console 
$ sudo chown root:root consul 
$ sudo mv consul /usr/local/bin/ 
$ consul --version
$ consul -autocomplete-install
$ sudo useradd --system --home /etc/consul.d --shell /bin/false consul 
$ sudo touch /etc/systemd/system/consul.service
$ sudo vi /etc/systemd/system/consul.service
[Unit] 
Description="HashiCorp Consul - A service mesh solution" 
Documentation=https://www.consul.io/ 
Requires=network-online.target 
After=network-online.target 
ConditionFileNotEmpty=/etc/consul.d/consul.hcl 
[Service] 
EnvironmentFile=-/etc/consul.d/consul.env
User=consul 
Group=consul 
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/ 
ExecReload=/bin/kill --signal HUP $MAINPID 
KillMode=process
KillSignal=SIGTERM
Restart=on-failure 
RestartSec=5
LimitNOFILE=65536
[Install] 
WantedBy=multi-user.target

$ sudo mkdir --parents /etc/consul.d 
$ sudo touch /etc/consul.d/consul.hcl
$ sudo touch /etc/consul.d/consul.env
$ sudo  vi  /etc/consul.d/consul.hcl
data_dir = "/opt/consul" 
bind_addr = "10.13.42.101" 
advertise_addr = "10.13.42.101" 
client_addr = "0.0.0.0" 
bootstrap_expect = 3
node_name = "consul-server-1" 
ui_config {
  enabled = true
}
server = true 
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103"] 
leave_on_terminate = true 
log_level = "INFO" 
datacenter = "dc-wavve" 
enable_syslog = true 
ports {
  http = 8500
  dns = 8600
  https = -1
  serf_lan = 8301
  grpc = 8502
  server = 8300
}
performance {
  raft_multiplier = 1
}
 

$ sudo mkdir -p -m 755 /opt/consul 
$ sudo chown -R consul:consul /opt/consul 
$ sudo chown -R consul:consul /etc/consul.d
$ sudo chown consul:consul /etc/consul.d/consul.hcl
$ sudo chown consul:consul /etc/consul.d/consul.env
$ sudo chmod 640 /etc/consul.d/consul.hcl
$ sudo chmod 640 /etc/consul.d/consul.env

$ sudo systemctl enable consul 
$ sudo systemctl start consul 
$ sudo systemctl status consul
$ consul members
$ consul operator raft list-peers
```


### Consul Server 2

```console
$ sudo chown root:root consul 
$ sudo mv consul /usr/local/bin/ 
$ consul --version
$ consul -autocomplete-install
$ sudo useradd --system --home /etc/consul.d --shell /bin/false consul 
$ sudo touch /etc/systemd/system/consul.service
$ sudo vi /etc/systemd/system/consul.service
[Unit] 
Description="HashiCorp Consul - A service mesh solution" 
Documentation=https://www.consul.io/ 
Requires=network-online.target 
After=network-online.target 
ConditionFileNotEmpty=/etc/consul.d/consul.hcl 
[Service] 
EnvironmentFile=-/etc/consul.d/consul.env
User=consul 
Group=consul 
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/ 
ExecReload=/bin/kill --signal HUP $MAINPID 
KillMode=process
KillSignal=SIGTERM
Restart=on-failure 
RestartSec=5
LimitNOFILE=65536
[Install] 
WantedBy=multi-user.target

$ sudo mkdir --parents /etc/consul.d 
$ sudo touch /etc/consul.d/consul.hcl
$ sudo touch /etc/consul.d/consul.env
$ sudo vi  /etc/consul.d/consul.hcl
data_dir = "/opt/consul" 
bind_addr = "10.13.42.102" 
advertise_addr = "10.13.42.102" 
client_addr = "0.0.0.0" 
bootstrap_expect = 3
node_name = "consul-server-2" 
ui_config {
  enabled = true
}
server = true 
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103"] 
leave_on_terminate = true 
log_level = "INFO" 
datacenter = "dc-wavve" 
enable_syslog = true 
ports {
  http = 8500
  dns = 8600
  https = -1
  serf_lan = 8301
  grpc = 8502
  server = 8300
}
performance {
  raft_multiplier = 1
}
 

$ sudo mkdir -p -m 755 /opt/consul 
$ sudo chown -R consul:consul /opt/consul 
$ sudo chown -R consul:consul /etc/consul.d
$ sudo chown consul:consul /etc/consul.d/consul.hcl
$ sudo chown consul:consul /etc/consul.d/consul.env
$ sudo chmod 640 /etc/consul.d/consul.hcl
$ sudo chmod 640 /etc/consul.d/consul.env

$ sudo systemctl enable consul 
$ sudo systemctl start consul 
$ sudo systemctl status consul
$ consul members
$ consul operator raft list-peers
```

### Consul Server 3

```console
$ sudo chown root:root consul 
$ sudo mv consul /usr/local/bin/ 
$ consul --version
$ consul -autocomplete-install
$ sudo useradd --system --home /etc/consul.d --shell /bin/false consul 
$ sudo touch /etc/systemd/system/consul.service
$ sudo vi /etc/systemd/system/consul.service
[Unit] 
Description="HashiCorp Consul - A service mesh solution" 
Documentation=https://www.consul.io/ 
Requires=network-online.target 
After=network-online.target 
ConditionFileNotEmpty=/etc/consul.d/consul.hcl 
[Service] 
EnvironmentFile=-/etc/consul.d/consul.env
User=consul 
Group=consul 
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/ 
ExecReload=/bin/kill --signal HUP $MAINPID 
KillMode=process
KillSignal=SIGTERM
Restart=on-failure 
RestartSec=5
LimitNOFILE=65536
[Install] 
WantedBy=multi-user.target

$ sudo mkdir --parents /etc/consul.d 
$ sudo touch /etc/consul.d/consul.hcl
$ sudo touch /etc/consul.d/consul.env
$ sudo vi  /etc/consul.d/consul.hcl
data_dir = "/opt/consul" 
bind_addr = "10.13.42.103" 
advertise_addr = "10.13.42.103" 
client_addr = "0.0.0.0" 
bootstrap_expect = 3
node_name = "consul-server-3" 
ui_config {
  enabled = true
}
server = true 
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103"] 
leave_on_terminate = true 
log_level = "INFO" 
datacenter = "dc-wavve" 
enable_syslog = true 
ports {
  http = 8500
  dns = 8600
  https = -1
  serf_lan = 8301
  grpc = 8502
  server = 8300
}
performance {
  raft_multiplier = 1
}

$ sudo mkdir -p -m 755 /opt/consul 
$ sudo chown -R consul:consul /opt/consul 
$ sudo chown -R consul:consul /etc/consul.d
$ sudo chown consul:consul /etc/consul.d/consul.hcl
$ sudo chown consul:consul /etc/consul.d/consul.env
$ sudo chmod 640 /etc/consul.d/consul.hcl
$ sudo chmod 640 /etc/consul.d/consul.env

$ sudo systemctl enable consul 
$ sudo systemctl start consul 
$ sudo systemctl status consul
$ consul members
$ consul operator raft list-peers
```

### Consul Client 1

```console
$ sudo chown root:root consul 
$ sudo mv consul /usr/local/bin/ 
$ consul --version
$ consul -autocomplete-install
$ sudo useradd --system --home /etc/consul.d --shell /bin/false consul 
$ sudo touch /etc/systemd/system/consul.service
$ sudo vi /etc/systemd/system/consul.service
[Unit] 
Description="HashiCorp Consul - A service mesh solution" 
Documentation=https://www.consul.io/ 
Requires=network-online.target 
After=network-online.target 
ConditionFileNotEmpty=/etc/consul.d/consul.hcl 
[Service] 
EnvironmentFile=-/etc/consul.d/consul.env
User=consul 
Group=consul 
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/ 
ExecReload=/bin/kill --signal HUP $MAINPID 
KillMode=process
KillSignal=SIGTERM
Restart=on-failure 
RestartSec=5
LimitNOFILE=65536
[Install] 
WantedBy=multi-user.target

$ sudo mkdir --parents /etc/consul.d 
$ sudo touch /etc/consul.d/consul.hcl
$ sudo touch /etc/consul.d/consul.env
$ sudo vi  /etc/consul.d/consul.hcl
data_dir = "/opt/consul" 
bind_addr = "10.13.42.201"
advertise_addr = "10.13.42.201"
client_addr = "0.0.0.0"
node_name = "consul-client-1"
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103"]
server = false
rejoin_after_leave = true
leave_on_terminate = true
log_level = "INFO"
datacenter = "dc-wavve"
enable_syslog = true
ports {
  http = 8500
  dns = 8600
  https = -1
  serf_lan = 8301
  grpc = 8502
  server = 8300
}


$ sudo mkdir -p -m 755 /opt/consul 
$ sudo chown -R consul:consul /opt/consul 
$ sudo chown -R consul:consul /etc/consul.d
$ sudo chown consul:consul /etc/consul.d/consul.hcl
$ sudo chown consul:consul /etc/consul.d/consul.env
$ sudo chmod 640 /etc/consul.d/consul.hcl
$ sudo chmod 640 /etc/consul.d/consul.env

$ sudo systemctl enable consul 
$ sudo systemctl start consul 
$ sudo systemctl status consul
$ consul members
$ consul operator raft list-peers
```

### Consul Client 2

```console
$ sudo chown root:root consul 
$ sudo mv consul /usr/local/bin/ 
$ consul --version
$ consul -autocomplete-install
$ sudo useradd --system --home /etc/consul.d --shell /bin/false consul 
$ sudo touch /etc/systemd/system/consul.service
$ sudo vi /etc/systemd/system/consul.service
[Unit] 
Description="HashiCorp Consul - A service mesh solution" 
Documentation=https://www.consul.io/ 
Requires=network-online.target 
After=network-online.target 
ConditionFileNotEmpty=/etc/consul.d/consul.hcl 
[Service] 
EnvironmentFile=-/etc/consul.d/consul.env
User=consul 
Group=consul 
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/ 
ExecReload=/bin/kill --signal HUP $MAINPID 
KillMode=process
KillSignal=SIGTERM
Restart=on-failure 
RestartSec=5
LimitNOFILE=65536
[Install] 
WantedBy=multi-user.target

$ sudo mkdir --parents /etc/consul.d 
$ sudo touch /etc/consul.d/consul.hcl
$ sudo touch /etc/consul.d/consul.env
$ sudo vi  /etc/consul.d/consul.hcl
data_dir = "/opt/consul" 
bind_addr = "10.13.42.202"
advertise_addr = "10.13.42.202"
client_addr = "0.0.0.0"
node_name = "consul-client-2"
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103"]
server = false
rejoin_after_leave = true
leave_on_terminate = true
log_level = "INFO"
datacenter = "dc-wavve"
enable_syslog = true
ports {
  http = 8500
  dns = 8600
  https = -1
  serf_lan = 8301
  grpc = 8502
  server = 8300
}

$ sudo mkdir -p -m 755 /opt/consul 
$ sudo chown -R consul:consul /opt/consul 
$ sudo chown -R consul:consul /etc/consul.d
$ sudo chown consul:consul /etc/consul.d/consul.hcl
$ sudo chown consul:consul /etc/consul.d/consul.env
$ sudo chmod 640 /etc/consul.d/consul.hcl
$ sudo chmod 640 /etc/consul.d/consul.env

$ sudo systemctl enable consul 
$ sudo systemctl start consul 
$ sudo systemctl status consul
$ consul members
$ consul operator raft list-peers
```





 
