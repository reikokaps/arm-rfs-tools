#!/bin/bash
#
# Erzeuge Root-Filesystem für ARM-Geräte (armhf)
# und startet die Basiseinrichtung
#
# Reiko Kaps <rek@ct.de> 2013

BOOTSTRAP=qemu-debootstrap
ARCH=armhf
VARIANT=minbase
DIST=wheezy
MIRROR=http://ftp.de.debian.org/debian
BASEDIR=/mnt/tmp 
EXTRAS="nano,openssh-server,ifupdown,localepurge,netbase,net-tools,isc-dhcp-client,keyboard-configuration"

## sonstiges
bold=`tput bold`
normal=`tput sgr0`

##
# wir brauchen root
[ $UID -ne 0 ] && { 
    echo $bold"Error: We need root privilege!"$normal
    echo "use sudo $0 or something like that."
    exit 1
}

##
# haben wir alles nötige?

[ -z $(which ${BOOTSTRAP}) ] && {
    echo $bold"Error: Can't find  ${BOOTSTRAP}."$normal
    echo "Please run: "
    echo "apt-get install qemu-user-static binfmt-support debootstrap"
    exit 1
}

##
# Hilfe
hilfe() {
cat<<EOF
${bold}Aufruf: $0 bootstrap|go2rootfs|all${normal}

Optionen:
bootstrap ..... erzeugt neue Root-Filesystem unter $BASEDIR
go2rootfs ..... wechselt in das Root-Filesystem unter $BASEDIR
all ........... erzeugt ein Root-Filesystem und wechsel anschließend hinein
clean ......... alles unter $BASEDIR löschen [Vorsicht!]"

EOF
}

##
# alles als TAR-Archiv zusammenpacken
tarball() {
    # übergeordnetes Verzeichnis ermitteln
    local SAVEDIR=$(dirname ${BASEDIR})
    local ARCHIV=rootfs-${ARCH}-$(date +%F-%s).tar.gz

    [ -d ${BASEDIR} ] && {
	echo ${bold}"Erzeuge Schnappschuss-Archiv vom Root-Filesystem"${normal}
	echo "Dateiname: ${SAVEDIR}/${ARCHIV}"
	tar czf ${SAVEDIR}/${ARCHIV} ${BASEDIR}	
    }
}

## 
# alles auf die eingehängte SD-Karte schieben
copy2sd() {
    echo "Diese Funktion wurde noch nicht eingebaut!"
    return # todo

    # wo hängt die SD-Karte???
    echo ${bold}"Bitte geben Sie den Mointpoint der SD-Karte an:"$normal
    read mountpoint
}

##
# Pakete holen, installieren und grundlegend einrichten
bootstrap() {
    ${BOOTSTRAP} --verbose \
	--variant=${VARIANT} \
	--arch=${ARCH} \
	--include=${EXTRAS} \
	${DIST} \
	${BASEDIR} \
	${MIRROR}
}

##
# lege einige Vorgaben fest
# 1. Paketquellen
# 2. fstab/Mountpoints
setup_rootfs() {
    # 1. Paketquellen
    echo ${bold}"Lege Paketquellen fest ..."${normal}
    cat<<EOF>${BASEDIR}/etc/apt/sources.list
deb http://ftp.de.debian.org/debian wheezy main contrib non-free
deb-src http://ftp.de.debian.org/debian wheezy main contrib non-free
deb http://ftp.de.debian.org/debian wheezy-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian wheezy-updates main contrib non-free
deb http://security.debian.org/debian-security wheezy/updates main contrib non-free
deb-src http://security.debian.org/debian-security wheezy/updates main contrib non-free
EOF
    # 2.  fstab
    echo ${bold}"Lege Mountpoints fest ..."${normal}
    cat<<EOF>${BASEDIR}/etc/fstab
none    /tmp    tmpfs   defaults,noatime,mode=1777 0 0
# if you have a separate boot partition
#/dev/mmcblk0p9  /boot   vfat defaults 0 0 
EOF
    # 3. kopiere resolv.conf 
    echo ${bold}"Kopiere resolv.conf ..."${normal}
    cp /etc/resolv.conf ${BASEDIR}/etc/resolv.conf
    # 4. Lege Hostnamen für das Rootfs-System fest
    echo -ne ${bold}"Bitte geben Sie einen Namen für das System ein:"${normal}
    read newname
    echo ${newname} >  ${BASEDIR}/etc/hostname

    # issue anpassen
    cat<<EOF>> ${BASEDIR}/etc/issue
      _ _
  ___( ) |_
 / __|/| __|
| (__  | |_
 \___|  \__|4arm (2014.1)

EOF
    # 5. etc/network/interfaces
    cat<<EOF>>${BASEDIR}/etc/network/interfaces
auto lo
iface lo inet loopback

# eth0 (Der LAN-Port des Minix X5)
iface eth0 inet dhcp
auto eth0

# eth1 (WLAN)
# iface eth1 inet dhcp
# auto eth1
EOF
}

## 
# Pseudodateisysteme einrichten
# und per Chroot ins neue Rootfilesystem wechseln
go2rootfs() {
    mount -t proc proc ${BASEDIR}/proc
    mount -t sysfs sysfs ${BASEDIR}/sys
    mount -o bind /dev ${BASEDIR}/dev
    mount -t devpts devpts ${BASEDIR}/dev/pts
    echo $bold"Wechsele jetzt ins neue Root-Filesystem"$normal
    chroot ${BASEDIR}
    # und wieder alles lösen
    umount ${BASEDIR}/proc
    umount ${BASEDIR}/sys
    umount ${BASEDIR}/dev/pts
    umount ${BASEDIR}/dev
}


###
# Main 

case "$1" in
    bootstrap)
	bootstrap
	setup_rootfs
	;;
    go2rootfs)
	go2rootfs
	exit 0
	;;
    clean)
	echo -ne "Lösche alles unter $BASEDIR ... "
	[ -d ${BASEDIR} ] && rm -r ${BASEDIR}
	echo -ne $bold"[FERTIG]\n"$normal
	;;
    tarball)
	tarball
	;;
    copy2SD)
	copy2sd
	;;
    hilfe)
	hilfe
	;;
    *)
	hilfe
	;;
esac
exit 0
    






