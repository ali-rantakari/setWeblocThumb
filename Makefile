# setWeblocThumb makefile
# 
# Created by Ali Rantakari on 4 Aug, 2009
# 

SHELL=/bin/bash

SCP_TARGET=$(shell cat ./deploymentScpTarget)
APP_VERSION=$(shell grep "^const int VERSION_" setWeblocThumb.m | awk '{print $$NF}' | tr -d ';' | tr '\n' '.' | sed -e 's/.$$//')
VERSION_ON_SERVER=$(shell curl -Ss http://hasseg.org/setWeblocThumb/?versioncheck=y)
TEMP_DEPLOYMENT_DIR=deployment/$(APP_VERSION)
TEMP_DEPLOYMENT_ZIPFILE=$(TEMP_DEPLOYMENT_DIR)/setWeblocThumb-v$(APP_VERSION).zip
TEMP_DEPLOYMENT_USAGEFILE="usage.txt"
VERSIONCHANGELOGFILELOC="$(TEMP_DEPLOYMENT_DIR)/changelog.html"
GENERALCHANGELOGFILELOC="changelog.html"
SCP_TARGET=$(shell cat ./deploymentScpTarget)
DEPLOYMENT_INCLUDES_DIR="./deployment-files"

COMPILER_GCC="gcc"
COMPILER_CLANG="/Developer/usr/bin/clang"
COMPILER=$(COMPILER_CLANG)


SOURCE_FILES=setWeblocThumb.m MBBase64.m ANSIEscapeHelper.m HGCLIUtils.m HGCLIAutoUpdater.m HGCLIAutoUpdaterDelegate.m SetWeblocThumbAutoUpdaterDelegate.m



all: setWeblocThumb

docs: usage.txt


usage.txt: setWeblocThumb
	@echo
	@echo ---- generating usage.txt:
	@echo ======================================
	./setWeblocThumb > usage.txt



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
setWeblocThumb: $(SOURCE_FILES) imgBase64.m
	@echo
	@echo ---- Compiling:
	@echo ======================================
	$(COMPILER) -O3 -Wall -force_cpusubtype_ALL -mmacosx-version-min=10.5 -arch i386 -arch ppc -framework Cocoa -framework WebKit -o $@ $(SOURCE_FILES)




#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# run clang static analyzer
#-------------------------------------------------------------------------
analyze:
	@echo
	@echo ---- Analyzing:
	@echo ======================================
	$(COMPILER_CLANG) --analyze $(SOURCE_FILES)





#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# make release package (prepare for deployment)
#-------------------------------------------------------------------------
package: setWeblocThumb docs
	@echo
	@echo ---- Preparing for deployment:
	@echo ======================================
	
# create zip archive
	mkdir -p $(TEMP_DEPLOYMENT_DIR)
	echo "-D -j $(TEMP_DEPLOYMENT_ZIPFILE) setWeblocThumb" | xargs zip
	cd "$(DEPLOYMENT_INCLUDES_DIR)"; echo "-g -R ../$(TEMP_DEPLOYMENT_ZIPFILE) *" | xargs zip
	
# if changelog doesn't already exist in the deployment dir
# for this version, get 'general' changelog file from root if
# one exists, and if not, create an empty changelog file
	@( if [ ! -e $(VERSIONCHANGELOGFILELOC) ];then\
		if [ -e $(GENERALCHANGELOGFILELOC) ];then\
			cp $(GENERALCHANGELOGFILELOC) $(VERSIONCHANGELOGFILELOC);\
			echo "Copied existing changelog.html from project root into deployment dir - opening it for editing";\
		else\
			echo -e "<ul>\n	<li></li>\n</ul>\n" > $(VERSIONCHANGELOGFILELOC);\
			echo "Created new empty changelog.html into deployment dir - opening it for editing";\
		fi; \
	else\
		echo "changelog.html exists for $(APP_VERSION) - opening it for editing";\
	fi )
	@open -a Smultron $(VERSIONCHANGELOGFILELOC)




#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# deploy to server
#-------------------------------------------------------------------------
deploy: package
	@echo
	@echo ---- Deploying to server:
	@echo ======================================
	
	@echo "Checking latest version number vs. current version number..."
	@( if [ "$(VERSION_ON_SERVER)" != "$(APP_VERSION)" ];then\
		echo "Latest version on server is $(VERSION_ON_SERVER). Uploading $(APP_VERSION).";\
	else\
		echo "NOTE: Current version exists on server: ($(APP_VERSION)).";\
	fi;\
	echo "Press enter to continue uploading to server or Ctrl-C to cancel.";\
	read INPUTSTR;\
	scp -r $(TEMP_DEPLOYMENT_DIR) $(TEMP_DEPLOYMENT_USAGEFILE) $(SCP_TARGET); )





#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
clean:
	@echo
	@echo ---- Cleaning up:
	@echo ======================================
	-rm -Rf setWeblocThumb
	-rm -Rf imgBase64.m
	-rm -Rf usage.txt



