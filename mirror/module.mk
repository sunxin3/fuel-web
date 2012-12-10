/:=$(LOCAL_MIRROR)/

$/%: /:=$/

METADATA_FILES:=repomd.xml comps.xml filelists.xml.gz primary.xml.gz other.xml.gz

CENTOSEXTRA_PACKAGES:=$(shell grep -v "^\\s*\#" requirements-rpm.txt)
CENTOSRPMFORGE_PACKAGES:=qemu

# RPM PACKAGE CACHE RULES

ifeq ($(IGNORE_MIRROR),1)
REPO_SUFFIX=real
else
REPO_SUFFIX=mirror
endif

define yum_conf
[main]
cachedir=$(CENTOS_REPO_DIR)cache
keepcache=0
debuglevel=6
logfile=$(CENTOS_REPO_DIR)yum.log
exactarch=1
obsoletes=1
gpgcheck=0
plugins=1
pluginpath=$(shell readlink -f -m $(CENTOS_REPO_DIR)etc/yum-plugins)
pluginconfpath=$(shell readlink -f -m $(CENTOS_REPO_DIR)etc/yum/pluginconf.d)
reposdir=$(CENTOS_REPO_DIR)etc/yum-$(REPO_SUFFIX).repos.d
endef

$(CENTOS_REPO_DIR)etc/yum-$(REPO_SUFFIX).conf: export contents:=$(yum_conf)
$(CENTOS_REPO_DIR)etc/yum-$(REPO_SUFFIX).conf: mirror/module.mk
ifeq ($(IGNORE_MIRROR),1)
	mkdir -p $(CENTOS_REPO_DIR)etc/yum/pluginconf.d
	echo "[main]\nenabled=1" > $(CENTOS_REPO_DIR)etc/yum/pluginconf.d/priorities.conf
	mkdir -p $(CENTOS_REPO_DIR)etc/yum-plugins
	cp mirror/yum-priorities-plugin.py $(CENTOS_REPO_DIR)etc/yum-plugins/priorities.py
endif
	@mkdir -p $(@D)
	echo "$${contents}" > $@

define yum_mirror_repo
[mirror]
name=CentOS $(CENTOS_RELEASE) - Base
baseurl=$(REPOMIRROR)/Packages
gpgcheck=0
enabled=1
endef

define yum_real_repo
[base]
name=CentOS-$(CENTOS_RELEASE) - Base
#mirrorlist=http://mirrorlist.centos.org/?release=$(CENTOS_RELEASE)&arch=$(CENTOS_ARCH)&repo=os
baseurl=$(CENTOSMIRROR)/$(CENTOS_RELEASE)/os/$(CENTOS_ARCH)
gpgcheck=0
enabled=1
priority=10

[updates]
name=CentOS-$(CENTOS_RELEASE) - Updates
#mirrorlist=http://mirrorlist.centos.org/?release=$(CENTOS_RELEASE)&arch=$(CENTOS_ARCH)&repo=updates
baseurl=$(CENTOSMIRROR)/$(CENTOS_RELEASE)/updates/$(CENTOS_ARCH)
gpgcheck=0
enabled=1
priority=10

[extras]
name=CentOS-$(CENTOS_RELEASE) - Extras
#mirrorlist=http://mirrorlist.centos.org/?release=$(CENTOS_RELEASE)&arch=$(CENTOS_ARCH)&repo=extras
baseurl=$(CENTOSMIRROR)/$(CENTOS_RELEASE)/extras/$(CENTOS_ARCH)
gpgcheck=0
enabled=1
priority=10

[centosplus]
name=CentOS-$(CENTOS_RELEASE) - Plus
#mirrorlist=http://mirrorlist.centos.org/?release=$(CENTOS_RELEASE)&arch=$(CENTOS_ARCH)&repo=centosplus
baseurl=$(CENTOSMIRROR)/$(CENTOS_RELEASE)/centosplus/$(CENTOS_ARCH)
gpgcheck=0
enabled=1
priority=10

[contrib]
name=CentOS-$(CENTOS_RELEASE) - Contrib
#mirrorlist=http://mirrorlist.centos.org/?release=$(CENTOS_RELEASE)&arch=$(CENTOS_ARCH)&repo=contrib
baseurl=$(CENTOSMIRROR)/$(CENTOS_RELEASE)/contrib/$(CENTOS_ARCH)
gpgcheck=0
enabled=1
priority=10

