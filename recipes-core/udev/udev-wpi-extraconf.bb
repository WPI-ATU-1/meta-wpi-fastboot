DESCRIPTION = "WPI ATU WiFi Config"
LICENSE = "CLOSED"

# WPI op-gyro extra configuration udev rules
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
		file://wpi_usb_en.sh"

do_install:prepend () {

    if [ -e "${WORKDIR}/wpi_usb_en.sh" ]; then
        install -d ${D}${sysconfdir}/udev/scripts/
        install -m 0755 ${WORKDIR}/wpi_usb_en.sh ${D}${sysconfdir}/udev/scripts
    fi

}

PACKAGE_ARCH = "${MACHINE_ARCH}"
