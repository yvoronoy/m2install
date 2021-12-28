#!/usr/bin/env bash
[ -z "$AWS_ACCESS_KEY_ID" ] && { echo 'AWS_ACCESS_KEY_ID is not set' ; exit 1; }
[ -z "$AWS_SECRET_ACCESS_KEY" ] && { echo 'AWS_SECRET_ACCESS_KEY' ; exit 1; }

docker build --rm -t terraform-runner:latest infra/
[[ -z "$1" || "$1" = "build" ]] && docker run --rm -it -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -v "$(pwd)/infra/ansible/etc:/etc/ansible" -v "$(pwd):/root/m2install" -w /root/m2install/infra/terraform terraform-runner terraform apply --auto-approve

[[ -z "$1" || "$1" = "play" ]] && sleep 5 && docker run --rm -it -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -v "$(pwd)/infra/ansible/etc:/etc/ansible" -v "$(pwd):/root/m2install" -w /root/m2install/infra/terraform terraform-runner ansible-playbook ../ansible/playbook.yaml -v

[[ -z "$1" || "$1" = "destroy" ]] && docker run --rm -it -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -v "$(pwd)/infra/ansible/etc:/etc/ansible" -v "$(pwd):/root/m2install" -w /root/m2install/infra/terraform terraform-runner terraform destroy --auto-approve
