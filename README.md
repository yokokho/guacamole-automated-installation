# Automated Setup for Guacamole Server with Tomcat

<p align='center'>بسم الله الرحمن الرحيم</p>

This script automates the setup process for deploying Guacamole Server with Tomcat on a Ubuntu (tested on Ubuntu 24.04 - fresh installation). 

If you are using Debian, you need to replace `libjpeg-turbo8-dev` in the script with `libjpeg62-turbo-dev`.

As a note, Guacamole is a clientless remote desktop gateway that supports standard protocols like VNC, RDP, and SSH. Basically, it allows us to access those protocols via a web browser.

---

## Requirements

- Ubuntu-based Linux distribution (tested on Ubuntu 24.04 - fresh installation)
- Internet connectivity
- **Root privileges or sudo access** for run the script (this is necessary because the script will attempt to automate the setup process for `mysql_secure_installation`, which technically requires sudo access.)

---

## Usage

1. Clone the repository and navigate to the directory:
    ```sh
    git clone https://github.com/yokokho/guacamole-automated-installation.git
    cd guacamole-automated-installation
    ```

2. Make the script executable:
    ```sh
    chmod +x guac-automate.sh
    ```

3. Run the script using sudo:
    ```sh
    sudo ./guac-automate.sh
    ```

4. Follow the prompts to input the required information:
   - Tomcat username and password
   - MySQL root password
   - Guacamole database details (name, username, password)
   - Preferred path name for Guacamole

5. Sit back and relax while the script sets up Guacamole with Tomcat (it takes a while because many packages will be installed).
   
6. After installation, you can access your Guacamole on your browser via `http://server_ip:8080/your-preferred-path`.

7. Use the following credentials to login:
   - Username: `guacadmin`
   - Password: `guacadmin`

![Guacamole Automated Installation - Screenshot 5](https://github.com/yokokho/guacamole-automated-installation/assets/13397042/f8dad100-35ae-4e15-875b-a5b456ffff53)

---

## Example Prompts and Actions

1. **Tomcat Configuration**:
    - Input your username for Tomcat: `your-tomcat-username`
    - Input your password for Tomcat: `your-tomcat-password`

2. **MySQL Configuration**:
    - Enter MySQL root password: `your-mysql-root-password`
    - Enter Guacamole database name: `guacamole_db`
    - Enter Guacamole database username: `guacamole_user`
    - Enter Guacamole database password: `guacamole_password`

3. **Guacamole Path**:
    - Enter our preferred path name for Guacamole: `our-secret-path`

---

## Script Details

- Updates the system and installs necessary packages.
- Installs Java - checks if Java is installed. If not, the script will install the default JDK.
- Install expect - this one is  is necessary because it allows the script to automate interactive processes requiring user input, such as the `mysql_secure_installation` command used in this script.
- Installs Tomcat.
- Creates a Tomcat service configuration file.
- Configures Tomcat for Guacamole (setting up the username, password, and modifying the configuration so that Tomcat can be accessed publicly).
- Downloads and installs Guacamole Server.
- Configures and starts Guacamole daemon.
- Sets up MySQL and Imports Guacamole database schema.
- Creates Guacamole properties file.
- Restarts necessary services.
- Optionally opens port 8080 on UFW firewall if detected.

---

## Additional Information

The script uses:
- Guacamole server version: 1.5.5
- Guacamole auth jdbc version: 1.5.5
- Tomcat version: 9.0.89
- MySQL connector java version: 8.0.26

Please note that Guacamole is not yet supported in Tomcat 10.

**Changing Versions:** If you need to modify the version of any software, you can do so by adjusting the `versions` used in the wget commands within the script.

---

## Results

![Guacamole Automated Installation - Screenshot 1](https://github.com/yokokho/guacamole-automated-installation/assets/13397042/87a6a3a9-bb42-486a-9597-06e48a10c298)

---

![Guacamole Automated Installation - Screenshot 2](https://github.com/yokokho/guacamole-automated-installation/assets/13397042/bc0d4b28-66a5-440b-b323-72c90068870d)

---

![Guacamole Automated Installation - Screenshot 3](https://github.com/yokokho/guacamole-automated-installation/assets/13397042/50b24411-eaf0-45bd-a6c7-c66f14614172)

---

![Guacamole Automated Installation - Screenshot 4](https://github.com/yokokho/guacamole-automated-installation/assets/13397042/200b5791-dce1-4290-b140-7ee7f6602cf5)

---

## Troubleshooting

- Ensure you have an active internet connection.
- Make sure you have sudo privileges on the system.

---

## Disclaimer

Before executing the script, please take a moment to review its contents and understand its functionality. It's essential to ensure that the actions performed by the script align with your system requirements and security policies.

This script is provided as-is, without warranty of any kind. Use it at your own risk.

---

## License

- This script is provided without any license restrictions. 
- Free to use and modify - for good purposes.
