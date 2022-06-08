## Vault 설치관련 테스트

Consul 구성을 하기 전에 구성이 가능한지 네트워크 체크후 아래와 같이 테스트 할 수 있다.

### Server

```
$ sudo su
$ mkdir -p -m 777 /root/consul  
$ consul agent -server -bootstrap-expect=1 -node consul-server -bind 10.13.42.101 -client=0.0.0.0 -data-dir=/root/consul
```

### Client

```
$ sudo su
$ mkdir -p -m 777 /root/consul  
$ consul agent -join 10.13.42.101 -node=consul-client -bind 10.13.42.102 -client=0.0.0.0 -data-dir=/root/consul
```

 
