#!/bin/bash

installpackages(){

dnf -y install epel-release
dnf -y install rpmlint
dnf -y install mock
dnf -y install rpm-tools
dnf -y install golang

git clone https://git.rockylinux.org/release-engineering/public/srpmproc
cd srpmproc/cmd/srpmproc
go build
cp -fn srpmproc /usr/bin
cd ..
cd ..
cd ..
rm -rf srpmproc


}


getsrpms(){

DQUOTE='"'
PAGEVAR="*?sorting=&page="
PAGENUM=1
MAXPAGES=162


until [ "$PAGENUM" -gt "$MAXPAGES" ]
do
    printf "\e[1;32mPage added to queue: \e[1;31mhttps://git.centos.org/projects/rpms/$PAGEVAR$PAGENUM\e[0m\n"
    ((PAGENUM=PAGENUM+1))
    curl -Ls "https://git.centos.org/projects/rpms/$PAGEVAR$PAGENUM" | grep -was 'href="/rpms' | sed "s/<a href="$DQUOTE"\///g" | sed -r 's/.{2}$//' | sed -r 's/.{10}//' >> urls.tmp &
    sleep 0.2
done
sleep 5

}

clonealltherepos(){

LINES=$(cat urls.tmp | wc -l)
LINEUSED=0

printf "\e[1;32mRepos to clone: \e[1;31m$LINES\e[0m\n"
sleep 1

mkdir repos
cd repos

until [ "$LINEUSED" -gt "$LINES" ]
do
    LINES=$(cat ../urls.tmp | wc -l) #Had some really weird issues with the "until" loop changing the number of lines for the "LINES" var, so it has to be more than once
    printf "\e[1;32mRepos cloned: \e[1;31m$LINEUSED \e[32mout of \e[1;31m$LINES\e[0m\n"             #  |
    ((LINEUSED=LINEUSED+1))                                                                         #  |
    printf "\e[1;32mCloning repo: \e[1;31m$REPO\e[0m\n"                                             #  |
    REPO=$(sed -n ${LINEUSED}p ../urls.tmp)                                                         #  |
    git clone https://git.centos.org/$REPO                                                          #  |
    LINES=$(cat ../urls.tmp | wc -l)                   #    "recheck" of the original line variable  < |
done

}

buildsrpm(){

cd ..
mkdir -p tmp/srpmproc
cd repos

REPOS=$(ls | wc -l)
REPONUM=0

until [ "$REPONUM" -eq "$REPOS" ]
do
    REPOS=$(ls | wc -l)
    ((REPONUM=REPONUM+1))
    REPONAME=$(ls -1 . | sed -n ${REPONUM}p)
    cd $REPONAME
    srpmproc --version 8 --upstream-prefix https://git.rockylinux.org/staging --storage-addr file:///mnt/rockybuild/tmp/srpmproc --tmpfs-mode SOURCES --source-rpm $REPONAME && sleep 1
    rpmbuild -bs --nodeps --define "%_topdir SOURCES/r8" --define "dist .el8" SOURCES/r8/SPECS/*.spec || rpmbuild -bs --nodeps --define "%_topdir `find .`" --define "dist .el8" `find .` || rpmbuild -bs --nodeps --define "%_topdir `find . | grep r8`" --define "dist .el8" `find . | grep .spec` 
    cd ..
done

cd ..
mkdir srpms-built
find repos/ -name '*.rpm' -print0 | xargs -0 -I files cp files srpms-built/

}


buildrpms(){
mkdir rpms-built

mock -r /etc/mock/centos-8-x86_64 --nocheck --resultdir=rpms-built/ srpms-built/*



}

# movespecs(){
# 
# cd ..
# mkdir spec
# find repos/ -name '*.spec' -print0 | xargs -0 -I files cp files spec/
# cd spec
# 
# }

# gensrpms(){
# 
# SPECS=$(ls | wc -l)
# SPECNUM=0
# mkdir ../sources
# mkdir ../srpms
# 
# 
# until [ "$SPECNUM" -eq "$SPECS" ]
# do
#     SPECS=$(ls | wc -l)
#     printf "\e[1;32mSources Downloaded: \e[1;31m$SPECNUM \e[32mout of \e[1;31m$SPECS\e[0m\n"
#     ((SPECNUM=SPECNUM+1))
#     SPECFILE=$(ls -1 .  | sed -n ${SPECNUM}p)
#     spectool -A --get-files --directory=../sources --debug --force $SPECFILE || echo "$SPECFILE sourcepull failed!" >> ../sourcepull-failures.log && printf "\033[1m\033[35m$SPECFILE Sourcepull Failed! \e[0m\n"
#     echo $SPECFILE
# done
# 
# SPECS=$(ls | wc -l)
# SPECNUM=0
# 
# mock --init
# until [ "$SPECNUM" -eq "$SPECS" ]
# do
#     SPECS=$(ls | wc -l)
#     printf "\e[1;32mSRPMs Built: \e[1;31m$SPECNUM \e[32mout of \e[1;31m$SPECS\e[0m\n"
#     ((SPECNUM=SPECNUM+1))
#     SPECFILE=$(ls -1 .  | sed -n ${SPECNUM}p)
#     mock --buildsrpm --resultdir=../srpms --sources ../sources/ --spec $SPECFILE || echo "$SPECFILE SRPM Generation failed!" >> ../srpmgen-failures.log && printf "\033[1m\033[35m$SPECFILE SRPM Generation Failed! \e[0m\n"
#     SPECS=$(ls | wc -l)
# done
# 
# cd ..
# 
# }

cleanup(){

#rm -rf urls.tmp
#rm -rf spec
printf "\e[1;31mDone! \e[0m\n"

}
 
getsrpms
clonealltherepos
buildsrpm
buildrpms
cleanup
