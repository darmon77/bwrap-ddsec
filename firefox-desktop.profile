#Maintainer "Dennis Andrea Darmon "
#City "Melbourne Australia"
#Contacto @darmon77 
#https://github.com/darmon77/bwrap-ddsec
#bug https://github.com/darmon77/bwrap-ddsec/issues
#Firefox Wayland modo paranoico (todo lo descargado se termina destruyendo al cerrar el navegador )
(exec bwrap \
        --proc /proc \
        --dev /dev \
        --ro-bind /usr /usr \
        --ro-bind /lib /lib \
        --ro-bind "$HOME"/.ICEauthority "$HOME"/.ICEauthority \
        --bind "$HOME"/.cache/mozilla "$HOME"/.cache/mozilla \
        --bind "$HOME"/.mozilla "$HOME"/.mozilla \
        --dev-bind /run/user/1000/pulse /run/user/1000/pulse \
        --unshare-all \
        --share-net \
        firefox "$@")
