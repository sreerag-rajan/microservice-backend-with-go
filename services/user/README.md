# User Service

## Introduction

This is the base user service. This is used to manage a users information. This service primarily provides cruds related to a user. 

## DB Structure

This service has 1 table:

### Profile
This is the table that will hold the users profile information like first name, last name, profile image (as string). this will recieve a user uuid from the auth service user table. There is no foreign key constraint to it. If it recieves a user uuid it assumes the user exists. 

## Functions
#### Create User

#### Update User

#### Delete user

#### Delete Users (Bulk)

#### Get User by id (uuid)

#### List all Users

#### List Users and Paginate