[epel]
name=Extra Packages for Enterprise Linux $(CENTOS_MAJOR) - $(CENTOS_ARCH)
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-$(CENTOS_MAJOR)&arch=$(CENTOS_ARCH)
baseurl=$(EPELMIRROR)/$(CENTOS_MAJOR)/$(CENTOS_ARCH)
gpgcheck=0
enabled=1
priority=20

[openstack-epel-fuel]
name=Mirantis OpenStack Custom Packages
mirrorlist=http://download.mirantis.com/epel-fuel-folsom/mirror.external.list
gpgkey=https://fedoraproject.org/static/0608B895.txt
  http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6
  http://download.mirantis.com/epel-fuel-folsom/rabbit.key
  http://download.mirantis.com/epel-fuel-folsom/mirantis.key
gpgcheck=0
enabled=1
priority=1

[mirantis]
name=Mirantis Packages for CentOS
baseurl=http://moc-ci.srt.mirantis.net/rpm
gpgcheck=0
enabled=0

[rpmforge]
name=RHEL $(CENTOS_RELEASE) - RPMforge.net - dag
#mirrorlist = http://apt.sw.be/redhat/el$(CENTOS_MAJOR)/en/mirrors-rpmforge
baseurl=$(RPMFORGEMIRROR)/el$(CENTOS_MAJOR)/en/$(CENTOS_ARCH)/rpmforge
gpgcheck=0
enabled=0

[rpmforge-extras]
name = RHEL $(CENTOS_RELEASE) - RPMforge.net - extras
#mirrorlist = http://apt.sw.be/redhat/el$(CENTOS_MAJOR)/en/mirrors-rpmforge-extras
baseurl = $(RPMFORGEMIRROR)/el$(CENTOS_MAJOR)/en/$(CENTOS_ARCH)/extras
gpgcheck = 0
enabled = 1
priority=95

[puppetlabs]
name=Puppet Labs Packages
baseurl=http://yum.puppetlabs.com/el/$(CENTOS_MAJOR)/products/$(CENTOS_ARCH)/
enabled=1
gpgcheck=1
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
priority=1
endef

$(CENTOS_REPO_DIR)etc/yum-$(REPO_SUFFIX).repos.d/base.repo: export contents:=$(yum_$(REPO_SUFFIX)_repo)

$(CENTOS_REPO_DIR)etc/yum-$(REPO_SUFFIX).repos.d/base.repo: mirror/module.mk
	@mkdir -p $(@D)
	echo "$${contents}" > $@

$(CENTOS_REPO_DIR)repodata/comps.xml:
	@mkdir -p $(@D)
	wget -O $@.gz $(CENTOS_MIRROR)/`wget -qO- $(CENTOS_MIRROR)/repodata/repomd.xml | \
	 grep '$(@F)\.gz' | awk -F'"' '{ print $$2 }'`
	gunzip $(CENTOS_REPO_DIR)repodata/$(@F).gz

$/cache-boot.done: \
		$(addprefix $(CENTOS_REPO_DIR)/images/,$(IMAGES_FILES)) \
		$(addprefix $(CENTOS_REPO_DIR)/EFI/BOOT/,$(EFI_FILES)) \
		$(addprefix $(CENTOS_REPO_DIR)/isolinux/,$(ISOLINUX_FILES))
	$(ACTION.TOUCH)

$/cache-infra.done: \
		$(CENTOS_REPO_DIR)etc/yum-$(REPO_SUFFIX).conf \
		$(CENTOS_REPO_DIR)etc/yum-$(REPO_SUFFIX).repos.d/base.repo
	$(ACTION.TOUCH)

$/cache-extra.done: \
		$(CENTOS_REPO_DIR)repodata/comps.xml \
	 	$/cache-infra.done \
		requirements-rpm.txt
	yum -c $(CENTOS_REPO_DIR)etc/yum-$(REPO_SUFFIX).conf clean all
	rm -rf /var/tmp/yum-$$USER-*/
	yumdownloader -c $(CENTOS_REPO_DIR)etc/yum-$(REPO_SUFFIX).conf --resolve --destdir=$(CENTOS_REPO_DIR)Packages --archlist=$(CENTOS_ARCH) $(CENTOSEXTRA_PACKAGES) $(CENTOSRPMFORGE_PACKAGES)
	$(ACTION.TOUCH)

$/cache.done: $/cache-extra.done $/cache-boot.done
	$(ACTION.TOUCH)

$(addprefix $(CENTOS_REPO_DIR)Packages/repodata/,$(METADATA_FILES)): $/cache.done $(CENTOS_REPO_DIR)repodata/comps.xml
	createrepo -g `readlink -f "$(CENTOS_REPO_DIR)repodata/comps.xml"` -o $(CENTOS_REPO_DIR)Packages $(CENTOS_REPO_DIR)Packages

