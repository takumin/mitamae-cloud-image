# frozen_string_literal: true

#
# Public Variables
#

node.reverse_merge!({
  powerdns: {
    backend: {
      bind: {
        'config':              '/etc/powerdns/named.conf',
        'autoprimary-config':  '/var/lib/powerdns/supermaster.conf',
        'autoprimary-destdir': '/var/lib/powerdns/zones.slave.d',
      },
    },
    config: {
      authoritative: {
        'include-dir': '/etc/powerdns/pdns.d',
        'local-address': [
          '127.0.0.1:5300',
          '[::1]:5300',
        ],
      },
      recursor: {
        dnssec: {
          validation:      'process',
          trustanchorfile: '/usr/share/dns/root.key',
        },
        recursor: {
          hint_file:   '/usr/share/dns/root.hints',
          include_dir: '/etc/powerdns/recursor.d',

          forward_zones_recurse: [
            {
              zone: '.',
              forwarders: [
                # Google Public DNS
                '2001:4860:4860::8888',
                '2001:4860:4860::8844',
              ],
            },
          ],
        },
        incoming: {
          listen: [
            '127.0.0.1:5301',
            '[::1]:5301',
          ],
        },
      },
      dnsdist: {
        authoritative: '127.0.0.1:5300',
        recursor:      '127.0.0.1:5301',
        local_domain: [
          # Bare Metal
          'metal.internal',
          # Private Network
          '10.in-addr.arpa',
          '16.172.in-addr.arpa',
          '168.192.in-addr.arpa',
        ],
        local_network: [
          # Localhost
          '127.0.0.1/8',
          '[::1]/128',
          # Link Local
          '169.254.0.0/16',
          '[fe80::]/10',
          # Private Network
          '10.0.0.0/8',
          '172.16.0.0/12',
          '192.168.0.0/16',
          '[fd00::]/8',
        ],
      },
    },
  },
})
