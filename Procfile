inbound_mail: env QUEUE=inbound_mail bundle exec rake environment resque:work
outbound_mail: env QUEUE=outbound_mail bundle exec rake environment resque:work
search_updates: env QUEUE=search_updates bundle exec rake environment resque:work
resque_web: bundle exec resque-web -F --namespace resque:Cyclescape --app-dir ./ --pid-file /var/run/resque_web.pid --log-file /var/log/resque_web.log --url-file ./resque_web.url
