#!/bin/bash
# 
# install script for setWeblocThumb
# (c) 2009 Ali Rantakari
# 

DN="`dirname \"$0\"`"
THISDIR="`cd \"$DN\"; pwd`"

BINDIR=/usr/local/bin

BINFILE="${THISDIR}/setWeblocThumb"



if [ ! -e "${BINFILE}" ];then
	echo "Error: can not find \"${BINFILE}\". Make sure you're running this script from within the distribution directory (the same directory where setWeblocThumb resides.)"
	exit 1
fi
echo "================================="
echo
echo "This script will install:"
echo
printf "setWeblocThumb executable to: \e[36m${BINDIR}\e[m\n"
echo
echo $'We\'ll need administrator rights to install to this location so \e[33mplease enter your admin password when asked\e[m.'
echo $'\e[1mPress any key to continue installing or Ctrl-C to cancel.\e[m'
read
echo
sudo -v
if [ ! $? -eq 0 ];then echo "error! aborting." >&2; exit 10; fi
echo

echo -n "Creating directories..."
sudo mkdir -p ${BINDIR}
if [ ! $? -eq 0 ];then echo "...error! aborting." >&2; exit 10; fi
echo "done."

echo -n "Installing the binary executable..."
sudo cp -f "${BINFILE}" "${BINDIR}"
if [ ! $? -eq 0 ];then echo "...error! aborting." >&2; exit 10; fi
echo "done."

echo 
echo $'\e[32msetWeblocThumb has been successfully installed.\e[m'
echo

