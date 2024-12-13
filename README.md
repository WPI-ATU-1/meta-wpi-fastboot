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
git clone git@github.com:WPI-ATU-1/meta-wpi-fastboot.git
```

#### Setup the build folder
	
```sh
DISTRO=fsl-imx-wayland MACHINE=<machine_name> source sources/meta-wpi-fastboot/tools/imx-setup-fastboot.sh -b <build_dir>
```

Where ```<machine_name>``` is:
- **opgyro-fastboo**  			    for OP-Gyro (i.MX93)

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
