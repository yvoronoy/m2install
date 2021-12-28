## How to run tests by using Github Actions locally 
 - Install act https://github.com/nektos/act
 - Copy infra/workflow-secrets.env.example infra/workflow-secrets.env
 - Edit infra/workflow-secrets.env with your secrets
 - Run `act --secret-file infra/workflow-secrets.env`
