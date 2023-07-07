#!/bin/bash
#
########### Create user ############################
#
# Script required username argument is used. -u
# Default:
# Username is input -u username
# Default directory /home/username
# A random password is generated
# Account is active
# Ssh is provided (method of adding to a group is used, 
# it is not necessary to restart the ssh service )
####################################################


# Help Example
Help() {
    # Display Help
    echo "Script to create new user(s) with arguments"
    echo "Syntax: script.sh [-h|-u|-d|-p|-s]"
    echo "Exaple: sudo ./script.sh -u David -d Dav -s Y -p Y"
    echo "Arguments:"
    echo "-h Print whis help"
    echo "-u Enter username. Required arguments!!!"
    echo "-d Use if you want a non-standard home directory, example above"
    echo "-p Will generate a new password automatically, to use your own password use the Y option"
    echo "-a Default user account Unlock, to Lock account use the Y option. For Unlock use: usermod -U username"
    echo "-s Ssh access. Provide by default for not provide use (Y/y).To add to a group you can use: usermod -aG ssh-access username"
}

# Check the number of arguments (Required username)
if [ $# -lt 1 ] || [ $1 != "-u" ]; then
    echo "You must using fitst option -u username"
    Help
    exit 1
fi

# Check group and ssh-config.
# On first run, creates the "ssh-access" group, adds it to /etc/ssh/sshd_config,
# adds the root user and all users with UID > 1000 to it. Restarts service ssh.
if ! grep -q "^ssh-access:" /etc/group; then
    # Create ssh-access group
    sudo groupadd ssh-access
    echo "Group ssh-access created"
    # Add root user to ssh-access group
    sudo usermod -aG ssh-access root
    echo "User root added to ssh-access group"
    # Add users with UID above 1000 to ssh-access group
    for user in $(awk -F':' '$3 > 1000 {print $1}' /etc/passwd); do
        sudo usermod -aG ssh-access $user
        echo "User $user added to ssh-access group"
    done
else
    echo "Group ssh-access already exists"
fi

# Check if AllowGroups option exists in /etc/ssh/sshd_config
if grep -q "^AllowGroups.*ssh-access" /etc/ssh/sshd_config; then
    echo "AllowGroups already configured with ssh-access."
else
    echo "AllowGroups ssh-access" >>/etc/ssh/sshd_config
    echo "AllowGroups has been added with ssh-access."
    # Restart the ssh service
    sudo service ssh restart
fi

# Initialize variables
username=""
ssh=""
home_folder=""
group_name="ssh-access"
password=""
access=""

# Description of arguments
while getopts ":h:u:d:s:p:a:s:" option; do
    case $option in
    h) Help && exit 1 ;;
    u) username="$OPTARG" ;;
    d) home_folder=/home/"$OPTARG" ;;
    s) ssh="$OPTARG" ;;
    p) password="$OPTARG" ;;
    a) access="$OPTARG" ;;
    *) echo "[!] Invalid argument" && Help && exit 1 ;;
    esac
done

# --- TASK 2 ---
if [ "${#username}" -gt "10" ]; then
    echo "Your username contains more than 10 characters. Please enter less than 10 characters"
    Help
    exit 1
fi

# Generate a new password
if [[ $password =~ ^[Yy]$ ]]; then
    # Prompt for password if "-p Y"
    read -s -p "Enter password: " user_password
    echo
else
    # Generate password
    user_password=$(date +%s | sha256sum | base64 | head -c 8)
fi

# Create user
sudo useradd -m -d "${home_folder:-/home/$username}" $username
# Add password for new user
echo -e "$user_password\n$user_password" | passwd $username
# Username and password view
echo User $username password $user_password

# check user (temp)
cat /etc/passwd | grep $username

# Lock account if use option "-a Y"
if [[ $access =~ ^[Yy]$ ]]; then
    usermod -L $username
fi

# check user account (temp)
cat /etc/shadow | grep $username

# Check the value of ssh variable
if [[ $ssh =~ ^[Yy]$ ]]; then
    echo "User $username NOT added to the $group_name group."
else
    usermod -aG $group_name $username
    echo "User $username has been added to the $group_name group."
fi

# check user account (temp)
cat /etc/group | grep $group_name


