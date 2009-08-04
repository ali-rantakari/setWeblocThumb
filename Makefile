# setWeblocThumb makefile
# 
# Created by Ali Rantakari on 4 Aug, 2009
# 

SHELL=/bin/bash

CURRDATE=$(shell date +"%Y-%m-%d")
SCP_TARGET=$(shell cat ./deploymentScpTarget)







all: setWeblocThumb



#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# generate imgBase64.m with the imgBase64 NSString*
#-------------------------------------------------------------------------
imgBase64.m: webloc.png
	@echo
	@echo ---- Base64-encoding base icon PNG:
	@echo ======================================
	echo -n "NSString *imgBase64 = @\"" > imgBase64.m
	cat webloc.png | openssl base64 -e | tr -d '\n' >> imgBase64.m
	echo "\";" >> imgBase64.m


#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# compile the binary itself
#-------------------------------------------------------------------------
setWeblocThumb: imgBase64.m setWeblocThumb.m MBBase64.m
	@echo
	@echo ---- Compiling:
	@echo ======================================
	gcc -O2 -Wall -force_cpusubtype_ALL -mmacosx-version-min=10.5 -arch i386 -arch ppc -framework Cocoa -framework WebKit -o $@ setWeblocThumb.m MBBase64.m



#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
clean:
	@echo
	@echo ---- Cleaning up:
	@echo ======================================
	-rm -Rf setWeblocThumb
	-rm -Rf imgBase64.m



