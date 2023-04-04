import os
import subprocess

#Getting path and changing dir:
print("Example : /home/ajay/")
clientfile_path = input("Enter the folder path of the file: ")
os.chdir(clientfile_path)


#Installation
print("Example : BIOVIA_2021.DS2021Client - 1cayjy_yP_UbkwNF_M3rm3-dqFQQEepBE.bin")
clientfile_name = input("Enter the file name to be installed: ")
subprocess.run(["./"+ clientfile_name, "--noexec", "--target", clientfile_path + "BIOVIA"])


#Installing DSC Client:
os.chdir(clientfile_path + "BIOVIA")
subprocess.run(["rm", "install_DSClient.sh"])

os.chdir(clientfile_path + "DiscoveryStudioVisualizer")
subprocess.run(["cp", "install_DSClient.sh", clientfile_path + "BIOVIA"])

os.chdir(clientfile_path + "BIOVIA")
subprocess.run(["chmod", "744", "install_DSClient.sh"])

subprocess.call(["bash","install_DSClient.sh"])


#Lp installing:
subprocess.run(["sudo", "apt", "install", "csh"])
subprocess.run(["sudo", "apt", "install", "tcsh"])

os.chdir(clientfile_path + "BIOVIA/DiscoveryStudio2021/lp_installer/")
subprocess.run(["chmod", "744", "lp_setup_linux.sh"])

subprocess.run(["./"+ "lp_setup_linux.sh", "--noexec", "--target", clientfile_path + "BIOVIA"])


#lp config:
os.chdir(clientfile_path + "BIOVIA/LicensePack/etc")

subprocess.call(["csh","lp_config"])

#lp echovars:
subprocess.call(["csh","lp_echovars"])

#config lp location:
os.chdir(clientfile_path + "BIOVIA/DiscoveryStudio2021/bin/")

subprocess.run(["./config_lp_location", clientfile_path + "/BIOVIA/LicensePack/"])

#libpng 15:
os.chdir(clientfile_path + "/DiscoveryStudioVisualizer/libpng-1.5.15")

subprocess.run(["./configure", "--prefix=/usr/local/libpng"])
subprocess.run(["sudo", "make" ,"install"])
subprocess.run(["sudo", "apt-get" ,"install", "mlocate"])
subprocess.run(["sudo", "updatedb"])

subprocess.run(["sudo", "ln", "-s", "/usr/local/libpng/lib/libpng15.so.15", "/usr/lib/libpng15.so.15"])


#Running the program:
os.chdir(clientfile_path + "BIOVIA/DiscoveryStudio2021/bin/")

subprocess.call(["bash", "DiscoveryStudio2021"])













