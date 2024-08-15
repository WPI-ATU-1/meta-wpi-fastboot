#!/bin/bash

# PATH
ATF_PATCH="WPI-OP-Gyro-Fast-Boot-ATF-Add-RAM-FDT-address.patch"
UBOOT_PATCH="WPI-OP-Gyro-Fast-Boot-U-Boot-Falcon-Mode-Modified.patch"
MKIMAGE_PATCH="WPI-OP-Gyro-Fast-Boot-mkimge-Falcon-Mode.patch"
KERNEL_PATCH="WPI-OP-Gyro-Fast-Boot-Kernel-Falcon-Mode-Device-Tree.patch"
ATF_TARGET_DIR="tmp/work/opgyro-poky-linux/imx-atf/*/git/"
UBOOT_TARGET_DIR="tmp/work/opgyro-poky-linux/u-boot-imx/*/git/"
IMX_BOOT_DIR="tmp/work/opgyro-poky-linux/imx-boot/*/git/"
KERNEL_DIR="tmp/work/opgyro-poky-linux/linux-imx/*/git/"
DEPLOY_DIR="tmp/deploy/images/opgyro/"

# Check Build Target
if [ "$#" -eq 0 ]; then
    echo "No arguments provided. Defaulting to all ATF, U-Boot and mkimage."
    BUILD_ATF=true
    BUILD_UBOOT=true
    BUILD_IMAGE=true
	BUILD_KERNEL=true
    BUILD_CLEAN=false
elif [ "$1" = "clean" ]; then
    BUILD_CLEAN=true
	Help=false
    if [ "$2" ]; then
        case "$2" in
			"atf")
				BUILD_ATF=true
                BUILD_UBOOT=false
                BUILD_IMAGE=false
				BUILD_KERNEL=false
                ;;
            "uboot")
                BUILD_ATF=false
                BUILD_UBOOT=true
                BUILD_IMAGE=false
				BUILD_KERNEL=false
                ;;
            "mkimage")
                BUILD_ATF=false
                BUILD_UBOOT=false
                BUILD_IMAGE=true
				BUILD_KERNEL=false
                ;;
			"kernel")
                BUILD_ATF=false
                BUILD_UBOOT=false
                BUILD_IMAGE=false
				BUILD_KERNEL=true
                ;;
            *)
                echo "Invalid argument. Use 'atf', 'uboot', 'mkimage', or no argument for all."
                exit 1
                ;;
        esac
    fi
else
    case "$1" in
        "atf")
            BUILD_ATF=true
            BUILD_UBOOT=false
            BUILD_IMAGE=false
			BUILD_KERNEL=false
            BUILD_CLEAN=false
			Help=false
            ;;
        "uboot")
            BUILD_ATF=false
            BUILD_UBOOT=true
            BUILD_IMAGE=false
			BUILD_KERNEL=false
            BUILD_CLEAN=false
			Help=false
            ;;
        "mkimage")
            BUILD_ATF=false
            BUILD_UBOOT=false
            BUILD_IMAGE=true
			BUILD_KERNEL=false
            BUILD_CLEAN=false
			Help=false
            ;;
		"kernel")
            BUILD_ATF=false
            BUILD_UBOOT=false
            BUILD_IMAGE=false
			BUILD_KERNEL=true
            BUILD_CLEAN=false
			Help=false
            ;;
		"help")
			BUILD_ATF=false
            BUILD_UBOOT=false
            BUILD_IMAGE=false
			BUILD_KERNEL=false
            BUILD_CLEAN=false
			Help=true
			;;
        *)
            echo "Invalid argument. Use 'atf', 'uboot', 'kernel', or 'mkimage'."
            exit 1
            ;;
    esac
fi

# ATF
build_atf() {
	# Patch
	if git -C $ATF_TARGET_DIR log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
		echo "patch already exists..."
		cd $ATF_TARGET_DIR || { echo "Directory not found! Exiting."; exit 1; }
    else
		echo "Copying patch file..."
		cp "$ATF_PATCH" $ATF_TARGET_DIR	
		
		echo "Changing directory to the target git repository..."
		cd $ATF_TARGET_DIR || { echo "Directory not found! Exiting."; exit 1; }
	
		echo "Applying patch..."
		git am "$ATF_PATCH"
    fi
	
	# Build
	echo "Building with make..."
	CROSS_COMPILE=aarch64-linux-gnu- make PLAT=imx93 bl31
	
	echo "Build ATF process completed."	
	
	cd - || exit 1
	
	echo "Build ATF process completed."
}

