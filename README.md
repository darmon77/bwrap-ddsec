Bwrap-ddsec
==========
Perfile de sandboxing sin privilegios para bubblewrap 



Muchas herramientas de tiempo de ejecución de contenedores, como systemd-nspawn, dockeretc., se centran en proporcionar infraestructura para administradores de sistemas y herramientas de orquestación (por ejemplo, Kubernetes) para ejecutar contenedores.

Estas herramientas no son adecuadas para dárselas a usuarios sin privilegios, porque es trivial convertir dicho acceso en un shell raíz con privilegios completos en el host.

Espacios de nombres de usuario
---------------
Existeun sistema de aislamiento a nivel del kernel Linux llamado "user namespaces" [espacios de nombres de usuario](https://www.google.com/search?q=user+namespaces+site%3Ahttps%3A%2F%2Flwn.net) que intenta permitir que los usuarios sin privilegios utilicen las funciones del contenedor. Si bien se ha logrado un progreso significativo, todavía existen [preocupaciones al respecto](https://lwn.net/Articles/673597/) y no está disponible para usuarios sin privilegios en varias distribuciones de producción como CentOS / Red Hat Enterprise Linux 7, Debian Jessie, etc.

Consulte, por ejemplo, [CVE-2016-3135](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-3135), que es una vulnerabilidad de raíz local introducida por los usuarios. Esta [publicación de marzo de 2016](https://lkml.org/lkml/2016/3/9/555) tiene más discusión.

Bubblewrap podría verse como una implementación de conjunto de un subconjunto de espacios de nombres de usuario. Énfasis en el subconjunto - específicamente relevante para el CVE anterior, bubblewrap no permite el control sobre iptables.

El código original de bubblewrap existía antes de los espacios de nombres de usuario: hereda el código de [xdg-app helper](https://cgit.freedesktop.org/xdg-app/xdg-app/tree/common/xdg-app-helper.c) que, a su vez, se deriva de forma distante de [linux-user-chroot](https://git.gnome.org/browse/linux-user-chroot) .

Seguridad
--------
Los mantenedores de esta herramienta creen que, incluso cuando se usa en combinación con el software típico instalado en esa distribución, no permite la escalada de privilegios. Sin embargo, puede aumentar la capacidad de un usuario que ha iniciado sesión para realizar ataques de denegación de servicio.

En particular, bubblewrap se utiliza PR_SET_NO_NEW_PRIVS para desactivar los binarios de setuid, que es la [forma tradicional](https://en.wikipedia.org/wiki/Chroot#Limitations) de salir de cosas como chroots.

Usuarios
--------
Este programa puede ser compartido por todas las herramientas de contenedor que realizan operaciones no root, como:

[Flatpak](http://www.flatpak.org/)
[rpm-ostree sin privilegios](https://github.com/projectatomic/rpm-ostree/pull/209)
[bwrap-oci](https://github.com/projectatomic/bwrap-oci)
También nos gustaría que esto estuviera disponible en los clústeres de Kubernetes / OpenShift. Tener la capacidad de que los usuarios sin privilegios utilicen las funciones del contenedor facilitaría significativamente la realización de escenarios de depuración interactivos y similares.

Uso
--------
bubblewrap funciona creando un espacio de nombres de montaje nuevo, completamente vacío, donde la raíz está en un tmpfs que es invisible para el host, y se limpiará automáticamente cuando finalice el último proceso. A continuación, puede utilizar las opciones de la línea de comandos para construir el sistema de archivos raíz y el entorno de proceso y el comando para ejecutar en el espacio de nombres.

Hay una [secuencia](https://github.com/containers/bubblewrap/blob/master/demos/bubblewrap-shell.sh) de [comandos de demostración](https://github.com/containers/bubblewrap/blob/master/demos/bubblewrap-shell.sh) más grande en el código fuente, pero aquí hay una versión reducida que ejecuta un nuevo shell reutilizando el archivo /usr.

bwrap --ro-bind /usr /usr --symlink usr/lib64 /lib64 --proc /proc --dev /dev --unshare-pid bash
Este es un ejemplo incompleto, pero útil con fines ilustrativos. Más a menudo, en lugar de crear un contenedor utilizando el árbol del sistema de archivos del host, desea apuntar a un chroot. Allí, en lugar de crear el enlace simbólico lib64 -> usr/lib64en los tmpfs, es posible que ya lo haya creado en los rootfs de destino.

Sandboxing
--------
El objetivo de bubblewrap es ejecutar una aplicación en una caja de arena, donde tiene acceso restringido a partes del sistema operativo o datos del usuario, como el directorio de inicio.

bubblewrap siempre crea un nuevo espacio de nombres de montaje, y el usuario puede especificar exactamente qué partes del sistema de archivos deben estar visibles en la caja de arena. Cualquiera de estos directorios que especifique se montará nodevde forma predeterminada y se puede hacer de solo lectura.

Además, puede utilizar estas funciones del kernel:

[Espacios de](http://linux.die.net/man/2/clone) nombres de usuario ( [CLONE_NEWUSER](http://linux.die.net/man/2/clone) ): esto oculta todo menos el uid y gid actuales del sandbox. También puede cambiar cuál debería ser el valor de uid / gid en la caja de arena.

[Espacios de](http://linux.die.net/man/2/clone) nombres de IPC ( [CLONE_NEWIPC](http://linux.die.net/man/2/clone) ): la caja de arena obtendrá su propia copia de todas las diferentes formas de IPC, como la memoria compartida SysV y los semáforos.

[Espacios de](http://linux.die.net/man/2/clone) nombres PID ( [CLONE_NEWPID](http://linux.die.net/man/2/clone) ): el sandbox no verá ningún proceso fuera del sandbox. Además, bubblewrap ejecutará un pid1 trivial dentro de su contenedor para manejar los requisitos de cosechar niños en la caja de arena. Esto evita lo que ahora se conoce como el [problema Docker pid 1](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/) .

[Espacios de]()http://linux.die.net/man/2/clone nombres de red ( [CLONE_NEWNET](http://linux.die.net/man/2/clone) ): el sandbox no verá la red. En su lugar, tendrá su propio espacio de nombres de red con solo un dispositivo de bucle invertido.

[Espacio de](http://linux.die.net/man/2/clone) nombres de UTS ( [CLONE_NEWUTS](http://linux.die.net/man/2/clone) ): la caja de arena tendrá su propio nombre de host.

Filtros seccomp: puede pasar filtros seccomp que limitan las llamadas al sistema que se pueden realizar en la zona de pruebas. Para obtener más información, consulte [Seccomp](https://en.wikipedia.org/wiki/Seccomp) .

Comparación de proyectos relacionados: Firejail
----------------------------------------
[Firejail](https://github.com/netblue30/firejail/tree/master/src/firejail) es similar a Flatpak antes de que bubblewrap se dividiera en el sentido de que combina una herramienta setuid con muchas funciones de sandboxing específicas de escritorio. Por ejemplo, Firejail conoce Pulseaudio, mientras que bubblewrap no.

Los autores de bubblewrap creen que es mucho más fácil auditar un pequeño programa setuid y mantener características como el filtrado de Pulseaudio como un proceso sin privilegios, como ocurre ahora en Flatpak.

Además, @cgwalters piensa que tratar de incluir en [la lista blanca las rutas de los archivos](https://github.com/netblue30/firejail/blob/37a5a3545ef6d8d03dad8bbd888f53e13274c9e5/src/firejail/fs_whitelist.c#L176) es una mala idea dadas las innumerables formas en que los usuarios tienen que manipular las rutas y las innumerables formas en que los administradores del sistema pueden configurar un sistema. El enfoque de bubblewrap es retener solo algunas capacidades específicas de Linux como CAP_SYS_ADMIN, pero siempre acceder al sistema de archivos como el uid de invocación. Esto cierra por completo los [ataques TOCTTOU](https://cwe.mitre.org/data/definitions/367.html) y [demás](https://cwe.mitre.org/data/definitions/367.html) .

Comparación de proyectos relacionados: Sandstorm.io
---------------------------------------
[Sandstorm.io](https://sandstorm.io/) requiere espacios de nombres de usuarios sin privilegios para configurar su caja de arena, aunque también podría adaptarse fácilmente para operar en un modo setuid. @cgwalters cree que su código es bastante bueno, pero aún podría tener sentido unificar en bubblewrap. Sin embargo, @kentonv (de Sandstorm) siente que si bien esto tiene sentido en principio, el costo de cambio supera los beneficios prácticos por ahora. Esta decisión podría reevaluarse en el futuro, pero hoy no se está aplicando activamente.

Comparación de proyectos relacionados: runc / binctr
---------------------------------------
[runC](https://github.com/opencontainers/runc) está trabajando actualmente en el soporte de [contenedores](https://github.com/opencontainers/runc/pull/774) sin [raíz](https://github.com/opencontainers/runc/pull/774) , sin necesidad setuidni ningún otro privilegio durante la instalación de runC (usando espacios de nombres de usuarios sin privilegios en lugar de setuid), creación y administración de contenedores. Sin embargo, el modo estándar de usar runC es similar a [systemd nspawn](https://www.freedesktop.org/software/systemd/man/systemd-nspawn.html) en que está diseñado para ser invocado por root.

Los autores de bubblewrap creen que runc y systemd-nspawn no están diseñados para convertirse en setuid, y están lejos de admitir tal modo. Sin embargo, con contenedores sin raíz, runC podrá cumplir con ciertos casos de uso que admite bubblewrap (con el beneficio adicional de ser un tiempo de ejecución OCI completo y estandarizado).

[binctr](https://github.com/jfrazelle/binctr) es solo una envoltura para runC, por lo que hereda todas sus compensaciones de diseño.

[ Bubblewrap https://github.com/containers/bubblewrap](https://github.com/containers/bubblewrap)
---------------------------------------

