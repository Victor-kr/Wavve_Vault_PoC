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


### Credential

- Unseal Key 1: GNxKYsnACporCzHmujTBqhWwfBcQwZdqQfsgpOaMWkdU
- Unseal Key 2: qADOqgFnHhLH2/OxVOSOJxkTwwYgD1LweKVtW/ZKBE9D
- Unseal Key 3: Wxsui8/Zii2UGQuy0VdVFXZpFVR3nIT5PGM9zNssi9eA
- Unseal Key 4: NK37Kt6PSD1AvnEvBG91P8/ugiiax0SHzaWcJuT1Ay/A
- Unseal Key 5: 1PyIUDuMzpTvRtrbiBBPWBz0RnusFJKbYcDLpxoWGeSh
- Initial Root Token: hvs.VHgNnWCSdvyJRLSU3cQEDMLA


### 포트

|Source|Destination|port|protocol|Direction|Purpose|
|------|---|---|---|---|---|
|Client machines|Load balancer|443|tcp|incoming|Request distribution|
|Load balancer|Vault servers|8200|tcp|incoming|Vault API|
|Vault servers|Vault servers|8200|tcp|bidirectional|Cluster bootstrapping|
|Vault servers|Vault servers|8201|tcp|bidirectional|Raft, replication, request forwarding|
|Consul and Vault servers|Consul servers|8300|tcp|incoming|Consul server RPC|
|Consul and Vault servers|Consul and Vault servers|8301|tcp, udp|bidirectional|Consul LAN gossip|


### 필요 파일 전달

```
scp -i ~/.ssh/poc-test.pem -pv ~/consul ubuntu@10.13.42.101:/home/ubuntu/consul
scp -i ~/.ssh/poc-test.pem -pv ~/consul ubuntu@10.13.42.102:/home/ubuntu/consul
scp -i ~/.ssh/poc-test.pem -pv ~/consul ubuntu@10.13.42.103:/home/ubuntu/consul
scp -i ~/.ssh/poc-test.pem -pv ~/vault ubuntu@10.13.42.201:/home/ubuntu/vault
scp -i ~/.ssh/poc-test.pem -pv ~/vault  ubuntu@10.13.42.202:/home/ubuntu/vault
scp -i ~/.ssh/poc-test.pem -pv ~/vault-secrets-gen ubuntu@10.13.42.201:/home/ubuntu/vault-secrets-gen
scp -i ~/.ssh/poc-test.pem -pv ~/vault-secrets-gen ubuntu@10.13.42.202:/home/ubuntu/vault-secrets-gen
```


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


### Vault Server Active (Consul Client 1)

```console
$ sudo chown root:root vault
$ sudo mv vault /usr/local/bin/ 
$ vault --version
$ vault  -autocomplete-install
$ complete -C /usr/local/bin/vault vault
$ sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

$ sudo useradd --system --home /etc/vault.d --shell /bin/false vault
$ sudo touch /etc/systemd/system/vault.service
$ sudo vi /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=notify
EnvironmentFile=/etc/vault.d/vault.env
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target

$ sudo mkdir --parents /etc/vault.d 
$ sudo mkdir  --parents /etc/vault/plugins
$ sudo chown  -R vault:vault /etc/vault/plugins
$ sudo chmod 777 /etc/vault/plugins

$ sudo touch /etc/vault.d/vault.hcl
$ sudo touch /etc/vault.d/vault.env
$ sudo vi  /etc/vault.d/vault.hcl
storage  "consul" {
  address = "127.0.0.1:8500"
  path = "vault/"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "10.13.42.201:8201"
  tls_disable = "true"
}

"ui" = true

plugin_directory="/etc/vault/plugins"
disable_mlock = true
default_lease_ttl = "768h"
max_lease_ttl = "768h"
api_addr = "http://10.13.42.201:8200"
cluster_addr = "http://10.13.42.201:8201"

service_registration "consul" {
  address = "127.0.0.1:8500"
}

$ sudo chown -R vault:vault /etc/vault.d
$ sudo chown vault:vault /etc/vault.d/vault.hcl
$ sudo chown vault:vault /etc/vault.d/vault.env
$ sudo chmod 640 /etc/vault.d/vault.hcl
$ sudo chmod 640 /etc/vault.d/vault.env

$ sudo systemctl enable vault
$ sudo systemctl start vault
$ sudo systemctl status vault
$ export VAULT_ADDR="http://10.13.42.201:8200"
$ vault status 
$ vault operator init
Unseal Key 1: GNxKYsnACporCzHmujTBqhWwfBcQwZdqQfsgpOaMWkdU
Unseal Key 2: qADOqgFnHhLH2/OxVOSOJxkTwwYgD1LweKVtW/ZKBE9D
Unseal Key 3: Wxsui8/Zii2UGQuy0VdVFXZpFVR3nIT5PGM9zNssi9eA
Unseal Key 4: NK37Kt6PSD1AvnEvBG91P8/ugiiax0SHzaWcJuT1Ay/A
Unseal Key 5: 1PyIUDuMzpTvRtrbiBBPWBz0RnusFJKbYcDLpxoWGeSh

Initial Root Token: hvs.VHgNnWCSdvyJRLSU3cQEDMLA
...
$ vault operator unseal
```

