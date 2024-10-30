import pexpect as p
import time

child = p.spawn('./identityconsole_install')

child.expect('Press ENTER to continue')
child.sendline()

child.expect('--More--.*')
child.sendline('q')

child.expect('Do you accept the terms of Identity Console .*[y/n/q] ?')
child.sendline('y')

time.sleep(30)
child.expect('Enter the Identity Console server hostname\/IP address .*')
child.sendline('{{ IDC_host }}')

child.expect('Enter the port number you wish Identity Console to listen on \(DEFAULT: 9000\): ')
child.sendline('{{ IDC_port }}')

#child.expect('Enter the eDirectory\/Identity Vault server Domain name\/IP address with LDAPS port number \[192.168.1.1:636\]')
#child.sendline('{{ IDV_address }}')

#child.expect('Enter the eDirectory\/Identity Vault username \(e.g: cn=admin,ou=org_unit,o=org\)')
#child.sendline('{{ IDV_user }}')

#child.expect('Enter the eDirectory\/Identity Vault user password:')
#child.sendline('{{ IDV_password }}')

child.expect('Enter y for YES and n for NO \(DEFAULT: n\) : ')
child.sendline('n')

child.expect('Enter the trusted root certificate\(s\) folder path: ')
child.sendline('.')

child.expect('Enter the server certificate path including the filename: ')
child.sendline('cert.pfx')

child.expect('Enter the server certificate password: ')
child.sendline('{{ pfx_password }}')

child.expect('Re-enter the server certificate password: ')
child.sendline('{{ pfx_password }}')

child.expect('Identity Console can be accessed at .*')
child.sendline()
