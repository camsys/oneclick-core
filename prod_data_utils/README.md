Setup (One Time Actions)
---------
a. copy folder to new app

b. update config.json
1. update master_source_id
2. update replica_source_id
3. update database
4. create AWS access/secret keys and update
    
How To Run (Note: This is old and needs to be updated)
---------

a. Copy previous version folder. Update version number of folder

b. Update BeforeCommonTasks and AfterCommonTasks

c. Update version number in config.json

d. Commit and push

e. Ssh into ec2 instance. Pull latest code.

f. Make sure in application.yml the DB is still pointing to the correct DB. The script updates the application.yml which does not get pushed so the github version might not have the correct DB host.

g. cd app/prod_data_check

h. ruby run.rb

i. All done!


Notes
---------

1. run.rb: is the entry and it calls db_replica_utils.rb and version specific data tasks;
To run, do `ruby run.rb`

2. db_replica_utils.rb: would connect to AWS based on config.json and create a read replica off target 
database instance and establish ActiveRecord connection to the database in replica instance; following 
data tasks would be using this AR connection and therefore would be applied into the replica instance DB

3. config.json: configuration file that has AWS, DB and application specific config data.

4. common_tasks.rb: common data/rake tasks to run in each deployment

5. {version} folder: each folder is named by the version number that includes version specific tasks to run before and after running common_tasks.rb and any sql files referenced in task script to be imported into the database

6. {version}/before_common_tasks.rb: data task script to run BEFORE common_tasks for a specific version deployment

7. {version}/after_common_tasks.rb: data task script to run AFTER common_tasks for a specific version deployment

8. mysql_utils.rb: a common utility mixin to connect to MySQL and load SQL file (can be injected into task class as needed)
