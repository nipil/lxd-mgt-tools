# lxd-mgt-tools

These scripts create bridge interfaces, one for each DMZ.

Add this to `/etc/network/interfaces` :

    source /etc/network/interfaces.d/*.conf

Create `vlan18` for DMZ 18 :

    sudo ./dmz-create.sh 18

Here is the result (with chosen addresses) :

    35: vlan18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default
        link/ether WW:ZZ:ZZ:ZZ:ZZ:ZZ brd ff:ff:ff:ff:ff:ff
        inet 10.0.18.254/24 brd 10.0.18.255 scope global vlan18
           valid_lft forever preferred_lft forever
        inet6 fd00::12:ffff:ffff:ffff:fffe/64 scope global
           valid_lft forever preferred_lft forever
        inet6 fe80::ZZZZ:ZZff:feZZ:ZZZZ/64 scope link
           valid_lft forever preferred_lft forever

Delete it with :

    sudo ./dmz-delete.sh 18
