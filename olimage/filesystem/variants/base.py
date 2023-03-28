from olimage.core.io import Console
from olimage.core.setup import Setup
from olimage.core.utils import Utils

from olimage.filesystem.decorators import export, prepare, stamp
from olimage.filesystem.base import FileSystemBase


class VariantBase(FileSystemBase):
    stages = ["configure", "cleanup"]
    variant = "base"

    @stamp
    @export
    @prepare
    def configure(self):
        # # Copy resolv.conf
        # with Console("Copying /etc/resolv.conf"):
        #     Utils.shell.run(
        #         "rm -vf {}/etc/resolv.conf".format(self._build_dir), ignore_fail=True
        #     )
        #     Utils.shell.run(
        #         "cp -vf /etc/resolv.conf {}/etc/resolv.conf".format(self._build_dir)
        #     )

        with Console("Install temporary resolv.conf"):
            Utils.install("/etc/resolv.conf")

        # Install packages
        self._install_packages()

        with Console("Grant sudo without password for user 'um'"):
            Utils.install("/etc/sudoers.d/010_um-nopasswd")

        with Console("Who am I ?"):
            Utils.shell.chroot("sudo -u um whoami")

        # Nginx configuration
        with Console("Install Nginx configuration"):
            Utils.install("/etc/nginx/conf.d/common_vars.conf")
            Utils.install("/etc/nginx/conf.d/upstreams.conf")
            Utils.install("/etc/nginx/sites-available/mainsail")
            Utils.shell.chroot("rm /etc/nginx/sites-enabled/default")

        with Console("Link available site mainsail"):
            Utils.shell.chroot(
                "ln -sf /etc/nginx/sites-available/mainsail /etc/nginx/sites-enabled/"
            )

        with Console("Modify nginx logrotate cycle (14d -> 2d) ..."):
            Utils.shell.chroot("sed -i 's/rotate 14/rotate 2/' /etc/logrotate.d/nginx")

        with Console("Enable nginx service"):
            Utils.shell.chroot("systemctl enable nginx.service")

        # To be somewhat faster using bash scripts for now.
        # Install and launch ultimainsailos.sh
        with Console("Install and launch ultimainsail.sh"):
            Utils.install("/ultimainsailos.sh")
            Utils.shell.chroot("bash /ultimainsailos.sh")

        with Console("Remove ultimainsail.sh ..."):
            Utils.shell.chroot("rm -rf /ultimainsailos.sh")

        # restore resolv.conf
        with Console("Restore /etc/resolv.conf"):
            Utils.shell.run(
                "rm -vf {}/etc/resolv.conf".format(self._build_dir), ignore_fail=True
            )
            Utils.shell.run(
                "ln -nsf ../run/resolvconf/resolv.conf {}/etc/resolv.conf".format(
                    self._build_dir
                )
            )

    @stamp
    @export(final=True)
    @prepare
    def cleanup(self):
        super().cleanup()
