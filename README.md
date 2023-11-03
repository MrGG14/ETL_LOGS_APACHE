# ETL_LOGS_APACHE
El proyecto consiste en la implementación de una ETL que permita monitorizar un conjunto de IPs
y analizar en un clúster Kafka los accesos registrados en el log de un servidor apache. En el proceso
se distinguen tres fases principales:

1. Carga de datos desde las fuentes al cluster Kafka
2. Procesado de los datos mediante ksql
3. Consultas. Generación de resultados

## Carga inicial de datos

Consiste en alimentar el cluster Kafka con los datos del log de un servidor apache. Habrá una única inyección de datos inicial, en un momento concreto, y solamente desde
dos fuentes de datos:
1. un fichero denominado muestra.log que contiene un extracto de los datos de los accesos
registrados en un log de apache durante el año 2022
2. una tabla denominada monitor localizada en una base de datos relacional denominada kafka
que contiene información de las IPs susceptibles de monitorización

### Carga inicial del log
Este proceso consiste en leer el fichero con los registros en formato CLF (Common Log Format) y
procesarlos con el objeto de geoposicionarlos. Para ello se utiliza la herramienta logstash instalada
y configurada en un contenedor Docker del mismo nombre


Más detalladamente, el proceso transcurre conforme a lo siguiente:
logstash recibe datos a través del puerto 50000 de la máquina local. Como parte del material se suministra un script bash que permite enviar los datos al contenedor. A continuación se
muestra un ejemplo de invocación:

{PATH1}/ingest.sh tag {PATH2}/muestra.log localhost 50000

• tag: el código asignado al equipo

• PATH1: carpeta donde se localiza el script

• PATH2: carpeta que contiene los datos de muestra

El procesado de los datos lo determina la configuración en la sección filter del fichero kafka.yml
localizado en la carpeta logstash/pipeline. Básicamente consta de las siguientes operaciones:

• inserción de la etiqueta del código de equipo en el mensaje

• extracción de los campos del registro de acuerdo con el formato HTTPD_COMBINEDLOG

• geolocalización de las IPs utilizando las bases de datos [GeoIP2 de MaxMind](https://dev.maxmind.com/geoip?lang=en)
Una vez que los datos de entrada han sido procesados son enviados a los destinos definidos en la
sección output. En este caso se definen dos destinos para los datos:

• El primer destino provee un registro tipo file dentro del contenedor logstash. El fichero tiene
formato json y se localiza en la ruta /tmp/apache.json y va a permitir extraer fácilmente el
esquema de los datos que produce el filtro. Para esto se recomienda utilizar un parser online
como https://jsonparser.org/.

• El segundo destino es el etiquetado como kafka y contiene todo lo necesario para remitir la
información anterior al topic logstash (creado automáticamente) en el cluster. La Ilustración
2 muestra el campo valor de uno de los mensajes 


Cada mensaje en el tópico contendrá un máximo de 8 etiquetas. Cada
una tendrá el correspondiente desglose. Las etiquetas en el primer nivel responden a lo siguiente:

@timestamp: relativo al tiempo en el que el mensaje fue cargado en el cluster. Los mensajes
permanecen en el cluster un tiempo determinado (depende de la configuración) transcurrido
el cual se eliminan

@version: inyectado por logstash. No es relevante

timestamp: relativo al tiempo del registro en el log de apache

tag: valor de la etiqueta con la cual se cargó el mensaje

user_agent: información del agente de usuario en el log de apache

geoip: información de la ip en el log de apache geoposicionada por logstash

http: datos del protocolo http en el log de apache

url: string del url registrado en log de apache

Como se describe más adelante, la primera acción de la ETL consistirá en cargar los datos recibidos
en el topic logstash en un stream denominado $tag_apache_raw


## Carga de la tabla monitor desde la BD

Esta operación requiere la carga (scripts monitor-ddl.sql y monitor-dml.sql, respectivamente). A
continuación procede definir un conector io.confluent.connect.jdbc.JdbcSourceConnector que
permita inyectar los datos en el cluster. Es importante seguir el esquema de denominación que se
describe en el apartado siguiente. De acuerdo con ello, el nombre del conector tipo JdbcSource
deberá ser $tag-monitor-jdbc-source donde $tag es un código a elegir. 


## Procesamiento en ksql. Esquema de nombrado

Toda la ETL se va a desarrollar utilizando únicamente ksql de manera que se tendrán que definir los
tópicos, streams, tablas y conectores que sean necesarios. Todos ellos deberán atender al esquema
de denominación siguiente:

• los tópicos tendrán el prefijo ibd.$tag.

• los conectores se denominarán $tag-tname-jdbc-source y $tag-tname-jdbc-sink donde
tname es el nombre de la tabla fuente o destino

• streams y tablas atenderán al esquema $tag_nombre. En particular, la ETL comenzará a
partir de un stream denominado $tag_apache_raw que estará ligado al topic logstash. Dado
que los datos en el campo valor de los eventos tienen una estructura plana (todo en una
línea) la primera transformación consistirá precisamente en “desaplanarlos” a fin de obtener
datos anidados estructurados (ver How to query structured data)

• todas las operaciones deberán contemplar la posibilidad de que se produzcan errores durante
la ingestión de los datos en el cluster. En particular, el proceso de geolocalización de IPs
puede fallar o, incluso, puede haber campos vacíos o incorrectos en el log CLF de apache

• fundamental tener en cuenta que en el cluster Kafka de la asignatura al crear streams y/o
tablas la claúsula WITH deberá especificar los valores PARTITIONS=2, REPLICAS=2


## Generación de resultados

### Accesos recurrentes

Este informe debe mostrar información relativa a los accesos correspondientes a IPs y UAIDs que
son objeto de monitorización. Es decir, que aparecen en la tabla monitor cargada en la base de datos
al inicio del proceso. Como muestra la Ilustración 3, el informe incluye el n.º de visitas original (V)
de las IPs monitorizadas y el que resulta de los registros en el log durante el año 2022 (N)


### Accesos desde una UAID

En este caso el informe incluye los registros del log donde figura una UAID concreta (en la
Ilustración 4 es la UAID = 6248c7a654ab4c1061918e0801cb074f5f01983d). Se muestra la última
visita, las listas de method y status_code así como el n.º total de accesos registrados en 2022

### Tabla geoip

Esta operación volcará los datos de las IPs geolocalizadas extraídas del log en la tabla geoip cuya
orden de creación se incluye en el script geoip-ddl.sql. Este paso requiere la definición de un
conector io.confluent.connect.jdbc.JdbcSinkConnector. En particular, el nombre del conector será
$tag-monitor-jdbc-sink y el prefijo del tópico ibd.$tag







