#!/bin/bash

copy_qt_libs_for_binary()
{
    echo "Copying Qt libs for binary $1 to $2"

    qt_libs=$(ldd $1 | grep Qt)

    qt_lib=()
    mapfile -t qt_lib <<< "$qt_libs"
    for lib in "${qt_lib[@]}"
    do
        a=( $lib )
        cp -n ${a[2]} $2
        sub_libs=$(ldd ${a[2]} | grep Qt)
        sub_lib=()
        mapfile -t sub_lib <<< "$sub_libs"
        for lib2 in "${qt_lib[@]}"
        do
            a2=( $lib2 )
            cp -n ${a2[2]} $2
        done
    done
}


copy_other_libs_for_binary()
{
    echo "Copying other libs for binary $1 to $2"

    other_libs=$(ldd $1 | grep -v Qt)

    other_lib=()
    mapfile -t other_lib <<< "$other_libs"
    for lib in "${other_lib[@]}"
    do
        a=( $lib )
        count=${#a[@]}
        if ((count > 3)); then
            cp -n ${a[2]} $2
            sub_libs=$(ldd ${a[2]} | grep -v Qt)
            sub_lib=()
            mapfile -t sub_lib <<< "$sub_libs"
            for lib2 in "${other_lib[@]}"
            do
                a2=( $lib2 )
                count2=${#a2[@]}
                if ((count2 > 3)); then
                    cp -n ${a2[2]} $2
                fi
            done
        fi
    done
}


# Run the get_qt_details.sh script to set details of the Qt installation and the architecture
this_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $this_dir/get_qt_details.sh

# Create temp directory to work in when creating the AppImage
rm -rf temp
mkdir temp
cd temp

# Get the AppImage script functions file
wget -q https://github.com/probonopd/AppImages/raw/master/functions.sh -O ./functions.sh
. ./functions.sh

# Create the AppImage directory structure
mkdir -p ser-player.AppDir/usr/bin
mkdir -p ser-player.AppDir/usr/lib/ser-player/libs
mkdir -p ser-player.AppDir/usr/lib/ser-player/platforms
mkdir -p ser-player.AppDir/usr/lib/ser-player/plugins/imageformats
mkdir -p ser-player.AppDir/usr/share/applications
mkdir -p ser-player.AppDir/usr/share/icons/hicolor/128x128/apps
mkdir -p ser-player.AppDir/usr/share/mime/packages

# Copy ser-player executable file into place and strip it
cp ../../bin/ser-player ser-player.AppDir/usr/lib/ser-player/
strip -s ser-player.AppDir/usr/lib/ser-player/ser-player
chmod 0755 ser-player.AppDir/usr/lib/ser-player/ser-player
chrpath -d ser-player.AppDir/usr/lib/ser-player/ser-player

# Copy shell script and wrapper files
cp ../files/ser-player ser-player.AppDir/usr/bin/
cp ../files/ser-player.wrapper ser-player.AppDir/usr/bin/

# Copy files in share directories
cp ../files/share/ser-player.desktop ser-player.AppDir/usr/share/applications/
cp ../files/ser-player.png ser-player.AppDir/usr/share/icons/hicolor/128x128/apps/
cp ../files/share/ser-player.xml ser-player.AppDir/usr/share/mime/packages/

# Copy file into top level of AppDir
cp ../files/AppRun ser-player.AppDir/
cp ../files/ser-player.desktop ser-player.AppDir/
cp ../files/ser-player.png ser-player.AppDir/

# Copy Qt platform plugin to AppDir
cp ${QT_INSTALL_DIR}/plugins/platforms/libqxcb.* ser-player.AppDir/usr/lib/ser-player/platforms/ #TODO

# Copy other Qt plugins to AppDir
cp ${QT_INSTALL_DIR}/plugins/imageformats/libqjpeg.* ser-player.AppDir/usr/lib/ser-player/plugins/imageformats/ #TODO
cp ${QT_INSTALL_DIR}/plugins/imageformats/libqtiff.* ser-player.AppDir/usr/lib/ser-player/plugins/imageformats/ #TODO

# Copy Qt libs to AppDir
copy_qt_libs_for_binary ../../bin/ser-player ser-player.AppDir/usr/lib/ser-player/libs/
copy_qt_libs_for_binary ${QT_INSTALL_DIR}plugins/platforms/libqxcb.so ser-player.AppDir/usr/lib/ser-player/libs/  #TODO

# Strip Qt libs and change permissions
strip -s ser-player.AppDir/usr/lib/ser-player/libs/*
chmod 0644 ser-player.AppDir/usr/lib/ser-player/libs/*

# Copy System libs to AppDir
copy_other_libs_for_binary ../../bin/ser-player ser-player.AppDir/usr/lib/

# Remove excluded libraries
cd ser-player.AppDir/usr/lib/
delete_blacklisted
cd ../../..

# Strip other libs and change permissions
strip -s ser-player.AppDir/usr/lib/lib*
chmod 0644 ser-player.AppDir/usr/lib/lib*


#wget -c "https://github.com/probonopd/AppImageKit/releases/download/5/AppImageAssistant" # (64-bit)
git clone https://github.com/probonopd/AppImageKit.git
./AppImageKit/build.sh

./AppImageKit/AppImageAssistant ./ser-player.AppDir/ ../ser-player-test_${SYS_ARCH}.AppImage

cd ..