# Install Zabbix Agent 4.4.7 from source on Debian 12

It does not natively have the Zabbix Agent 4.4.7 binaries for Debian 12, making it necessary to compile the source code.<br>
This script automates the compilation procedure by installing the necessary dependencies for the procedure.
<hr>

## Running the script [Do it as a root]:
Download the script:
```bash
$ wget https://raw.githubusercontent.com/jeanrodrigop/zabbix-source-4.4.7/main/zabbix-source-4.4.7.sh
```
Change permission to execute:
```bash
$ sudo chmod +x zabbix-source-4.4.7.sh
```
Execute the script:
```bash
$ ./zabbix-source-4.4.7.sh
```
<hr>

Build by Jean Rodrigo
