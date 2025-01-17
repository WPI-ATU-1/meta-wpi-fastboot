WPI i.MX Fast Boot Meta-Layer
=======================

This layer creates custom images with Falcon Mode enabled in U-Boot. Full description of this method can be found in [AN14093](https://www.nxp.com.cn/docs/en/application-note/AN14093.pdf).

It supports the **OP-Gyro** (i.MX93). 

Yocto Image
-----------
Follow the below instructions for building the image.

#### Download the Yocto Project BSP

```sh
repo init -u https://github.com/WPI-ATU-1/wpi-manifest.git -b imx-linux-scarthgap -m imx-6.6.23-2.0.0.xml
repo sync
```

#### Get the meta-imx-fastboot Meta-layer

Clone the meta-wpi-fastboot Meta-layer into your sources directory

```sh
cd sources
git clone git@github.com:WPI-ATU-1/meta-wpi-fastboot.git
```

#### Setup the build folder
	
```sh
DISTRO=fsl-imx-wayland MACHINE=<machine_name> source sources/meta-wpi-fastboot/tools/imx-setup-fastboot.sh -b <build_dir>
```

Where ```<machine_name>``` is:
- **opgyro-fastboot**  			    for OP-Gyro (i.MX93)

Example:

```sh
DISTRO=fsl-imx-xwayland MACHINE=opgyro-fastboot source sources/meta-wpi-fastboot/tools/imx-setup-fastboot.sh -b build-L6.6.23-opgyro-full-fastboot
```

#### Build the fastboot image

```sh
bitbake imx-image-fastboot
```

#### Prepare the kernel device tree

To boot in Falcon Mode, the kernel device tree must be fixed up in U-Boot.

Boot the board using the image built at the previous step, and stop it in U-Boot.

Run the following command:

```sh
u-boot => run prepare_fdt
```

This command creates the ```<board>-falcon.dtb```, which is saved automatically in the FAT partition of the SD card. **You only need to run this command once.**

This device tree will be used by SPL to boot in Falcon Mode.

Any subsequent time you boot the board, it will automatically start in Falcon Mode. You can fall back to U-Boot by keeping any key pressed during power on.

#### Result
```bash!
U-Boot SPL 2024.04+g674440bc73e+p0 (Jun 06 2024 - 10:05:34 +0000)
SOC: 0xa1009300
LC: 0x2040010
PMIC: PCA9451A
PMIC: Over Drive Voltage Mode
DDR: 3733MTS
M33 prepare ok
Normal Boot
Trying to boot from MMC2
NOTICE:  TRDC init done
NOTICE:  BL31: v2.10.0  (release):automotive-14.0.0_2.1.0-dirty
NOTICE:  BL31: Built : 10:04:22, May 29 2024
[    0.113304] imx93-ldb soc@0:ldb@4ac10020: Failed to create device link (0x180) with 4ae30000.lcd-controller
[    0.149032] qoriq_thermal 44482000.tmu: invalid range data.
[    0.281384] imx93-ldb soc@0:ldb@4ac10020: Failed to create device link (0x180) with soc@0:phy@4ac10024
[    0.347140] rtc-rs5c372 2-0032: hctosys: unable to read the hardware clock
[    0.417495] ov5640 0-003c: ov5640_read_reg: error: reg=300a
[    0.423070] ov5640 0-003c: ov5640_check_chip_id: failed to read chip identifier
[    0.431966] imx93-ldb soc@0:ldb@4ac10020: Failed to create device link (0x180) with lvds_panel

NXP i.MX Release Distro 6.6-scarthgap opgyro ttyLP0

opgyro login: 
```

![image](https://github.com/WPI-Ray/meta-wpi-fastboot/blob/lf-6.6.23-2.0.0/OP-Gyro%20Fast%20Boot%20Log%20Compare.gif)
