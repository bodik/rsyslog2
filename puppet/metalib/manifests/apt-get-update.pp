#internal class, will be removed with full adoption puppetlabs-apt
class metalib::apt-get-update () {
 notice($name)
 exec {"apt-get update": 
                command => "/usr/bin/apt-get update",
                refreshonly => true,
 }
}
