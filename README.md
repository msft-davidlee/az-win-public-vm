# Disclaimer
The information contained in this README.md file and any accompanying materials (including, but not limited to, scripts, sample codes, etc.) are provided "AS-IS" and "WITH ALL FAULTS." Any estimated pricing information is provided solely for demonstration purposes and does not represent final pricing and Microsoft assumes no liability arising from your use of the information. Microsoft makes NO GUARANTEES OR WARRANTIES OF ANY KIND, WHETHER EXPRESSED OR IMPLIED, in providing this information, including any pricing information.

# Introduction
This project creates a public vm that you can SSH into on your desired VNET. 

# Get Started
To create this networking environment in your Azure subscription, please follow the steps below. 

0. Be sure to read and create https://github.com/msft-davidlee/az-internal-network as this is needed for AKS networking.
1. Fork this git repo. See: https://docs.github.com/en/get-started/quickstart/fork-a-repo
2. Create two resource groups to represent two environments. Suffix each resource group name with either a -dev or -prod. An example could be networking-dev and networking-prod.
3. Next, you must create a service principal with Contributor roles assigned to the two resource groups.
4. In your github organization for your project, create two environments, and named them dev and prod respectively.
5. Create the following secrets in your github per environment. Be sure to populate with your desired values. The values below are all suggestions.
6. Note that the environment suffix of dev or prod will be appened to your resource group but you will have the option to define your own resource prefix.

## Secrets
| Name | Comments |
| --- | --- |
| AZURE_CREDENTIALS | <pre>{<br/>&nbsp;&nbsp;&nbsp;&nbsp;"clientId": "",<br/>&nbsp;&nbsp;&nbsp;&nbsp;"clientSecret": "", <br/>&nbsp;&nbsp;&nbsp;&nbsp;"subscriptionId": "",<br/>&nbsp;&nbsp;&nbsp;&nbsp;"tenantId": "" <br/>}</pre> |
| PREFIX | myvms - or whatever name you would like for all your resources etc |
| RESOURCE_GROUP | vm - or whatever name you give to the resource group |
| NETWORKING_PREFIX | platform - this is the default used in https://github.com/msft-davidlee/az-internal-network - see more comments below |

Note that the NETWORKING_PREFIX is the networking resources i.e. VNETs created from https://github.com/msft-davidlee/az-internal-network. Please make sure you complete that before starting this project. It is the PREFIX used in that project. 