$/repo.done: $(addprefix $(CENTOS_REPO_DIR)Packages/repodata/,$(METADATA_FILES))
	touch $@

# centos isolinux files

$(addprefix $(CENTOS_REPO_DIR)/isolinux/,$(ISOLINUX_FILES)):
	@mkdir -p $(@D)
	wget -O $@ $(CENTOS_MIRROR)/isolinux/$(@F)

# centos EFI boot images

$(addprefix $(CENTOS_REPO_DIR)/EFI/BOOT/,$(EFI_FILES)):
	@mkdir -p $(@D)
	wget -O $@ $(CENTOS_MIRROR)/EFI/BOOT/$(@F)

# centos boot images

$(addprefix $(CENTOS_REPO_DIR)/images/,$(IMAGES_FILES)):
	@mkdir -p $(@D)
	wget -O $@ $(CENTOS_MIRROR)/images/$(@F)

# EGGS AND GEMS

$/eggs.done: \
		$(BS_DIR)/init.done \
		requirements-eggs.txt
	@mkdir -p $/eggs
	@[ -f $/eggs/pip-1.2.1.tar.gz ] || (cd $/eggs && wget http://pypi.python.org/packages/source/p/pip/pip-1.2.1.tar.gz)
	@cp -R $/eggs $(INITRAM_DIR)/tmp
	sudo cp /etc/resolv.conf $(INITRAM_DIR)/etc/resolv.conf
	$(YUM) install python-setuptools
	mount | grep -q $(INITRAM_DIR)/proc || sudo mount --bind /proc $(INITRAM_DIR)/proc
	mount | grep -q $(INITRAM_DIR)/dev || sudo mount --bind /dev $(INITRAM_DIR)/dev
	$(CHROOT_CMD) easy_install -U /tmp/eggs/pip-1.2.1.tar.gz
	@cat requirements-eggs.txt | while read egg ver; do \
         if [ -z "`find $(INITRAM_DIR)/tmp/eggs/ -name $${egg}-$${ver}\*`" ]; then \
             $(CHROOT_CMD) pip install --exists-action=i -d /tmp/eggs $${egg}==$${ver} ;\
         fi; \
	done
	cp -fR $(INITRAM_DIR)/tmp/eggs $/
	$(CHROOT_CMD) rm -rf /tmp/eggs
	$(CHROOT_CMD) rm -f /tmp/requirements-eggs.txt
	sudo sync
	sudo umount $(INITRAM_DIR)/proc
	sudo umount $(INITRAM_DIR)/dev
	sudo rm $(INITRAM_DIR)/etc/resolv.conf
	$(ACTION.TOUCH)

define bundle_gemfile_template
source "http://rubygems.org"
source "http://gems.rubyforge.org"
source "http://gemcutter.org"
endef

$/gems-bundle-gemfile.done: export bundle_gemfile_template_content:=$(bundle_gemfile_template)
$/gems-bundle-gemfile.done: requirements-gems.txt
	@mkdir -p $/gems-bundle
	echo "$${bundle_gemfile_template_content}" > $/gems-bundle/Gemfile
	cat requirements-gems.txt | while read gem ver; do \
         echo "gem \"$${gem}\", \"$${ver}\"" >> $/gems-bundle/Gemfile; \
	done
	$(ACTION.TOUCH)

ifeq ($(IGNORE_MIRROR),1)
SRC_URLS:=$(shell grep -v ^\\s*\# requirements-src.txt)
else
SRC_URLS:=$(shell grep -v ^\\s*\# requirements-src.txt | sed "s=.*/\(.*\)=$(MIRROR_URL)/src/\1=")
endif

$/src.done:
	@mkdir -p $/src
	wget --no-use-server-timestamps -c -P $/src $(SRC_URLS)
	$(ACTION.TOUCH)

$/gems-bundle.done: $/gems-bundle-gemfile.done
	( cd $/gems-bundle && bundle install --path ./ && bundle package )
	( cd $/gems-bundle/vendor/cache/ && gem fetch -v 1.2.1 bundler )
	$(ACTION.TOUCH)

$/gems.done: $/gems-bundle.done
	@mkdir -p $/gems
	cp $/gems-bundle/vendor/cache/*.gem $/gems
	$(ACTION.TOUCH)

mirror: $(addprefix $(CENTOS_REPO_DIR)Packages/repodata/,$(METADATA_FILES)) \
	$/src.done \
	$/cache-boot.done \
	$/eggs.done \
	$/gems.done
