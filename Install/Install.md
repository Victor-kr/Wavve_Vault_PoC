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
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103","10.13.42.201","10.13.42.202"] 
leave_on_terminate = true 
log_level = "INFO" 
datacenter = "dc-wavve" 
enable_syslog = true 
ports { 
  grpc = 8502 
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
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103","10.13.42.201","10.13.42.202"] 
leave_on_terminate = true 
log_level = "INFO" 
datacenter = "dc-wavve" 
enable_syslog = true 
ports { 
  grpc = 8502 
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
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103","10.13.42.201","10.13.42.202"] 
leave_on_terminate = true 
log_level = "INFO" 
datacenter = "dc-wavve" 
enable_syslog = true 
ports { 
  grpc = 8502 
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
node_name = "consul-client-1"
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103","10.13.42.201","10.13.42.202"]
leave_on_terminate = true
log_level = "INFO"
datacenter = "dc-wavve"
enable_syslog = true
ports {
  grpc = 8502
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
node_name = "consul-client-2"
retry_join = ["10.13.42.101","10.13.42.102","10.13.42.103","10.13.42.201","10.13.42.202"]
leave_on_terminate = true
log_level = "INFO"
datacenter = "dc-wavve"
enable_syslog = true
ports {
  grpc = 8502
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





 
