#!/bin/bash
# This is a simple script to install FALCON-integrate + FALCON_unzip.
# contact: gconcepcion@pacificbiosciences.com

###Install script dependencies
##This script should work on both Ubuntu/CentOS as long as the following dependencies are installed and
##available in your $PATH

#source /mnt/software/Modules/current/init/bash
#module load gcc/4.9.2
#module load python/2.7.9
#module load virtualenv/13.0.1
#module load git

###Variables
INPUT=$1
if [ -z ${INPUT} ]; then
    ROOT=$(pwd)
else
    ROOT=$(readlink -f ${INPUT})
fi

SRC=${ROOT}/src
VENV_BASE=${ROOT}/fc_env
SLUG=$(date +%y%m%d)
VENV=${VENV_BASE}_${SLUG}
FALCON_PATH=${SRC}/FALCON-integrate
FALCON_REPO="https://github.com/PacificBiosciences/FALCON-integrate.git"
DL_CLOUD="https://downloads.pacbcloud.com/public/falcon/"

###Test whether you need ucs4 or ucs2 tarball with this command:
#  $ python2.7 -c 'import sysconfig,pprint; pprint.pprint(sysconfig.get_config_vars()["Py_UNICODE_SIZE"])'
UNZIP_TARBALL="falcon-2017.06.28-18.01-py2.7-ucs4.tar.gz"
#UNZIP_TARBALL="falcon-2017.06.28-18.01-py2.7-ucs2.tar.gz"

###Cleanup
if [ ! -d ${ROOT} ]; then
    mkdir ${ROOT}
fi

if [ -d ${SRC} ]; then
    rm -rf ${SRC}
    mkdir ${SRC}
else
    mkdir ${SRC}
fi 

if [ -d "${VENV}" ]; then
    echo "Removing previous build from today"
    rm -rf $VENV
fi

if [ -d "${FALCON_PATH}" ]; then
    echo "Removing old FALCON-integrate repo"
    rm -rf ${FALCON_PATH}
fi

if [ -L "${VENV_BASE}" ]; then
    unlink ${VENV_BASE}
fi


virtualenv --no-site-packages ${VENV}
echo "export LD_LIBRARY_PATH=${VENV}/lib:\${LD_LIBRARY_PATH}" >>${VENV}/bin/activate

source ${VENV}/bin/activate

cd $SRC
git clone ${FALCON_REPO}

###install falcon

cd ${FALCON_PATH}
git checkout master
git submodule update --init
sed -i "s|^FALCON_WORKSPACE.*|FALCON_WORKSPACE=${FALCON_PATH}|g" default-env.sh
sed -i "s|^PYTHONUSERBASE.*|PYTHONUSERBASE=${VENV}|g" default-env.sh
make init
source env.sh

make config-standard
make -j all
make install
#make test

###install unzip

cd ${SRC}
curl -O ${DL_CLOUD}/${UNZIP_TARBALL}
tar zxvf ${UNZIP_TARBALL}  -C ${VENV}

ln -s ${VENV} ${VENV_BASE}


###install MUMmer 3.23 - for FALCON_unzip

MUMMER_323='https://downloads.sourceforge.net/project/mummer/mummer/3.23/MUMmer3.23.tar.gz'
cd ${SRC}
wget ${MUMMER_323} -P ${SRC}
tar zxvf MUMmer3.23.tar.gz
cd MUMmer3.23
make install
cp nucmer ${VENV}/bin


###Test falcon_unzip pipeline

cd ${FALCON_PATH}/FALCON-examples
../git-sym/git-sym update run/greg200k-sv2
cd run/greg200k-sv2
fc_run fc_run.cfg

sed -i "s|^smrt_bin=.*|smrt_bin=${VENV}/bin|g" fc_unzip.cfg
fc_unzip.py fc_unzip.cfg

echo "FALCON & FALCON_unzip have been successfully installed into a virtualenv."
echo "To activate the FALCON_unzip environment:"
echo "$ source ${VENV}/bin/activate"
