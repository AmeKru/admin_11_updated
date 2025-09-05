const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "api": {
        "plugins": {
            "awsAPIPlugin": {
                "MooRide20Data": {
                    "endpointType": "GraphQL",
                    "endpoint": "https://mgrhtiu6obbq5idvuf2xheiy3a.appsync-api.ap-southeast-2.amazonaws.com/graphql",
                    "region": "ap-southeast-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-kdoyqvtr6bf6bkyjlzqqgctc2m"
                }
            }
        }
    },
    "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "IdentityManager": {
          "Default": {}
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "ap-southeast-2_xwmal4Dlq",
            "AppClientId": "3o3jep6ccpot5t26ia4aurojoq",
            "Region": "ap-southeast-2"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "usernameAttributes": ["email"],
            "signupAttributes": [
              "email"
             ],
            "passwordProtectionSettings": {
                "passwordPolicyMinLength": 8,
                "passwordPolicyCharacters": []
            }
          }
        }
      }
    }
  }
}''';
