# build_ubuntu_pi4_rt_kernal_docker

Under your raspberry pi, run following command to get curent built .config file
and name it e.g:
```
$ cat /boot/config-$(uname -r) > rapi_$(uname -r).config
$ ls
rapi_5.15.0-1029-raspi.config
$
```

Then copy/update to the file rapi_5.15.0-1029-raspi.config
