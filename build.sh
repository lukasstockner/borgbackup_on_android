#!/data/data/com.termux/files/usr/bin/bash
set -eux

apt -y install make clang openssl perl tsu wget git python python gnupg dirmngr curl autoconf automake sed gettext gzip pkg-config libcrypt lz4 attr


pip install virtualenv
virtualenv --python=python3 borg-env
source borg-env/bin/activate

if [ -d borg ]; then
	cd borg
	git checkout 1.1-maint
	git pull
else
	git clone https://github.com/borgbackup/borg.git
	cd borg
	git branch 1.1-maint remotes/origin/1.1-maint
	git checkout 1.1-maint
fi

pip install -r requirements.d/development.txt

#find if sync_file_range is available
s=`bash ../sync_file_range_test/test.sh`
if [ "$s" = "1" ];
then
	echo "patching borg to not use sync_file_range...."
	git apply ../borg_sync_file_range.patch
else
	echo "no need to patch borg"
fi

#patching paths
export BORG_OPENSSL_PREFIX="/data/data/com.termux/files/usr/"
export BORG_LZ4_PREFIX="/data/data/com.termux/files/usr/"

pip install -e .

cd ..
#need wrapper for ssh, because /system/lib64/ needs to be in LD_LIBRARY_PATH
#otherwise: Remote: CANNOT LINK EXECUTABLE "ssh": library "libandroid-support.so" not found
export BORG_RSH=borg_ssh_wrapper
cp borg_ssh_wrapper /data/data/com.termux/files/usr/bin/borg_ssh_wrapper
chmod +x /data/data/com.termux/files/usr/bin/borg_ssh_wrapper

#test by creating a backup of the borg directory
borg init -e none borg_test
borg create borg_test::1 borg
borg list borg_test
borg info borg_test::1
borg list borg_test::1
