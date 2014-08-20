 $product-releases.conf

APT::FTPArchive::Release::Origin "Elasticsearch";
APT::FTPArchive::Release::Label "Elasticsearch 1.2.x";
APT::FTPArchive::Release::Suite "stable";
APT::FTPArchive::Release::Codename "stable";
APT::FTPArchive::Release::Architectures "i386 amd64";
APT::FTPArchive::Release::Components "main";
APT::FTPArchive::Release::Description "Elasticsearch repo for all 1.2.x packages";

 $product.conf

Dir {
ArchiveDir "/path/to/repo/debian";
CacheDir "/path/to/repo/debian/.cache"
};
 
Default {
Packages::Compress ". gzip bzip2";
Sources::Compress ". gzip bzip2";
Contents::Compress ". gzip bzip2";
};
 
TreeDefault {
BinCacheDB "packages-$(SECTION)-$(ARCH).db";
Directory "pool/$(SECTION)";
Packages "$(DIST)/$(SECTION)/binary-$(ARCH)/Packages";
SrcDirectory "pool/$(SECTION)";
Contents "$(DIST)/Contents-$(ARCH)";
};
 
Tree "dists/stable" {
Sections "main";
Architectures "i386 amd64 all";
};

.repocfg
repo_dir=/root/packages
conf_dir=/root/repo_config

 update-repo.sh
#!/bin/bash
#richards
 
. /root/.repocfg
 
prog=$1
sync_s3=$2
 
if [[ -e $conf_dir/$prog.conf ]]; then
cd $repo_dir/$prog/debian/
 
apt-ftparchive packages pool > $repo_dir/$prog/debian/dists/stable/main/binary-all/Packages
cat $repo_dir/$prog/debian/dists/stable/main/binary-all/Packages | gzip -9 > $repo_dir/$prog/debian/dists/stable/main/binary-all/Packages.gz
 
cp $repo_dir/$prog/debian/dists/stable/main/binary-all/Packages $repo_dir/$prog/debian/dists/stable/main/binary-i386/Packages
cp $repo_dir/$prog/debian/dists/stable/main/binary-all/Packages.gz $repo_dir/$prog/debian/dists/stable/main/binary-i386/Packages.gz
cp $repo_dir/$prog/debian/dists/stable/main/binary-all/Packages $repo_dir/$prog/debian/dists/stable/main/binary-amd64/Packages
cp $repo_dir/$prog/debian/dists/stable/main/binary-all/Packages.gz $repo_dir/$prog/debian/dists/stable/main/binary-amd64/Packages.gz
 
apt-ftparchive -c $conf_dir/$prog-releases.conf release $repo_dir/$prog/debian/dists/stable/ > $repo_dir/$prog/debian/dists/stable/Release
# GPG sign the repository
rm -rf $repo_dir/$prog/debian/dists/stable/Release.gpg
gpg -a -b -o $repo_dir/$prog/debian/dists/stable/Release.gpg $repo_dir/$prog/debian/dists/stable/Release
 
if [[ $sync_s3 == "true" ]]; then
sleep 2
 
echo "uploading to S3"
s3cmd sync /$repo_dir/$prog/debian/ s3://packages.elasticsearch.org/$prog/debian/
echo "Setting files to public"
s3cmd setacl --acl-public --recursive s3://packages.elasticsearch.org/$prog/debian
fi
exit 0
else
echo "No config for $prog"
exit 1
fi