# U-Boot
build_uboot() {
	# Patch
	if git -C $UBOOT_TARGET_DIR log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
		echo "patch already exists..."
		cd $UBOOT_TARGET_DIR || { echo "Directory not found! Exiting."; exit 1; }
	else
		echo "Copying U-Boot patch file..."
		cp "$UBOOT_PATCH" $UBOOT_TARGET_DIR
	
		echo "Changing directory to the U-Boot target git repository..."
		cd $UBOOT_TARGET_DIR || { echo "U-Boot directory not found! Exiting."; exit 1; }
	
		echo "Applying U-Boot patch..."
		git am "$UBOOT_PATCH"
	fi
	
	# Build
	echo "Cleaning U-Boot..."
	make distclean

	echo "Configuring U-Boot..."
	ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- make op_gyro_falcon_defconfig
	
	echo "Building U-Boot..."
	CROSS_COMPILE=aarch64-linux-gnu- make -j $(nproc --all)
	
	cd - || exit 1

	# Copy to imx-boot
	echo "Copying U-Boot output files..."
	cp ${UBOOT_TARGET_DIR}u-boot*.bin ${UBOOT_TARGET_DIR}spl/u-boot-spl*.bin ${IMX_BOOT_DIR}iMX9/

	echo "Copying device tree file..."
	cp ${DEPLOY_DIR}op-gyro.dtb ${IMX_BOOT_DIR}iMX9/
	
	echo "Copying mkimage tool..."
	cp ${UBOOT_TARGET_DIR}tools/mkimage ${IMX_BOOT_DIR}iMX9/
	cd ${IMX_BOOT_DIR}iMX9/
	mv "mkimage" "mkimage_uboot"
	#cp ${UBOOT_TARGET_DIR}tools/mkimage ${IMX_BOOT_DIR}iMX9/
	#mv "${IMX_BOOT_DIR}iMX9/mkimage" "${IMX_BOOT_DIR}iMX9/mkimage_uboot"
	
	cd - || exit 1

	echo "Build U-Boot process completed."
}

# Mkimage
build_image() {
	# Patch
	if git -C $IMX_BOOT_DIR log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
		cd $IMX_BOOT_DIR || { echo "Directory not found! Exiting."; exit 1; }
	else
		echo "Copying MKimage patch file..."
		cp "$MKIMAGE_PATCH" $IMX_BOOT_DIR
		
		echo "Applying MKimage patch..."
		cd $IMX_BOOT_DIR
		git am "$MKIMAGE_PATCH"
	fi
	
	cd - || exit 1
	
	# Build flash_singleboot
	echo "Build flash_singleboot..."
	cd $IMX_BOOT_DIR
	make SOC=iMX9 flash_singleboot 
	
	echo "Build flash_singleboot process completed."
	
	cd - || exit 1
	
	# Build U-Boot.itb
	echo "Build U-Boot.itb..."
	cd ${IMX_BOOT_DIR}iMX9/
	DEK_BLOB_LOAD_ADDR=0x80400000 TEE_LOAD_ADDR=0x96000000 ATF_LOAD_ADDR=0x204e0000 ./mkimage_fit_atf.sh op-gyro.dtb > u-boot.its
	./mkimage_uboot -E -p 0x3000 -f u-boot.its u-boot.itb
	
	echo "Build U-Boot.itb process completed."
	
	cd - || exit 1
	
	## Build Image.itb
	echo "Copying Kernel Image..."
	cp ${DEPLOY_DIR}Image ${IMX_BOOT_DIR}iMX9/
	
	echo "Build Image.itb..."
	cd ${IMX_BOOT_DIR}iMX9/
	ATF_LOAD_ADDR=0x204e0000 KERNEL_LOAD_ADDR=0x80200000 ../mkimage_fit_atf_kernel.sh > Image.its
	./mkimage_uboot -E -p 0x3000 -f Image.its Image.itb
	echo "Build U-Boot.itb process completed."
	
	cd - || exit 1
	
	echo "Build MKimage process completed."
}

build_kernel(){
	# Patch
	if git -C $KERNEL_DIR log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
		cd $KERNEL_DIR || { echo "Directory not found! Exiting."; exit 1; }
	else
		echo "Copying Kernel patch file..."
		cp "$KERNEL_PATCH" $KERNEL_DIR
		
		echo "Applying Kernel patch..."
		cd $KERNEL_DIR
		git am "$KERNEL_PATCH"
	fi
	
	# Build
	if [ -f "arch/arm64/boot/dts/wpi/op-gyro-falcon.dtb" ]; then
		echo "Clean Kernel..."
        rm arch/arm64/boot/dts/wpi/op-gyro-falcon.dtb
    fi
	
	# Build
	echo "Build Kernel..."
	ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make imx_v8_defconfig
	ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make wpi/op-gyro-falcon.dtb
	#ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -j $(nproc --all) all
	
	cd - || exit 1
}

