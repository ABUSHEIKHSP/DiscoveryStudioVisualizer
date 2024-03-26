import os, subprocess, glob
import tkinter as tk
from tkinter import filedialog


class DSC_Installer():

    def __init__(self):

        self.bin_path = ''
        self.home = ''
        self.year = ''

    def bin_file_operations(self):

        self.bin_path = filedialog.askopenfilename() # Getting bin file
        # self.bin_path = '/home/abu/Downloads/BIOVIA_DS2024Client.bin'
        os.system(f'chmod 744 {self.bin_path}') # Making it executable
        
        # Installing bin file
        self.home = os.path.expanduser('~/') # Getting home path 
        self.year = ''.join([s for s in self.bin_path if s.isdigit()]) # Extracting year from bin file
        os.system(f'{self.bin_path} --noexec --target {self.home}BIOVIA{self.year}')

    def client_file_operations(self):

        os.chdir(f'{self.home}BIOVIA{self.year}') # Getting into BIOVIA2024

        # Modifying install_DSClient.sh
        with open('install_DSClient.sh', 'r') as file:
            lines = file.readlines() # Reading all the lines
            lines[0] = '#!/bin/bash\n'  # Modifying the first line

        for ind, line in enumerate(lines): # Getting index path of line alias echoe="echo -e"
            if line == 'alias echoe="echo -e"\n':
                lines[ind - 1] = 'shopt -s expand_aliases\n' # Adding another line before it

        with open('install_DSClient.sh', 'w') as file: # Writing back to the file
            file.writelines(lines)

        os.system('chmod 744 install_DSClient.sh') # Making it executable
        os.system('./install_DSClient.sh') # Running client file

    def lp_installer_operations(self):

        os.chdir(f"{self.home}BIOVIA") # Getting into BIOVIA
        os.chdir(f"{os.getcwd()}/{os.listdir()[0]}/lp_installer") # Getting into DicoveryStudio2024/lp_installer
        
        os.system('chmod 744 lp_setup_linux.sh') # Making it executable
        os.system(f'./lp_setup_linux.sh --noexec --target {self.home}/BIOVIA/')

    def license_pack_operations(self):

        os.chdir(f"{self.home}BIOVIA/LicensePack/etc/") # Getting into BIOVIA/LicensePack/etc

        # lp_config file needs c shell scripting language.
        # So we need to install tcsh in our system, which helps to execute the file
        #os.system('sudo apt install tcsh')
        os.system('./lp_config') # Executing lp_config

        # Modifying lp_echovars
        with open('lp_echovars', 'r') as file:
            lines = file.readlines() # Reading all the lines
            lines[0] = '#!/bin/tcsh\n'  # Modifying the first line
       
        with open('lp_echovars', 'w') as file: # Writing back to the file
            file.writelines(lines)

        os.system('./lp_echovars') # Executing file

        os.chdir(f"{self.home}BIOVIA") # Getting into BIOVIA
        os.chdir(f"{os.getcwd()}/{os.listdir()[0]}/bin") # Getting into DicoveryStudio2024/bin

        os.system(f'./config_lp_location {self.home}BIOVIA/LicensePack/')

    def libpng_operations(self):

        os.chdir(f'{self.home}DiscoveryStudioVisualizer/libpng15.so.15/')  # Getting into libpng15 folder

        os.system('sudo ./configure --prefix=/usr/local/libpng')
        os.system('sudo make install')

        source_path = "/usr/local/libpng/lib/libpng15.so.15"
        link_path = "/usr/lib/libpng15.so.15"

        command = f"sudo ln -s {source_path} {link_path}"
        os.system(command)


    def run_dsv(self):

        os.chdir(f"{self.home}BIOVIA") # Getting into BIOVIA
        os.chdir(f"{os.getcwd()}/{os.listdir()[0]}/bin") # Getting into DicoveryStudio2024/bin

        # Modifying DicoveryStudio
        file_name = glob.glob('DiscoveryStudio*')[0] # Getting DiscoveryStudio file

        with open(file_name, 'r') as file:
            lines = file.readlines() # Reading all the lines

        for ind, line in enumerate(lines): # Getting index path of line ACCELRYS_DEBUG=0
            if line.strip() == 'ACCELRYS_DEBUG=0':
                lines[ind] = '    ACCELRYS_DEBUG=1\n' # Changing 0 to 1

        with open(file_name, 'w') as file: # Writing back to the file
            file.writelines(lines)

        os.system(f'./{file_name}')



dsvi = DSC_Installer()
dsvi.bin_file_operations()
dsvi.client_file_operations()
dsvi.lp_installer_operations()
dsvi.license_pack_operations()
dsvi.libpng_operations()
dsvi.run_dsv()
