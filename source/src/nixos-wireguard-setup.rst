.. index:: nixos, nix, vpn, wireguard

NixOS Wireguard Server Setup
============================

First, boot your NixOS iso. Install NixOS as shown in the `manual <https://nixos.org/manual/nixos/unstable/index.html#ch-installation>`_. Login your server as an unpriviled user. Then become root and switch to `/root` with

.. code-block::

   sudo su
   cd /root


then open a shell with `wireguard-tools <https://search.nixos.org/packages?channel=unstable&type=packages&query=wireguard-tools>`_ with

.. code-block::

   nix-shell -p wireguard-tools


then generate a keypair for wireguard [#f1]_ with


.. code-block::

   wg genkey | tee privatekey | wg pubkey > publickey


There should be two files in your working directory named privatekey and publickey.Set your privatekey permissions to readonly with

.. code-block::

   chmod 400 privatekey


then print out publickey with

.. code-block::

   cat publickey


Note this key somewhere, you will need to share this with clients.

.. warning::

  DO NOT EVER SHARE PRIVATE KEY.


After that edit your `/etc/nixos/configuration.nix`. You can use whichever text editor you want, for instance opening with nano is simply

.. code-block::

   nano /etc/nixos/configuration.nix


then add `./vpn-config.nix` to your `import = [ ];` section it should look like this:

.. code-block::

   # ...
   imports = [
     ./hardware-configuration.nix
     ./vpn-config.nix
   ];
   # ...

Write and close your editor (for nano its `CTRL+O` and `CTRL+X`). Check your network interfaces with

.. code-block::

   ip a


Note your network interfaces. Then edit `/etc/nixos/vpn-config.nix` as this:

.. code-block::

  { config, ... }:

  let
    vpnPORT = 51820; # @EDIT THIS (ANY PORT IS OK)@
    vpnINTERFACE = "wg0"; # @EDIT THIS (ANY INTERFACE NAME IS OK)@
    inbInterface = "ensp1s0"; # @EDIT THIS (THIS INTERFACE SHOULD BE TAKEN FROM `ip a` COMMAND)@
    privKEY = "/root/privatekey"; # @EDIT THIS (LOCATION OF PRIVATE KEYFILE GENERATED FROM `wg genkey` COMMAND)@
    vpnSUBNET = "10.100.0"; # @EDIT THIS (ANY IPv4 WITHOUT LAST 8 BIT IS OK)@
  in
  {
    networking = {
      firewall = {
        enable = true;
        allowedUDPPorts = [ vpnPORT ];
      };
      nat = {
        enable = true;
        externalInterface = inbInterface;
        internalInterfaces = [ vpnINTERFACE ];
      };
      wireguard.interfaces = {
        "${vpnINTERFACE}" = {
          ips = [ "${vpnSUBNET}.1/24" ];
          listenPort = vpnPORT;
          postSetup = ''
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${vpnSUBNET}.0/24 -o ${inbInterface} -j MASQUERADE
          '';
          postShutdown = ''
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${vpnSUBNET}.0/24 -o ${inbInterface} -j MASQUERADE
          '';
          privateKeyFile = privKEY;
          peers = [
            {
              publicKey = ""; # @EDIT THIS (PUBLIC KEY OPTAINED FROM CLIENTS)@
              allowedIPs = [ "${vpnSUBNET}.2/32" ];
            }
            {
              publicKey = ""; # @EDIT THIS (PUBLIC KEY OPTAINED FROM CLIENTS)@

              allowedIPs = [ "${vpnSUBNET}.3/32" ];
            }
            {
              publicKey = ""; # @EDIT THIS (PUBLIC KEY OPTAINED FROM CLIENTS)@

              allowedIPs = [ "${vpnSUBNET}.4/32" ];
            }
          ];
        };
      };
    };
  }


.. note::

   Edit sections marked with `@EDIT THIS@`. If you have followed this guide accordingly you will only have to edit `inbInterface` and `peers`.


.. warning::

  The publicKey section is NOT THE PUBLIC KEY WE GENERATED EARLIER. It is public key generated by client and shared with server.


You can add as many peers (clients in this case) as you like. When you finish editing, write and close. Then reconfigure your system with:

.. code-block::

   nixos-rebuild switch


Server is ready, you can close your shell.

.. [#f1] This is unique to server, later you will have to generate keypairs for clients also.
