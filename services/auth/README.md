# AUTH Service

## Introduction

This is the base user service. This is used to manage a users information. This service primarily provides cruds related to a user. 

## DB Structure

This service has 3 table:
### User
This table captures core information about the user like email, phone, password and has a unique id. This table will be primarily use for authentication as well and will be shared with the auth service.

### Session
This is the table will track the login sessions of the user. 

### Tokens
This will be used for email and phone verifications and the token expiries. 

## APIS

#### Register

#### Login

#### Generate OTP

#### Valiate OTP

#### Reset Password
