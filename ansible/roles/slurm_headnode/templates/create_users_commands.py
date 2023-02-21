#!/usr/bin/env python3

# ./add_user.py -un mike -n Mike -sn 'Currin' -ssh 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINSU6y4lUazLnlyf/Ug+xYm2wI+zO3rd8L/7sAvChfaP dane@pop-os' --make-changes

from yaml import load as yaml_load
from yaml import FullLoader
from sys import argv

with open(argv[1], 'r') as yaml_file:
    the_data = yaml_load(yaml_file, Loader=FullLoader)

#print(dir(the_data))

for user_data in the_data['users']:
#    print(user_data)
    username = f'{user_data["Firstname"][0]}{user_data["Surname"]}'.lower().strip().replace(" ","")
    print(f'./add_user.py -un \'{ username }\' -n \'{ user_data["Firstname"] }\' -sn \'{user_data["Surname"]}\' -ssh \'{user_data["Public SSH key"]}\' --make-changes')



# {'Email address': 'monalisatatenda@gmail.com', 'Firstname': 'Monalisa', 'Public SSH key': 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCYNM46l4qiDjtfNU96EgRm3gQGmSnLc+86uW+xnkuVGZdM+hqY6c/L0KOej/E2h/LLA/+jp7Nzdca+BUF/YQUDXsiGjs9O0wfPO+8W/HeRK7KoJICBIk4UDCWHQ8juk5pL9Y4zqme7QFNGBbKmAj+9ce33Rhi1z9OQGyHScdO2Qhc0aLuO8M2OGk/1SCa9G/nbUmb++Xredil17a7fA4aJMHVSUk9T0Aob+lEdtIwY4gLhz+CodCdcumbhAKNeDRUq256VqRG4P9waPEPeUcw6cQ7GwXgwD6WM49+PgEGH2kHHCpqvhrVXimEWugEfMZ5nso14eQ+2qg6ezV+AQA6D monalisamanhanzva@Monalisas-MacBook-Air.local', 'Surname': 'Manhanzva', 'Timestamp': '07/10/2021 13:41:07'}
