# kube-cluster

This repo contains code to create a Kubernetes cluster from scratch via Terraform.

I made this as part of the [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way/tree/master) tutorial.

## Quickstart

Deploy:
```
cd terraform
terraform init
terraform apply
```

Destroy:
```
terraform destroy
```

# Manual steps

Setting up the jumpbox: Follow [these steps](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-jumpbox.md)

Create the `machines.txt` on the jumpbox:
```
cd terraform
terraform output machines_txt_content
# copy the contents and create a the /root/kubernets-the-hard-way/machines.txt file
```

Run the following script on the jumpbox to distribute the ssh keys to the machines.
