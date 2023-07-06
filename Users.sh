#!/bin/bash

# --- TASK 2 ---
function chekUsernameLimit() {
    local userName="$1"  # Receive the userName as an argument

    if [ "${#userName}" -gt "10" ]; then
        echo "Your username contains more than 10 characters. Please enter less than 10 characters"
        exit 1
    fi
}

function createUser() {
        username=$1
        password=$2
        directory=$3
        ssh_access=$4
        enable=$5
        # Prompt for username
        if [ -z "${username}" ]; then
          read -p "Enter username: " username
        fi

        # Show string length
        string_length=${#username}
        echo "------"
        echo "The length of the string is: $string_length"
        # Check the username length
        chekUsernameLimit "$username"
        echo "------"

        # Prompt for password
        if [ -z "${password}" ]; then
          read -s -p "Enter password: " password
          echo
        fi

        if [ -z "${ssl_access}" ]; then
          ssh_access=false
        fi

        if [ -z "${enable}" ]; then
          enable=false
        fi

        if [ -z "${directory}" ]; then
          read -p "Enter home directory [/home/$username]: " directory
        fi

        if [ -z "${directory}" ]; then
          directory="/home/username"
        fi

        # Create user with password
#        sudo useradd -d $directory -m -p $(echo "$password" | openssl passwd -1 -stdin) $username

        # Prompt for additional user details
#        read -p "Enter full name: " full_name
#        read -p "Enter description: " description

        # Set additional user details
#        sudo chfn -f "$full_name" -r "$description" $username

        echo "User $username created successfully."
  echo "$@"
}

function lockUser() {
        username=$1
        # Prompt for username
        if [ -z "${username}" ]; then
          read -p "Enter the username to lock: " username
        fi

        # Check if user exists
        if id "$username" >/dev/null 2>&1; then
            # Lock user account
            sudo passwd -l $username
            echo "User account $username locked."
        else
            echo "User account $username does not exist."
        fi
}

function grantSshAccess() {
        # Prompt for SSH permission configuration
        read -p "Enter SSH permission configuration (e.g., 'AllowUsers username'): " ssh_config

        # Add SSH permission configuration to sshd_config file
        echo "$ssh_config" | sudo tee -a /etc/ssh/sshd_config >/dev/null
        sudo service ssh restart

        echo "SSH access granted according to the provided configuration."
}

function removeUser() {
        username_to_remove=$1
        # Prompt for username
        if [ -z "${username_to_remove}" ]; then
          read -p "Enter username to remove: " username_to_remove
        fi

        # Remove SSH permission configuration from sshd_config file
        sudo sed -i "/AllowUsers.*$username_to_remove/d" /etc/ssh/sshd_config
        sudo service ssh restart

        echo "User $username_to_remove removed from SSH configuration."

        # Remove user's home directory
        read -p "Remove user $username_to_remove's home directory? [Y/n]: " remove_home_dir
        if [[ $remove_home_dir =~ ^[Yy]$ ]]; then
            sudo userdel -r $username_to_remove
            echo "Home directory for user $username_to_remove removed."
        fi

        echo "User $username_to_remove removed successfully."
}

#function viewActiveUsers() {
#    # Display existing active users
#    active_users=$(awk -F: '($7 != "/usr/sbin/nologin" && $7 != "/bin/false") { print $1 }' /etc/passwd)
#    active_users_count=$(echo "$active_users" | wc -l)
#    echo "Existing active users:"
#    if [ "$active_users_count" -eq 0 ]; then
#        echo "No active users found."
#    else
#        awk -F: '($7 != "/usr/sbin/nologin" && $7 != "/bin/false") { print NR".", $1 }' /etc/passwd | column
#    fi
#}

#function viewDisabledUsers() {
#        # Request root password
#        sudo echo "Requesting root password to view disabled accounts..."
#
#        # Display disabled user accounts
#        echo "Disabled user accounts:"
#        sudo awk -F: '($2 == "!" || $2 == "*") { print $1 }' /etc/shadow | column
#}

#help function example
Help() {
  if [[ -z $1 ]]; then
    echo "Enter command and options: <create|remove|lock|grant-ssh> [options]"
    exit;
  fi
  case $1 in
    "create")
       # Display Help
       echo "Creates user with password and custom directory"
       echo
       echo "Syntax: create -username <username> -password <password> [-directory directory] [-enabled] [-ssh_access]"
       echo "-username New created user name"
       echo "-password New created user password"
       echo "-directory New created user home directory"
       echo "-enable Is user enabled"
       echo "-ssh_access Is ssh access enabled"
       echo
     ;;
    "remove")
       # Display Help
       echo "Removes user with username"
       echo
       echo "Syntax: remove -username <username>"
       echo "-username New created user name"
       echo
     ;;
  esac
}

if [[ $1 = "-h" ]]; then
   Help
   exit;
fi

command=$1
: "${command:?Missing command}"

if [[ $2 = "-h" ]]; then
   Help $command
   exit;
fi

args=( "$@" )
# shellcheck disable=SC2184
unset args[0]
args_len=${#args[@]}

if [[ $1 = "create" ]]; then
    for (( i=0; i<$args_len; i++ )) ; do
      if [[ ${args[$i]} = "-username" ]]; then
        username=${args[$i + 1]}
      fi

      if [[ ${args[$i]} = "-password" ]]; then
        password=${args[$i + 1]}
      fi

      if [[ ${args[$i]} = "-directory" ]]; then
        directory=${args[$i + 1]}
      fi

      if [[ ${args[$i]} = "-ssh_access" ]]; then
        ssh_access=true
      fi

      if [[ ${args[$i]} = "-enable" ]]; then
        enable=true
      fi
    done

    createUser $username $password $directory $ssh_access $enable
elif [[ $1 = "lock" ]]; then
    for (( i=0; i<$args_len; i++ )) ; do
      if [[ ${args[$i]} = "-username" ]]; then
        username=${args[$i + 1]}
      fi
    done

    lockUser $username

elif [[ $1 = "grant-ssh" ]]; then
    for (( i=0; i<$args_len; i++ )) ; do
      if [[ ${args[$i]} = "-username" ]]; then
        username=${args[$i + 1]}
      fi
    done
    grantSshAccess $username
elif [[ $1 = "remove" ]]; then
    for (( i=0; i<$args_len; i++ )) ; do
      if [[ ${args[$i]} = "-username" ]]; then
        username=${args[$i + 1]}
      fi
    done
    grantSshAccess $username
    removeUser $username
#elif [[ $1 = "ls-active" ]]; then
#    viewActiveUsers $args
#elif [[ $1 = "ls-disabled" ]]; then
#    viewDisabledUsers $args
fi
