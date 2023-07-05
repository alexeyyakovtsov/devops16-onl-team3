#!/bin/bash

#help function example
Help()
{
   # Display Help
   echo "Creates user with password and custom directory"
   echo
   echo "Syntax: useradd -username <username> -password <password> [-directory directory] [-enabled] [-ssh_access]"
   echo "-username New created user name"
   echo "-password New created user password"
   echo "-directory New created user home directory"
   echo "-enable Is user enabled"
   echo "-ssh_access Is ssh access enabled"
   echo
}


#getopts function usage code snippet
while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
   esac
done

ssh_access=false
enable=false

args=( "$@" )
args_len=${#args[@]}

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

: "${username:?Missing -username}"
: "${password:?Missing -password}"

echo "Username: $username";
echo "Password: $password";

if [ -z "${directory}" ]; then
  echo "Directory is not set, use default"
  useradd -p $password $username
else
  echo "Directory: $directory";
  useradd -d $directory -p $password $username
fi

echo "ssh_access = $ssh_access"
echo "enable = $enable"