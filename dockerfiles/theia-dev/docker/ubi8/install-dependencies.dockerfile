USER root
# Install libsecret-devel on s390x and ppc64le for keytar build (binary included in npm package for x86)
RUN yum install -y curl make cmake gcc gcc-c++ python2 git git-core-doc openssh less bash tar gzip rsync patch \
    && { [ $(uname -m) == "s390x" ] && printf '[Fedora-secondary-packages]\nname=fedora-secondary-packages\nbaseurl=https://rpmfind.net/linux/fedora-secondary/releases/34/Everything/s390x/os/\ngpgcheck=0\nenabled=1\n' >> /etc/yum.repos.d/redhat.repo &&  yum install -y libsecret libsecret-devel || true; } \
    && { [ $(uname -m) == "ppc64le" ] && yum install -y libsecret https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/libsecret-devel-0.18.6-1.el8.ppc64le.rpm || true; } \
    && { [ $(uname -m) == "x86_64" ] && yum install -y libsecret || true; } \
    && yum -y clean all && rm -rf /var/cache/yum