### Vault Server Standby (Consul Client 2)

```console
$ sudo chown root:root vault
$ sudo mv vault /usr/local/bin/ 
$ vault --version
$ vault  -autocomplete-install
$ complete -C /usr/local/bin/vault vault
$ sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

$ sudo useradd --system --home /etc/vault.d --shell /bin/false vault
$ sudo touch /etc/systemd/system/vault.service
$ sudo vi /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=notify
EnvironmentFile=/etc/vault.d/vault.env
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target

$ sudo mkdir --parents /etc/vault.d 
$ sudo mkdir  --parents /etc/vault/plugins
$ sudo chown  -R vault:vault /etc/vault/plugins
$ sudo chmod 777 /etc/vault/plugins

$ sudo touch /etc/vault.d/vault.hcl
$ sudo touch /etc/vault.d/vault.env
$ sudo vi  /etc/vault.d/vault.hcl
storage  "consul" {
  address = "127.0.0.1:8500"
  path = "vault/"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "10.13.42.202:8201"
  tls_disable = "true"
}

"ui" = true

plugin_directory="/etc/vault/plugins"
disable_mlock = true
default_lease_ttl = "768h"
max_lease_ttl = "768h"
api_addr = "http://10.13.42.202:8200"
cluster_addr = "http://10.13.42.202:8201"

service_registration "consul" {
  address = "127.0.0.1:8500"
}

$ sudo chown -R vault:vault /etc/vault.d
$ sudo chown vault:vault /etc/vault.d/vault.hcl
$ sudo chown vault:vault /etc/vault.d/vault.env
$ sudo chmod 640 /etc/vault.d/vault.hcl
$ sudo chmod 640 /etc/vault.d/vault.env

$ sudo systemctl enable vault
$ sudo systemctl start vault
$ sudo systemctl status vault
$ export VAULT_ADDR="http://10.13.42.202:8200"
$ vault status 
...
$ vault operator unseal
```

### 플러그인 설치

- Vault Server Active (Consul Client 1)

```console
$ sudo mv vault-secrets-gen /etc/vault/plugins/
$ sudo chown -R vault:vault /etc/vault/plugins/vault-secrets-gen
$ sudo setcap cap_ipc_lock=+ep /etc/vault/plugins/vault-secrets-gen
$ sudo chmod 777 /etc/vault/plugins/vault-secrets-gen
$ export VAULT_ADDR="http://10.13.42.201:8200"
$ vault login
$ export SHA256=$(shasum -a 256 "/etc/vault/plugins/vault-secrets-gen" | cut -d' ' -f1)
$ vault plugin register -sha256="${SHA256}" -command="vault-secrets-gen" secret secrets-gen
$ vault secrets enable  -path="gen" -plugin-name="secrets-gen" plugin
```

- Vault Server Standby (Consul Client 2)

```console
$ sudo mv vault-secrets-gen /etc/vault/plugins/
$ sudo chown -R vault:vault /etc/vault/plugins/vault-secrets-gen
$ sudo setcap cap_ipc_lock=+ep /etc/vault/plugins/vault-secrets-gen
$ sudo chmod 777 /etc/vault/plugins/vault-secrets-gen
$ export VAULT_ADDR="http://10.13.42.202:8200"
$ vault login
$ export SHA256=$(shasum -a 256 "/etc/vault/plugins/vault-secrets-gen" | cut -d' ' -f1)
$ vault plugin register -sha256="${SHA256}" -command="vault-secrets-gen" secret secrets-gen
```

### File 로그 활성화

```console
//Active Server 에서 실행해야 됨
$ export VAULT_ADDR="http://10.13.42.202:8200"
$ vault login
$ sudo mkdir -p /var/log/vault
$ sudo touch /var/log/vault/vault_audit.log 
$ sudo chown vault:vault /var/log/vault/vault_audit.log
$ vault audit enable -path=file1 file file_path=/var/log/vault/vault_audit.log
$ vault audit list 
$ sudo tail -f /var/log/vault/vault_audit.log | jq
```

### 참고 사이트

https://docmoa.github.io/04-HashiCorp/04-Consul/02-Configuration/server.html
