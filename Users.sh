#!/bin/bash

# Display existing active users
active_users=$(awk -F: '($7 != "/usr/sbin/nologin" && $7 != "/bin/false") { print $1 }' /etc/passwd)
active_users_count=$(echo "$active_users" | wc -l)
echo "Existing active users:"
if [ "$active_users_count" -eq 0 ]; then
    echo "No active users found."
else
    awk -F: '($7 != "/usr/sbin/nologin" && $7 != "/bin/false") { print NR".", $1 }' /etc/passwd | column
fi

# Prompt for option to view disabled accounts
read -p "View list of disabled user accounts? [Y/n]: " view_disabled

# Check if user wants to view disabled accounts
if [[ $view_disabled =~ ^[Yy]$ ]]; then
    # Request root password
    sudo echo "Requesting root password to view disabled accounts..."

    # Display disabled user accounts
    echo "Disabled user accounts:"
    sudo awk -F: '($2 == "!" || $2 == "*") { print $1 }' /etc/shadow | column
fi

# Prompt for account lock
read -p "Do you want to lock a user account? [Y/n]: " lock_account

if [[ $lock_account =~ ^[Yy]$ ]]; then
    # Prompt for username
    read -p "Enter the username to lock: " username

    # Check if user exists
    if id "$username" >/dev/null 2>&1; then
        # Lock user account
        sudo passwd -l $username
        echo "User account $username locked."
    else
        echo "User account $username does not exist."
    fi
else
    echo "No user accounts locked."
fi

# Prompt to create a new user
read -p "Create a new user? [Y/n]: " create_new_user

if [[ $create_new_user =~ ^[Yy]$ ]]; then
    # Prompt for username
    read -p "Enter username: " username

    # Prompt for password
    read -s -p "Enter password: " password
    echo

    # Create user with password
    sudo useradd -m -p $(echo "$password" | openssl passwd -1 -stdin) $username

    # Prompt for additional user details
    read -p "Enter full name: " full_name
    read -p "Enter description: " description

    # Set additional user details
    sudo chfn -f "$full_name" -r "$description" $username

    # Create separate directory for the user
    read -p "Create a separate directory for the user? [Y/n]: " create_directory
    if [[ $create_directory =~ ^[Yy]$ ]]; then
        sudo mkdir /home/$username
        sudo chown $username:$username /home/$username
        echo "Separate directory created for user $username."
    fi

    echo "User $username created successfully."

# Grant SSH access to the user
read -p "Grant SSH access to the user? [Y/n]: " grant_ssh_access
if [[ $grant_ssh_access =~ ^[Yy]$ ]]; then
    # Prompt for SSH permission configuration
    read -p "Enter SSH permission configuration (e.g., 'AllowUsers username'): " ssh_config

    # Add SSH permission configuration to sshd_config file
    echo "$ssh_config" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    sudo service ssh restart

    echo "SSH access granted according to the provided configuration."
fi

# Prompt to remove a user
read -p "Remove a user? [Y/n]: " remove_user

if [[ $remove_user =~ ^[Yy]$ ]]; then
    # Prompt for username
    read -p "Enter username to remove: " username

    # Prompt for username to remove from SSH configuration
    read -p "Enter the username to remove from SSH configuration: " username

    # Remove SSH permission configuration from sshd_config file
    sudo sed -i "/AllowUsers.*$username/d" /etc/ssh/sshd_config
    sudo service ssh restart

    echo "User $username removed from SSH configuration."

    # Remove user's home directory
    read -p "Remove user $username's home directory? [Y/n]: " remove_home_dir
    if [[ $remove_home_dir =~ ^[Yy]$ ]]; then
        sudo userdel -r $username
        echo "Home directory for user $username removed."
    fi

    echo "User $username removed successfully."
else
    echo "No user removed."
fi