# Reset
build_clean() {
    if [ "$1" = "all" ]; then
        # Clean ATF
        cd $ATF_TARGET_DIR
            if git log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
                echo "Resetting ATF changes..."
                git reset --hard HEAD~1
            else
                echo "No modifications found in imx-atf."
            fi
        cd - || exit 1
		
		# Clean U-Boot
        cd $UBOOT_TARGET_DIR
            if git log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
                echo "Resetting U-Boot changes..."
                git reset --hard HEAD~1
            else
                echo "No modifications found in u-boot-imx."
            fi
        cd - || exit 1

        # Clean MKimage
        cd $IMX_BOOT_DIR
            if git log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
                echo "Resetting MKimage changes..."
                git reset --hard HEAD~1
            else
                echo "No modifications found in imx-mkimage."
            fi
        cd - || exit 1
		
		# Clean Kernel
        cd $KERNEL_DIR
            if git log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
                echo "Resetting Kernel changes..."
                git reset --hard HEAD~1
            else
                echo "No modifications found in linux-imx."
            fi
        cd - || exit 1
    else
        # Single Clean
        case "$1" in
            "atf")
                cd $ATF_TARGET_DIR
                    if git log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
                        echo "Resetting ATF changes..."
                        git reset --hard HEAD~1
                    else
                        echo "No modifications found in imx-atf."
                    fi
                cd - || exit 1
                ;;
            "uboot")
                cd $UBOOT_TARGET_DIR
                    if git log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
                        echo "Resetting U-Boot changes..."
                        git reset --hard HEAD~1
                    else
                        echo "No modifications found in u-boot-imx."
                    fi
                cd - || exit 1
                ;;
            "mkimage")
                cd $IMX_BOOT_DIR
                    if git log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
                        echo "Resetting MKimage changes..."
                        git reset --hard HEAD~1
                    else
                        echo "No modifications found in imx-mkimage."
                    fi
                cd - || exit 1
                ;;	
			"kernel")
				cd $KERNEL_DIR
					if git log | grep -q "WPI: OP-Gyro: Fast Boot:"; then
						echo "Resetting Kernel changes..."
						git reset --hard HEAD~1
					else
						echo "No modifications found in linux-imx."
					fi
				cd - || exit 1
				;;
            *)
                echo "Invalid argument for clean. Use 'atf', 'uboot', 'mkimage', or no argument for all."
                exit 1
                ;;
        esac
    fi
}

Help() {
    echo "Usage: sh ./Build-Fast-Boot.sh [OPTION]"
    echo ""
    echo "Display information about the script and its usage."
    echo ""
    echo "Options:"
    echo "  atf      Single build for imx-atf ."
    echo "  uboot    Single build for u-boot-imx."
    echo "  mkimage  Single build for imx-boot."
	echo "  kernel  Single build for linux-imx."
    echo "  clean    Clean all built components or reset specific components."
    echo "           Use 'clean' without arguments to reset all components."
    echo "           Use 'clean atf' to reset only the ATF component."
    echo "           Use 'clean uboot' to reset only the U-Boot component."
    echo "           Use 'clean mkimage' to reset only the MKimage component."
	echo "           Use 'clean kernel' to reset only the Kernel component."
    echo ""
    echo "Description:"
    echo "This script is designed to assist users in building and managing the Fast Boot process for the OP-Gyro platform."
    echo "You can build individual components or clean up previous builds to ensure a fresh start."
    echo ""
    echo "Examples:"
    echo "  ./Build-Fast-Boot.sh            # Build all components: ATF, U-Boot, and MKimage."
    echo "  ./Build-Fast-Boot.sh atf        # Build only the ATF component."
    echo "  ./Build-Fast-Boot.sh clean      # Clean all built components."
    echo "  ./Build-Fast-Boot.sh clean atf  # Clean only the ATF component."
    echo ""
    echo "Notes:"
    echo "  - Ensure you have the necessary permissions to execute the script."
    echo "  - Running the clean option will reset any uncommitted changes in the specified components."
    echo "  - Make sure to run this script from the correct directory where the build environment is set up."
}

# main
if [ "$BUILD_CLEAN" = true ]; then
    if [ "$2" ]; then
        build_clean "$2"
    else
        build_clean "all"
    fi
else
    if [ "$BUILD_ATF" = true ]; then
        build_atf
    fi
    if [ "$BUILD_UBOOT" = true ]; then
        build_uboot
    fi
    if [ "$BUILD_IMAGE" = true ]; then
        build_image
    fi
	if [ "$BUILD_KERNEL" = true ]; then
        build_kernel
    fi
	if [ "$Help" = true ]; then
        Help
    fi
fi
