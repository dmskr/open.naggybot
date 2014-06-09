
- [x] Pull request data should be updated as well during the 'pull' procedure
- [x] Do all the pull data in parallel

- [ ] All reviews in pending status created for the same pull request within the same repo should be shrinked to single one, latest one
- [ ] Comments pushed to GitHub should not be duplicated
- [ ] 'Too many words' should be posted to pull request overall if more than, say, 10 comments were posted already and more to come.
- [ ] All pulled data should be cleaned up once a review is completed plus, say, 10 days
- [ ] Ideally the 'pull' action should be moved to git-based updates
- [ ] Add something like airbrake.io to the application to be notified with errors
- [ ] Move the monitoring and restarting to monit, leaving upstart as a handy unitility

