#Maintainer "Dennis Andrea Darmon "
#City "Melbourne Australia"
#Contacto @darmon77 
#https://github.com/darmon77/bwrap-ddsec
#bug https://github.com/darmon77/bwrap-ddsec/issues
#Chromium Wayland modo paranoico (todo lo descargado se termina destruyendo al cerrar el navegador )
(exec bwrap \
        --proc /proc \
        --dev /dev \
        --ro-bind /usr /usr \
        --ro-bind /bin /bin \
        --ro-bind /lib /lib \
        --ro-bind /tmp/.X11-unix /tmp/.X11-unix \
        --ro-bind /run/dbus/system_bus_socket /run/dbus/system_bus_socket \
        --ro-bind "$HOME"/.ICEauthority "$HOME"/.ICEauthority \
        --bind "$HOME"/.cache/chromium "$HOME"/.cache/chromium \
        --bind "$HOME"/.config/chromium "$HOME"/.config/chromium \
        --dev-bind /run/user/1000/pulse /run/user/1000/pulse \
        --unshare-all \
        --share-net \
        chromium "$@")
