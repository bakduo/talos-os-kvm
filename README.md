Talos OS On KVM only version <= 1.0.x
=======================

Desde hace tiempo por allá en la versión 0.x que vengo observando y probando este genial proyecto que encapsula en un OS Linux todo kubernetes world, a mi forma de ver entre los mejorcito open source que permite gestionar cluster de kubernetes sin tantos vueltas. Claro está y realmente recomendable antes de caer en Talos, es recomendable que el usuario este aggiornado en lo que significa deploy de kubernetes de hardway ya que es la mejor manera en la cual el usuario pueda abordar y entender los puntos que ponen de manifiesto el uso de un API-driven.

Para los que vienen de cloud la tiene más fácil... para los que vienen de OpenStack Genial.. En OpenStack fue satisfactoria la oportunidad de probarlo, desde los upgrades hasta la carga. Tengo que comentar que se necesitan recursos considerables.

Ahora, para los que nos copamos con KVM, sepan que también está disponible. Existe una [documentación](https://www.talos.dev/v1.1/talos-guides/install/virtualized-platforms/kvm/) inicial y para mi  no me alcanzo, de todas formas agradezco el aporte de [AlfadilTabar](https://gist.githubusercontent.com/AlfadilTabar/cf39050c746296aec4cdd4736dcc05e9/raw/1dc5a4bcc35c8e15fd5701f576bbb65eb60f20aa/talos-kvm.sh) ya que al abordar su idea de deploy puede agregar un par de tips y aportar esta próxima documentación.

## TENER EN CUENTA versión 1.2.x

Lamentablemente para la versión 1.2.x no es posible que funcione la misma guía he estado tratando de resolver el probleme pero nada aún en el grupo de matrix no tuve una respuesta aún de una punta del problema.

Detalles del error:

```


ID       kubelet
STATE    Running
HEALTH   OK
EVENTS   [Running]: Health check successful (32s ago)
         [Running]: Started task kubelet (PID 1614) for container kubelet (34s ago)
         [Preparing]: Creating service runner (34s ago)
         [Preparing]: Running pre state (52s ago)
         [Waiting]: Waiting for time sync (54s ago)
         [Waiting]: Waiting for service "cri" to be "up", time sync (55s ago)
         [Waiting]: Waiting for service "cri" to be "up", time sync, network (56s ago)

ID       etcd
STATE    Preparing
HEALTH   ?
EVENTS   [Preparing]: Running pre state (1m33s ago)
         [Waiting]: Waiting for time sync (1m34s ago)
         [Waiting]: Waiting for service "cri" to be "up", time sync (1m35s ago)
         [Waiting]: Waiting for service "cri" to be "up", time sync, network, etcd spec (1m36s ago)


error (user=apiserver-kubelet-client, verb=get, resource=nodes, subresource=proxy)\") has prevented the request from succeeding"}
[ 2486.366403] [talos] kubernetes endpoint watch error {"component": "controller-runtime", "controller": "k8s.EndpointController", "error": "failed to list *v1.Endpoints: Get \"https://192.168.0.211:6443/api/v1/namespaces/default/endpoints?fieldSelector=metadata.name%3Dkubernetes&limit=500&resourceVersion=0\": EOF"}
[ 2537.326673] [talos] controller failed {"component": "controller-runtime", "controller": "k8s.KubeletStaticPodController", "error": "error refreshing pod status: error fetching pod status: an error on the server (\"Authorization error (user=apiserver-kubelet-client, verb=get, resource=nodes, subresource=proxy)\") has prevented the request from succeeding"}
[ 2541.831053] [talos] kubernetes endpoint watch error {"component": "controller-runtime", "controller": "k8s.EndpointController", "error": "failed to list *v1.Endpoints: Get \"https://192.168.0.211:6443/api/v1/namespaces/default/endpoints?fieldSelector=metadata.name%3Dkubernetes&limit=500&resourceVersion=0\": EOF"}
[ 2582.353336] [talos] kubernetes endpoint watch error {"component": "controller-runtime", "controller": "k8s.EndpointController", "error": "failed to list *v1.Endpoints: Get \"https://192.168.0.211:6443/api/v1/namespaces/default/endpoints?fieldSelector=metadata.name%3Dkubernetes&limit=500&resourceVersion=0\": EOF"}

```

Esto ocurre al momento de pasar la configuración del controller

```
./talosctl-v1.2.x apply-config --insecure --nodes 192.168.x.y --file controlplane.yaml
```

Cuando pasamos la configuración ya comienzan los problemas. Esto es siempre y cuando tratemos de utilizar un **LB** de la misma forma que con la versión <= 1.0.x. No inicia el servicio interno en el puerto 6443 por lo tanto el LB no llega a comunicarse con el nodo.


## Configuración a tener en cuenta KVM

- [X] discos SSD deseable. sino >= 7K
- [X] 32G de ram deseable.
- [X] 6 cores deseable.
- [X] Haproxy para balancer de Kubernetes post deploy talos.
- [X] 60G de disco deseable libres.
- [X] Ubuntu 18.04 - 20.04.
- [X] kvm + libvirt + qemu. Todo el paquete clasico para desplegar VM.
- [X] bajar Kubectl misma version sobre la cual trabaja Talos.
- [X] elegir una versión. Actualmente voy a utilizar la 1.0.6, esta misma en la cual llegue con los upgrade, hasta el memomento no llegue a probar la versión 1.1.

## Tips

Baja la versión de talosctl & Kubectl


```
curl -Lo /usr/local/bin/talosctl https://github.com/siderolabs/talos/releases/download/v1.0.6/talosctl-$(uname -s | tr "[:upper:]" "[:lower:]")-amd64

wget -c https://github.com/siderolabs/talos/releases/download/v1.0.6/talos-amd64.iso -O talos-amd64.iso

curl -LO https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl

curl -LO https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl.sha256

check version kubectl download:

echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

```

Generar un red virtual

```
virsh net-dumpxml default > nueva-red.xml

```

Edite el nueva-red.xml, configure los parametros que necesita luego recordar que se debe iniciar, y tratar de dejarla automáico. Esto es necesario porque necesito un DHCP. Si tenemos una red + vlan OK mejor. En mi caso y a fines demostración genero una red virtual. Aunque también sirve como final ya que luego nos permite aislar la red.


```
virsh net-define nueva-red.xml

virsh net-start nueva-red.xml

virsh net-autostart nueva-red.xml

```

configurar HAproxy:

```
frontend k8s_frontend
   bind IP:6443
   mode tcp
   option tcplog
   default_backend k8s_backend
   
backend k8s_backend
   mode tcp
   option tcplog
   balance roundrobin
   option ssl-hello-chk
   option log-health-checks
   option httpchk GET /healthz HTTP/1.1\r\nHost:\ IP
   server k8s_master_1 IP-1:6443 check check-ssl verify none
   server k8s_master_2 IP-2:6443 check check-ssl verify none
   server k8s_master_3 IP-3:6443 check check-ssl verify none

```

Ahora necesito realizar deploy de cada VM para poder seguir configurando:

```
deploy.sh k8s1 "$(get_mac k8s1)" "IP1" &&

sleep 3

deploy.sh k8s2 "$(get_mac k8s2)" "IP2" &&

sleep 3

deploy.sh k8s3 "$(get_mac k8s3)" "IP3" &&

sleep 3

deploy.sh k8s-worker1 "$(get_mac k8s-worker1)" "IP4"

```

El script me permite poder utilizar virt-install de forma tal de parametrizar lo mínimo que necesito para deployar cada vm. Y ser de "wrapper" para el resto que no necesito ver. Dependiendo de nuestro capacidad de hardware en cuestión de minutos deberia estar todo OK. En caso de algún error es casi seguro que se deba al hardware por lo tanto realicen de a uno por vez.

Los próximo es aplicar la configuración de controller y worker. Para ellos antes debemos obtener esa información para editar:

```
talosctl-linux-amd64-v106 gen config "k8s-micluster" "https://IP-LB:6443"

```

Con este comando vamos a ver una lista de ficheros:

 - controlplane.yaml
 - worker.yaml
 - talosconfig

A partir de aquí pueden seguir la [guia](https://www.talos.dev/v1.1/introduction/getting-started/) oficial. Salvo la sección :

```
talosctl apply-config --insecure \
    --nodes 192.168.0.2 \
    --file cp0.yaml

```

Aqui deben tener en cuenta en tipo de virtualización y conocer un poco el contexto y forma que tiene kubernetes, en este caso recomiendo que antes pasen por el stress de hardway ya que es la única manera en la cual ese YAML en lugar de ser un par de lineas complejas se conviertan en poesia simple y sencilla. Deben configurar todo aquello que requieren de forma especifica y particular, por ejemplo: disco, red, ip, dominio etc. Y luego si y solo si están seguros de que esta todo OK apliquen la configuración. Si salen todo OK en cuestión de minutos van a poder ver todo desplegado. En esta parte ya se encuentran en condiciones de probarlo de apoco iniciando por los endpoint.

NOTA: Deben estar seguros que el deploy de la configuración tenga una salida igual a:

```

[   zzzzz ] [talos] service[kubelet](Preparing): Running pre state
[   zzzzz ] [talos] service[etcd](Preparing): Running pre state
[   zzzzz ] [talos] service[trustd](Preparing): Running pre state
[   zzzzz ] [talos] service[trustd](Preparing): Creating service runner
[   zzzzz ] [talos] service[trustd](Running): Started task trustd (PID 1606) for container trustd
[   zzzzz ] [talos] service[trustd](Running): Health check successful

....

 if this node is the first node in the cluster, please run `talosctl bootstrap` against one of the following IPs:
[  zzzzz ] [talos] [direcion ip del nodo]

....


```

Si es así entonces el resto ya sera cuestión de tiempo, caso contrario puede deberse a un tema de recursos. Es muy importante ver los mensajes. Por eso recomiendo que hagan los *apply* de a uno por vez. Mas que nada porq en recurso de IOPS llego a **Writes-MB/s=469.7**


```
Ejemplo de la web:

  talosctl --talosconfig=./talosconfig \
    config endpoint 192.168.0.2 192.168.0.3 192.168.0.4

```

Tener en cuenta que cada ip hace referencia a los nodos... si todo salio Ok entonces

```
  talosctl --talosconfig=./talosconfig \
    --nodes 192.168.0.2 version

```

al ejecutar dicha instrucción deberian ver:

```

Client:
	Tag:         v1.0.6
	SHA:         SHA...
	Built:       
	Go version:  go1.17.11
	OS/Arch:     linux/amd64
Server:
	NODE:        MI IP
	Tag:         v1.0.6
	SHA:         SHA..
	Built:       
	Go version:  go1.17.11
	OS/Arch:     linux/amd64
	Enabled:     RBAC
```

en cada nodo debería ser todo igual salvo las direcciones ip que varian según el nodo claro esta.


Si TODO lo anterior esta OK entonces se esta en condiciones de realizar un bootstrap, esto se debe ejecutar una sola vez...

```
talosctl-linux-amd64-v106 --talosconfig=./talosconfig bootstrap --nodes IP-De-Cualquier-NODO

```

Esta parte puede tomar un tiempo, lo pueden ir siguiendo al progreso de todo por medio de virsh console:

```
virsh console nombre-vm
```

Deberian ver como todo queda OK. Ahora nos queda ver el tema kubernetes config

```

talosctl-linux-amd64-v106 --talosconfig=./talosconfig kubeconfig -n IP kubeconfig.yaml

kubectl --kubeconfig kubeconfig.yaml get nodes

``

Con esto se termina todo lo relacionado al deploy sobre KVM. A partir de aqui ya queda la configuración full de kubernetes.