# # Display existing active users
# active_users=$(awk -F: '($7 != "/usr/sbin/nologin" && $7 != "/bin/false") { print $1 }' /etc/passwd)
# active_users_count=$(echo "$active_users" | wc -l)
# echo "Existing active users:"
# if [ "$active_users_count" -eq 0 ]; then
#     echo "No active users found."
# else
#     awk -F: '($7 != "/usr/sbin/nologin" && $7 != "/bin/false") { print NR".", $1 }' /etc/passwd | column
# fi

# # Prompt for option to view disabled accounts
# read -p "View list of disabled user accounts? [Y/n]: " view_disabled

# # Check if user wants to view disabled accounts
# if [[ $view_disabled =~ ^[Yy]$ ]]; then
#     # Request root password
#     sudo echo "Requesting root password to view disabled accounts..."

#     # Display disabled user accounts
#     echo "Disabled user accounts:"
#     sudo awk -F: '($2 == "!" || $2 == "*") { print $1 }' /etc/shadow | column
# fi

# # Prompt for account lock
# read -p "Do you want to lock a user account? [Y/n]: " lock_account

# if [[ $lock_account =~ ^[Yy]$ ]]; then
#     # Prompt for username
#     read -p "Enter the username to lock: " username

#     # Check if user exists
#     if id "$username" >/dev/null 2>&1; then
#         # Lock user account
#         sudo passwd -l $username
#         echo "User account $username locked."
#     else
#         echo "User account $username does not exist."
#     fi
# else
#     echo "No user accounts locked."
# fi

# Prompt to create a new user
# read -p "Create a new user? [Y/n]: " create_new_user

# if [[ $create_new_user =~ ^[Yy]$ ]]; then
#     # Prompt for username
#     read -p "Enter username: " username

#     # Show string length
#     string_length=${#username}
#     echo "------"
#     echo "The length of the string is: $string_length"

#     # # Check the username length
#     # chekUsernameLimit "$username"
#     # echo "------"

#     # Prompt for password
#     read -s -p "Enter password: " password
#     echo

#     # Create user with password
#     sudo useradd -m -p $(echo "$password" | openssl passwd -1 -stdin) $username

#     # Prompt for additional user details
#     read -p "Enter full name: " full_name
#     read -p "Enter description: " description

#     # Set additional user details
#     sudo chfn -f "$full_name" -r "$description" $username

#     # Create separate directory for the user
#     read -p "Create a separate directory for the user? [Y/n]: " create_directory
#     if [[ $create_directory =~ ^[Yy]$ ]]; then
#         sudo mkdir /home/$username
#         sudo chown $username:$username /home/$username
#         echo "Separate directory created for user $username."
#     fi

#     echo "User $username created successfully."
#     echo "------------"
#     returnLength
#     echo "------------"
# fi

# # Grant SSH access to the user
# read -p "Grant SSH access to the user? [Y/n]: " grant_ssh_access
# if [[ $grant_ssh_access =~ ^[Yy]$ ]]; then
#     # Prompt for SSH permission configuration
#     read -p "Enter SSH permission configuration (e.g., 'AllowUsers username'): " ssh_config

#     # Add SSH permission configuration to sshd_config file
#     echo "$ssh_config" | sudo tee -a /etc/ssh/sshd_config >/dev/null
#     sudo service ssh restart

#     echo "SSH access granted according to the provided configuration."
# fi

# # Prompt to remove a user
# read -p "Remove a user? [Y/n]: " remove_user

# if [[ $remove_user =~ ^[Yy]$ ]]; then
#     # Prompt for username to remove
#     read -p "Enter username to remove: " username_to_remove

#     # Remove SSH permission configuration from sshd_config file
#     sudo sed -i "/AllowUsers.*$username_to_remove/d" /etc/ssh/sshd_config
#     sudo service ssh restart

#     echo "User $username_to_remove removed from SSH configuration."

#     # Remove user's home directory
#     read -p "Remove user $username_to_remove's home directory? [Y/n]: " remove_home_dir
#     if [[ $remove_home_dir =~ ^[Yy]$ ]]; then
#         sudo userdel -r $username_to_remove
#         echo "Home directory for user $username_to_remove removed."
#     fi

#     echo "User $username_to_remove removed successfully."
# else
#     echo "No user removed."
# fi
