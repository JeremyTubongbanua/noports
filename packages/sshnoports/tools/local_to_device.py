# This program installs the local repo version of sshnpd to the device
# defined in the .env file.  It is intended to be used for development

from dotenv import load_dotenv
from os import getenv
from importlib import import_module
from pathlib import Path
from sys import path as sys_path
from os import path as os_path

script_dir = os_path.dirname(os_path.realpath(__file__))


def import_parents(level=1):
    global __package__
    file = Path(__file__).resolve()
    parent, top = file.parent, file.parents[level]

    sys_path.append(str(top))
    try:
        sys_path.remove(str(parent))
    except ValueError:  # already removed
        pass

    __package__ = ".".join(parent.parts[len(top.parts) :])
    import_module(__package__)  # won't be needed after that


if __name__ == "__main__" and __package__ is None:
    import_parents(level=3)

from ...noports_sdk_python.src.sshnp_client import SSHNPClient
from ...noports_sdk_python.src.package_source import LocalPackageSource

load_dotenv()

client = SSHNPClient(
    client_atsign=getenv("FROM"),
    device_atsign=getenv("TO"),
    host=getenv("HOST"),
    public_key=getenv("SSH_PUBLIC_KEY"),
)

client.connect(getenv("DEVICE"))

client.update_sshnpd(LocalPackageSource(os_path.join(script_dir, "..", "..", "..")))
client.restart_all_services()