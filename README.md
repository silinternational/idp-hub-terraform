# idp-hub-terraform

This is a Terraform root block defining a SimpleSAMLphp "hub". It is based on
[ssp-base](https://github.com/silinternational/ssp-base) which utilizes several custom SimpleSAMLphp
modules, providing a menu of Identity Provider (IdP) choices for a user to choose from. The hub acts
as an IdP to a number of Service Providers (SP) and as a SP to the chosen IDP. 
