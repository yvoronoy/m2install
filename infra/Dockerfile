FROM alpine:3.14
RUN apk add --no-cache ansible openssh-client
RUN wget -qO terraform.zip https://releases.hashicorp.com/terraform/1.1.2/terraform_1.1.2_linux_amd64.zip
RUN unzip terraform.zip
RUN mv terraform /usr/local/bin/
CMD ["terraform"]
